defmodule NidmWeb.AdminLive do
    use NidmWeb, :live_view

    alias Nidm.GenServers.Gate
    alias Nidm.{ Users, Networks, NetworkStates, Exporter }

    require Logger

    def mount(_params, _session, socket) do
        users = Users.list_subjects()
        signed_in = Enum.filter users, &(&1.status != nil)
        networks = get_networks()
        network_ids = Enum.map networks, &(&1.id)
        networks = Map.new Enum.map(networks, &({&1.id, &1}))
        network_states = process_network_states(
            Map.keys(networks),
            NetworkStates.list_network_states()
        )
        gate = process_gate_data(Gate.get_state())

        case connected?(socket) do
            true ->
                Phoenix.PubSub.subscribe(Nidm.PubSub, "admin")
                # start a clock
                :timer.send_interval(10_000, :update_users)
            false ->
                :ok
        end

        socket = socket
            |> assign(
                user_ids: Enum.map(users, &(&1.id)),
                users: Map.new(Enum.map users, &({ &1.id, &1 })),
                network_ids: network_ids,
                networks: networks,
                network_states: network_states,
                gate: gate,
                signed_in: Enum.count(signed_in)
            )
            |> push_event("init-admin-chart", network_states)

        { :ok, socket, layout: { NidmWeb.LayoutView, "live-wide.html" } }
    end

    def handle_info(:update_users, socket) do
        cached = socket.assigns.users
        busy = Users.list_busy_subjects()
        cached = Enum.reduce busy, cached, fn user, acc ->
            Map.put(acc, user.id, user)
        end
        socket = assign(socket,
            users: cached,
            signed_in: Enum.count(busy)
        )
        { :noreply, socket }
    end

    def handle_info({ :update_network, network_state }, socket) do
        state = state_summary(network_state)

        network_states = socket.assigns.network_states
        added_state = Map.get(network_states, state.network_id, []) ++ [state]
        network_states = Map.put(network_states, state.network_id, added_state)

        socket = assign(socket, :network_states, network_states)
        socket = push_event(socket, "update-admin-chart", state)

        { :noreply, socket }
    end

    # notify when network is filled
    def handle_info({ :network_filled, network }, socket) do
        networks = socket.assigns.networks
        networks = Map.put(networks, network.id, network)
        socket = assign(socket, :networks, networks)
        { :noreply, socket }
    end


    def handle_info({ :gate, gate_data }, socket) do
        socket = assign(socket, :gate, process_gate_data(gate_data))
        { :noreply, socket }
    end


    def handle_info({ :export_ready, path }, socket) do
        socket = redirect(socket, to: "/admin/export?path=#{path}")
        { :noreply, socket }
    end


    def handle_event("flush", _value, socket) do
        gate_data = Gate.flush()
        # shut down all available networks
        Networks.available_networks()
        |> Enum.each(&Networks.set_status(&1, "closed-off"))
        # get all the networks again for the update
        networks = get_networks()
        # set the socket
        socket = socket
            |> assign(
                gate: process_gate_data(gate_data),
                networks: Map.new(Enum.map(networks, &({&1.id, &1})))
            )
        { :noreply, socket }
    end


    def handle_event("export", _value, socket) do
        Exporter.export()
        { :noreply, socket }
    end


    defp get_networks() do
        Enum.sort(Networks.list_networks(), &(&1.name < &2.name))
    end


    defp state_summary(state) do
        %{
            network_id: state.network_id,
            status: state.status,
            round: state.round,
            edges: state.edges,
            connects: state.connects,
            disconnects: state.disconnects,
            infected: state.infected * 10
        }
    end


    defp process_network_states(ids, network_states) do
        wrapper = Enum.reduce ids, %{}, fn id, acc ->
            Map.put(acc, id, [])
        end
        # sort network states
        Enum.reduce network_states, wrapper, fn state, acc ->
            state = state_summary(state)
            data = Map.get(acc, state.network_id, []) ++ [state]
            Map.put(acc, state.network_id, data)
        end


    end

    # adding the networks map is efficient, it avoids looking up the network all the time
    defp network_of_user(user, networks) do
        case user.network_id do
            nil -> ""
            _ ->
                network = Map.get(networks, user.network_id, %{ name: '-' })
                network.name
        end
    end


    defp process_gate_data(gate) do
        Enum.map gate.queues, fn { key, q } -> [ key, :queue.len(q) ] end
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
