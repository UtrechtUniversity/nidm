defmodule NidmWeb.GameLive do
    use NidmWeb, :live_view

    alias Nidm.GenServers.NetworkMonitor
    alias Nidm.{ Users, Networks, NetworkTools }
    alias Nidm.Resources.FriendshipRequest

    require Logger

    @round_intervals NetworkMonitor.get_round_intervals()

    def mount(_params, session, socket) do
        # get user
        %{ "user_id" => user_id } = session
        user = Users.get_user(user_id)
        node = user.node_id

        # connect to channels
        case connected?(socket) do
            false ->
                :ok
            true ->
                # subscribe to the network channel
                Phoenix.PubSub.subscribe(Nidm.PubSub, "network:#{ user.network_id }")
                # also subscribe to the user channel
                Phoenix.PubSub.subscribe(Nidm.PubSub, "node:#{ user.network_id }:#{ node }")
        end

        # get network
        network = Networks.get_network(user.network_id)

        # friends, introductions
        friends = network.edge_map[node]
        offerings = network.offerings[node]

        possible_breakups = MapSet.intersection(offerings, friends)
        introductions = MapSet.difference(offerings, friends)

        # health
        health = get_health_status(network)

        # get subtree and generate a topo
        # nodes_for_graph = NetworkTools.subtree(network, node, 1) ++ introductions
        graph_data = NetworkTools.get_topology(network)
        graph_data = Map.put(graph_data, :me, node)

        # assign queue state to the socket and the user_id
        socket = assign(
            socket,

            round: network.round,
            condition: network.condition_1,
            earned_points: user.prev_earned_points,
            total_points: user.earned_points,
            status: network.status,

            user_id: user.id,
            network_id: network.id,
            node: node,
            friends: friends,

            possible_breakups: possible_breakups,
            introductions: introductions,

            friendship_requests: [],
            health: health
        )

        socket = socket
            |> push_event("countdown", %{ time: @round_intervals[:tick] })
            |> push_event("init-graph", graph_data)
            |> push_event("paint-graph",
                %{
                    me: node,
                    introductions: MapSet.to_list(introductions),
                    friends: MapSet.to_list(friends),
                    health: health
                }
            )

        { :ok, socket, layout: { NidmWeb.LayoutView, "live-wide.html" } }
    end


    # connection with neighbour node
    def handle_event("create-break-friendship", params, socket) do
        network_id = socket.assigns.network_id

        request = %FriendshipRequest{
            id: Ecto.UUID.generate,
            type: nil,
            network_id: network_id,
            sending_node: socket.assigns.node,
            receiving_node: params["friend"],
            timestamp: System.os_time(:second),
            accepted: false,
            network_status: socket.assigns.status
        }

        # if the keyword "value" is in the params, we are going to connect
        request = case Map.has_key?(params, "value") do
            # connect: finalize request and send to server
            true -> %FriendshipRequest{ request | type: :connect }
            # disconnect finalize request and send to server
            false -> %FriendshipRequest{ request | type: :disconnect, accepted: true }
        end

        # send to the network monitor
        NetworkMonitor.add_friendship_request(network_id, request)

        { :reply, %{}, socket }
    end


    def handle_event("accept-friendship", params, socket) do
        network_id = socket.assigns.network_id
        node = socket.assigns.node

        # get the value of acceptance, if there is no value then the checkbox
        # is unchecked and thus false
        accept = Map.has_key?(params, "value")
        # send to the network monitor
        NetworkMonitor.friendship_acceptance(network_id,
            %{ accepting_node: node, sending_node: params["sending-node"], accept: accept  })

        { :reply, %{}, socket }
    end


    def handle_info({ :tick, %{ requests: payload }}, socket) do
        # whoami
        me = socket.assigns.node
        # my payload
        my_payload = payload[me]
        # old introductions
        old_introductions = socket.assigns.introductions

        # I hate this, but if I want to remove my friends when I have disconnected them
        # in the previous phase of the round, I have to find my disconnections
        # remove all friends that I want to get rid of
        friends = Enum.filter socket.assigns.friends, fn friend ->
            friends_payload = payload[friend]
            not(Enum.any?(friends_payload, &(&1.type == :disconnect and &1.from == me)))
        end

        # now I have to remove all the friends that dont want to be friends with me anymore
        friends = Enum.filter friends, fn friend ->
            not(Enum.any?(my_payload, &(&1.type == :disconnect and &1.from == friend)))
        end

        # now collect all friendship requests
        friendship_requests = my_payload
            |> Enum.filter(&(&1.type == :connect and &1.accepted == false)) # filter unaccepted connects
            |> Enum.map(&(&1.from))

        # add invitation
        socket = assign(socket,
            friendship_requests: friendship_requests,
            possible_breakups: [],
            introductions: [],
            friends: friends
        )

        socket = socket
            |> push_event("countdown", %{ time: @round_intervals[:tock] })
            |> push_event("add-proposed-edges", %{
                me: me,
                requests: payload,
                old_introductions: MapSet.to_list(old_introductions)
            })

        { :noreply, socket }
    end


    def handle_info(:exit, socket) do
        # terminate the network monitor
        { :noreply, redirect(socket, to: "/exit") }
    end


    def handle_info(:announcement, socket) do
        { :noreply, redirect(socket, to: "/pause") }
    end


    def handle_info({ :tock, network }, socket) do
        node = socket.assigns.node
        user = Users.get_user(socket.assigns.user_id)

        friends = network.edge_map[node]
        offerings = network.offerings[node]

        possible_breakups = MapSet.intersection(offerings, friends)
        introductions = MapSet.difference(offerings, friends)

        # get all health data
        health = get_health_status(network)

        # get an update on the edges
        graph_data = NetworkTools.get_topology(network)
        graph_data = Map.put(graph_data, :me, node)

        socket = socket
            |> push_event("countdown", %{ time: @round_intervals[:tick] })
            |> push_event("update-edges", graph_data)
            |> push_event("paint-graph",
                %{
                    me: node,
                    introductions: MapSet.to_list(introductions),
                    friends: MapSet.to_list(friends),
                    health: health
                }
            )

        socket = assign(socket,
            round: network.round,
            node: user.node_id,
            condition: network.condition_1,
            earned_points: user.prev_earned_points,
            total_points: user.earned_points,
            status: network.status,

            friendship_requests: [],
            possible_breakups: possible_breakups,
            introductions: introductions,
            friends: friends,

            health: health
        )

        { :noreply, socket }
    end


    defp get_health_status(network) do
        Map.new(Enum.map(network.health, fn { node, { status, _round } } -> { node, status } end))
    end


    defp sort_nodes(nodes) do
        nodes = case is_list(nodes) do
            true -> nodes
            false -> MapSet.to_list(nodes)
        end
        nodes
        |> Enum.sort(&(String.to_integer(&1) <= String.to_integer(&2)))
    end


    defp node_checkbox(node, phx_click, phx_value_key, checked, class) do
        assigns = %{ node: node, phx_click: phx_click, phx_value_key: phx_value_key,
            checked: checked, class: class }

        ~L"""
        <label for="cb_<%= node %>" class="node <%= class %>">
            <%= checkbox(:link, :state, phx_click: phx_click,
                "phx_value_#{phx_value_key}": node, value: checked,
                class: class, data_node: node, id: "cb_#{node}") %>
            Node <%= node %>
        </label>
        """
    end


    defp card(header, contents) do
        assigns = %{ header: header, contents: contents }
        ~L"""
        <div class="card">
            <div class="card-header"><%= header %></div>
            <div class="card-main">
                <div class="main-description"><%= contents %></div>
            </div>
        </div>
        """
    end


end
