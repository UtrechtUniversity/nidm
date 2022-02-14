defmodule Nidm.GenServers.NetworkMonitor do
    use GenServer, restart: :transient # restart only when shutdown abnormally

    alias Nidm.Resources.{ Network, FriendshipRequest }
    alias Nidm.{ Users, Networks, NetworkStates, NetworkTools, FriendshipRequests }

    @tick_interval 1 * 60_000
    @tock_interval 30_000
    @recovery_period Application.get_env(:nidm, :recovery_period, 3)
    @pause_duration Application.get_env(:nidm, :pause_duration, 5_000)

    def start_link(args) do
        # this GenServer can only exists if there is an actual network!!!
        # the process name is also the uuid for the network
        generate_genserver(args)
    end

    # this is for starting from a DynamicSupervisor
    def start_link(_, args) do
        # this GenServer can only exists if there is an actual network!!!
        # the process name is also the uuid for the network
        generate_genserver(args)
    end

    defp generate_genserver(args) do
        [ network: network ] = args
        # the ets table-name has to be an atom
        name = String.to_atom(network.id )
        GenServer.start_link(__MODULE__, args, name: name)
    end

    def get_round_intervals() do
       %{ tick: Kernel.trunc(@tick_interval/1000), tock: Kernel.trunc(@tock_interval/1000) }
    end

    def start_clock(pid) do
        pid = get_process_name(pid)
        GenServer.cast(pid, :start_clock)
    end

    def set_network(pid, network) do
        pid = get_process_name(pid)
        GenServer.call(pid, {:set_network, network})
    end

    def get_network(pid) do
        pid = get_process_name(pid)
        GenServer.call(pid, :get_network)
    end

    def get_state(pid) do
        pid = get_process_name(pid)
        GenServer.call(pid, :get_state)
    end

    def get_state_for_admin(pid) do
        pid = get_process_name(pid)
        GenServer.call(pid, :get_state_for_admin)
    end

    def add_friendship_request(pid, request) do
        pid = get_process_name(pid)
        GenServer.call(pid, {:add_friendship_request, request})
    end

    def friendship_acceptance(pid, acceptance) do
        pid = get_process_name(pid)
        GenServer.call(pid, {:friendship_acceptance, acceptance})
    end

    def reset_friendship_requests(pid) do
        pid = get_process_name(pid)
        GenServer.call(pid, {:reset_friendship_requests})
    end

    def list_network_states(pid) do
        pid = get_process_name(pid)
        GenServer.call(pid, :list_network_states)
    end


    def init(args) do
        [ network: network ] = args
        # create a map for user requests
        requests = %{}
        # return data structure
        {:ok, %{ network: network, friendship_requests: requests }}
    end

    # the tick is all about friendship invitations, this marks the end
    # of the first half of a round
    def handle_info(:tick, state) do
        %{ network: network, friendship_requests: requests } = state

        # create a list of all requests
        payload = create_connect_payloads(network, requests)

        # broadcast to all users
        Phoenix.PubSub.broadcast(
            Nidm.PubSub,
            "network:#{network.id}",
            { :tick, %{ requests: payload } }
        )

        # ask for the tock
        tock()
        # and return async
        { :noreply, state}
    end

    # end of the second part of a round
    def handle_info(:tock, state) do
        %{ network: network, friendship_requests: requests } = state

        # collect all requests
        requests = friendship_requests_to_list(requests)

        # # store the network before edge-map and health update: A
        # store_network_state(network, requests, "A")

        # process all requests:
        # 1. connect / disconnect
        # 2. store
        # 3. update network
        # 4. store network edges
        # 5. broadcast the changes to the clients
        new_map = Enum.reduce requests, network.edge_map, fn req, new_edge_map ->
            # add round
            req = %FriendshipRequest{ req | round: network.round }
            # store request in the database
            FriendshipRequests.insert(req)

            # return new state of the network
            case req.type do
                :disconnect ->
                    NetworkTools.disconnect_nodes(new_edge_map, req.sending_node, req.receiving_node)
                :connect ->
                    case req.accepted do
                        # connect if the invitation is accepted
                        true -> NetworkTools.connect_nodes(new_edge_map, req.sending_node, req.receiving_node)
                        # do nothing if invitation is not accepted
                        false -> new_edge_map
                    end
            end
        end

        # the network has to be updated with the new parameters
        # =====================================================

        # update the edge map
        new_network = %Network{ network | edge_map: new_map }

        # propagate virus
        new_health = propagate_virus(new_network)
        new_network = %Network{ new_network | health: new_health }

        # store the network B, contains new edge map and new health
        store_network_state(new_network, requests, "B")

        # check if end of game and broadcast network to the network clients
        none_infected? = Enum.all? new_health, fn { _, { status, _ } } -> status != :infected end
        last_round? = network.round == 19
        # last_round? = network.round == 2

        { new_round, new_status, reset? } = cond do
            network.status == "warm_up" and network.round == 2 ->
                # reset round and status, reset_virus
                { 0, "phase_1", true}
            network.status == "phase_1" and (none_infected? or last_round?) ->
                # reset round and status, reset_virus
                { 0, "phase_2", true }
            network.status == "phase_2" and (none_infected? or last_round?) ->
                # exit
                { network.round, "exit", false }
            true ->
                # round + 1, status remains, keep new_health
                { network.round + 1, network.status, false }
        end
        new_network = %Network{ new_network | status: new_status, round: new_round }


        # reset the network edges if necessary
        new_network = case reset? == true do
            true ->
                # change condition
                new_condition = case new_network.status do
                    "phase_1" -> new_network.condition_1
                    _ ->
                        case new_network.condition_1 do
                            :clustered -> :unclustered
                            :unclustered -> :clustered
                            :test -> :test
                            :big_test -> :big_test
                        end
                end

                # we need to reset the edges
                new_map = case new_condition do
                    :clustered -> Nidm.NetworkTopologies.clustered
                    :unclustered -> Nidm.NetworkTopologies.unclustered
                    :test -> Nidm.NetworkTopologies.test
                    :big_test -> Nidm.NetworkTopologies.big_test
                end

                new_network = %Network{ new_network |
                    condition_1: new_condition,
                    edge_map: new_map
                }

                # reset node mapping, risk_scores, health
                NetworkTools.reset_network(new_network)

            false -> new_network
        end

        # create new offerings
        new_offerings = NetworkTools.generate_offerings(new_network)
        new_network = %Network{ new_network | offerings: new_offerings }

        # update the points based on open and closed triades
        triads = NetworkTools.find_triads(new_network)
        earned_points = collect_earnings(
            triads,
            new_network.edge_map,
            new_network.health,
            new_network.condition_1
        )
        new_network = %Network{ new_network | earned_points: earned_points }

        # update the users if (old) status is not warmup
        users = Enum.map earned_points, fn { node, points } ->
            user = Users.get_user(new_network.node_mapping[node])
            add_to_total = (network.status != "warm_up")
            Users.set_earned_points(user, points, add_to_total)
        end

        # store the new state of the network to the database
        changeset = Nidm.Resources.Network.round_changeset(network, %{
            risk_scores: new_network.risk_scores,
            node_mapping: new_network.node_mapping,
            condition_1: new_network.condition_1,
            edge_map: new_network.edge_map,
            offerings: new_network.offerings,
            health: new_network.health,
            round: new_network.round,
            status: new_network.status,
            earned_points: new_network.earned_points
        })
        Networks.update(network, changeset, :db)

        # communicate all of this to /task2
        user_message = cond do
            new_status == "exit" ->
                # no more ticks or announcements, set user status
                # to exit questions
                Enum.each(users, &Users.set_status(&1, "exit_questions"))
                :exit
            network.status == "warm_up" and new_status == "phase_1" ->
                stop_announcement()
                :announcement
            network.status == "phase_1" and new_status == "phase_2" ->
                stop_announcement()
                :announcement
            true ->
                tick()
                { :tock, new_network }
        end

        # broadcast
        Phoenix.PubSub.broadcast(Nidm.PubSub, "network:#{network.id}", user_message)

        # new state, reset the requests and store the new network
        new_state = %{ state | friendship_requests: %{}, network: new_network }

        # and return async
        signal = case new_network.status == "exit" do
            true -> { :stop, :shutdown, new_state }
            false -> { :noreply, new_state }
        end

        signal
    end

    defp store_network_state(network, requests, suffix \\ nil) do
        network_state = NetworkStates.insert(network, requests, suffix)
        Phoenix.PubSub.broadcast Nidm.PubSub, "admin", { :update_network, network_state }
    end

    def handle_info(:revert_to_game, state) do
        %{ network: network } = state

        # broadcast to --pause page-- that we go back to game
        Phoenix.PubSub.broadcast(
            Nidm.PubSub,
            "network:#{network.id}",
            :to_game
        )

        # a request a tick
        tick()

        { :noreply, state }
    end

    def handle_cast(:start_clock, state) do
        # start counting down in order to stop the accouncement
        stop_announcement()
        { :noreply, state }
    end

    def handle_call({:set_network, network}, _from, state) do
        state = %{ state | network: network }
        { :reply, network, state }
    end

    def handle_call(:get_network, _from, state) do
        { :reply, state[:network], state }
    end

    def handle_call(:get_state, _from, state) do
        { :reply, state, state }
    end

    def handle_call(:get_state_for_admin, _from, state) do
        %{ network: network, friendship_requests: requests } = state
        request_list = friendship_requests_to_list(requests)
        { :reply, status_for_admin(network, request_list), state }
    end

    def handle_call(:list_network_states, _from, state) do
        %{ network_log: table_id } = state
        {:reply, :ets.select(table_id, [{{:"$1", :"$2"}, [], [[:"$1", :"$2"]]}]) , state}
    end

    def handle_call({:reset_friendship_requests}, _from, state) do
        { :reply, :ok, Map.put(state, :friendship_requests, %{})}
    end

    # add a friendship request, make sure it is unique and can't mess up all other requests
    def handle_call({:add_friendship_request, request}, _from, state) do
        # make sure the request makes sense, do not try to
        # connect a node that is already connected,
        # or disconnect a node that wasn't connected anyways
        %FriendshipRequest{ sender_id: sender_id, sending_node: sending_node,
            receiving_node: receiving_node } = request
        %{ network: network, friendship_requests: friendship_requests } = state

        # add the sender_id and receiver_id to the request
        request = %FriendshipRequest{ request |
            receiver_id: network.node_mapping[receiving_node],
            sender_id: network.node_mapping[sending_node]
        }

        # add request to the database
        new_friendship_requests = add_request_to_cache(friendship_requests, network, request)

        # update the state
        new_state = %{ state | friendship_requests: new_friendship_requests }

        # return
        { :reply, sender_id, new_state }
    end

    # accepting or not accepting a friendship
    def handle_call({:friendship_acceptance, acceptance}, _from, state) do
        %{ friendship_requests: requests } = state
        %{ accept: accept, accepting_node: accepting_node, sending_node: sending_node } = acceptance

        # get the request in question
        req = FriendshipRequests.get(requests, accepting_node, sending_node, false)
        # if it the request exists
        requests = case req do
            false -> requests
            _ ->
                # put the acceptance in there
                updated_request = %FriendshipRequest{ req | accepted: accept }
                FriendshipRequests.update(requests, updated_request)
        end

        # update the state
        new_state = %{ state | friendship_requests: requests }
        # return
        { :reply, acceptance, new_state }
    end

    defp tick() do
        # wait @tick_interval seconds to call the :tick function
        Process.send_after(self(), :tick, @tick_interval)
    end

    defp tock() do
        Process.send_after(self(), :tock, @tock_interval)
    end

    defp stop_announcement() do
        Process.send_after(self(), :revert_to_game, @pause_duration)
    end

    defp get_process_name(arg) do
        case is_pid(arg) do
            true -> arg
            false -> String.to_atom(arg)
        end
    end


    # ================
    # helper functions
    # ================


    def propagate_virus(network) do
        current_round = network.round

        # iterate over nodes and determine if a node gets sick, or immune
        Enum.reduce network.health, %{}, fn { node, health_status }, new_health ->
            { status, infected_at} = health_status
            cond do
                status == :infected and (current_round - infected_at) >= @recovery_period ->
                    Map.put(new_health, node, { :recovered, current_round })
                status == :susceptible ->
                    case infected?(network, node) do
                        true -> Map.put(new_health, node, { :infected, current_round })
                        false -> Map.put(new_health, node, health_status)
                    end
                true ->
                    Map.put(new_health, node, { status, infected_at })
            end
        end
    end


    defp infected?(network, node) do
        friends = network.edge_map[node]
        # how many infected
        infected_friends = Enum.reduce friends, 0, fn f, acc ->
            { status, _round } = network.health[f]
            case status == :infected do
                true -> acc + 1
                false -> acc
            end
        end
        # verdict
        p_infection = p_infection(network.gamma, infected_friends)
        # not infected
        p_not_infection = 1 - p_infection
        # choose
        infected = get_choice(
            [infected: p_infection, not_infected: p_not_infection],
            :rand.uniform
        )
        # return
        infected == :infected
    end


    defp p_infection(gamma, no_friends) do
        1 - :math.pow((1 - gamma), no_friends)
    end


    def add_request_to_cache(db, network, request) do
        %FriendshipRequest{ type: type, sending_node: sender, receiving_node: receiver } = request
        # is there a counterpart?
        counterpart = FriendshipRequests.get(db, sender, receiver, false)
        # are these nodes connected
        sender_receiver_connected = MapSet.member?(network.edge_map[sender], receiver)

        case sender_receiver_connected do
            true ->
                # in general the request must be a disconnect
                case type do
                    :connect ->
                        # only makes sense if there was a disconnect request before this one,
                        # which means these nodes were connected, we just remove the
                        # disconnect if it exists
                        FriendshipRequests.destroy(db, request)
                    :disconnect ->
                        # either there was a previous one or not, we overwrite
                        FriendshipRequests.insert(db, request)
                end


            false ->
                # in general the request must be a connect
                case type do
                    :connect ->
                        case counterpart do
                            false ->
                                FriendshipRequests.insert(db, request)
                            _ ->
                                # update the acceptance
                                counterpart = %FriendshipRequest{ counterpart | accepted: true }
                                request = %FriendshipRequest{ request | accepted: true }
                                # insert
                                db = FriendshipRequests.insert(db, counterpart)
                                FriendshipRequests.insert(db, request)
                        end
                    :disconnect ->
                        # only makes sense if there was connect before this, that means they must
                        # have been disconnected, amd therefore the current disconnect doesn't make
                        # sense, remove the previous disconnect
                        case counterpart do
                            false ->
                                # destroy the previous request if there is any
                                FriendshipRequests.destroy(db, request)
                            _ ->
                                # we need to get rid of the acceptance
                                counterpart = %FriendshipRequest{ counterpart | accepted: false }
                                # insert the counterpart
                                db = FriendshipRequests.update(db, counterpart)
                                # destroy the previous request if there is any
                                FriendshipRequests.destroy(db, request)
                        end
                end
        end
    end


    def create_connect_payloads(network, requests) do
        # select all connect requests and pass 'em to the receiving node
        Map.new(
            Enum.map(network.edge_map, fn { node, _value } ->
                node_requests = requests
                    |> Map.get(node, %{})                       # get the requests of this node (=map)
                    |> Map.values()                             # get the values (the actual requests)
                    |> Enum.map(&(%{from: &1.sending_node,
                        to: &1.receiving_node,
                        accepted: &1.accepted,
                        type: &1.type}))                        # map to a simpler form
                { node, node_requests }
            end)
        )
    end


    def friendship_requests_to_list(requests) do
        Enum.reduce(Map.values(requests), [], &(&2 ++ Map.values(&1)))
    end


    # get points from triads
    def collect_earnings(triads, edge_map, health, condition) do
        Enum.reduce triads, %{}, fn { node, local_triads }, result ->
            %{ open: open, closed: closed } = local_triads
            no_friends = Enum.count(edge_map[node])
            x_i = case (open + closed) != 0 do
                true -> closed / (closed + open)
                false -> 0
            end
            alpha = case condition do
                :clustered -> 0.667
                _ -> 0.0
            end
            # benefits
            benefits =
                (1 * no_friends) +
                0.5 * (1 - 2*(Kernel.abs(x_i - alpha) / Kernel.max(alpha, 1-alpha) ) )
            # cost
            cost = (0.2 * no_friends) + (0.067 * no_friends * no_friends)
            # infection
            sigma = case health[node] do
                { :susceptible, _ } -> 0.0
                { :recovered, _ } -> 0.0
                { :infected, _ } -> 0.34
            end
            # (benefits - cost) can't be lower than 0
            intermediate = benefits - cost
            intermediate = case intermediate < 0 do
                true -> 0
                false -> intermediate
            end
            # points, multiply with 41.6667
            points = round((intermediate - sigma) * 41.667)
            # store
            Map.put(result, node, points)
        end
    end


    defp get_choice([{glyph,_}], _), do: glyph
    defp get_choice([{glyph,prob}|_], ran) when ran < prob, do: glyph
    defp get_choice([{_,prob}|t], ran), do: get_choice(t, ran - prob)


    defp status_for_admin(network, request_list) do
        # count requests
        total_requests = Enum.count(request_list)
        connects = Enum.count(Enum.filter request_list, &(&1.type == :connect))
        disconnects = total_requests - connects
        # return this struct
        %{
            id: network.id,
            round: network.round,
            name: network.name,
            status: network.status,
            edges: Kernel.floor(Enum.reduce(network.edge_map, 0, fn { _n, edges }, acc -> acc + Enum.count(edges) end) / 2),
            connects: connects,
            disconnects: disconnects,
            infected: Enum.count(network.health, fn { _node, { status, _round} } -> status == :infected end)
        }

    end

end
