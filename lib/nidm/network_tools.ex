defmodule Nidm.NetworkTools do

    alias Nidm.Resources.Network
    alias Nidm.{ Networks, Users }

    require Logger

    # this function determines which node the NetworkMonitor introduces to
    # another node
    def generate_offerings(network) do
        phi = 0.2
        all_nodes = MapSet.new(Map.keys(network.edge_map))
        size = MapSet.size(all_nodes)
        nodes_offered = Kernel.round(phi * size)
        risk_scores = network.risk_scores
        max_risk_score = Enum.max(Map.values(risk_scores))

        psi = 0.5
        xi = 0.3

        omega = case network.condition_2 == :random do
            true -> 0.0
            false -> 0.8
        end

        offerings = Enum.map network.edge_map, fn { node, direct_friends } ->

            # collect indirect friends
            indirect_friends = indirect_friends(network, node)

            set = Enum.reduce_while 1..size, MapSet.new([]), fn _, acc ->
                # draw a random number
                x = :rand.uniform()

                target_set = cond do
                    x <= psi ->
                        direct_friends
                        |> MapSet.difference(acc)

                    (x > psi) and x <= (psi + xi) ->
                        indirect_friends
                        |> MapSet.difference(acc)

                    true ->
                        # pick from all other nodes
                        MapSet.difference(all_nodes, MapSet.new([node]))
                        |> MapSet.difference(direct_friends)
                        |> MapSet.difference(indirect_friends)
                        |> MapSet.difference(acc)
                end

                # we have to pick something if target set is still empty
                target_set = case MapSet.size(target_set) == 0 do
                    true -> MapSet.difference(all_nodes, MapSet.new([node]))
                    false -> target_set
                end

                # draw random number y
                y = :rand.uniform()
                # sort
                sorted_offer_nodes = case y < omega do
                    true ->
                        with_scores = Enum.map target_set, fn other ->
                            score = risk_similarity(node, other, risk_scores, max_risk_score)
                            { other, score }
                        end
                        sorted = Enum.sort with_scores, fn {_, s1}, {_, s2} ->
                            s1 < s2
                        end
                        Enum.map sorted, fn { node, _ } -> node end
                    false ->
                        Enum.shuffle(target_set)
                end

                # add first element to set if there is one
                acc = case Enum.empty?(sorted_offer_nodes) do
                    true -> acc
                    false ->
                        [offer | _] = sorted_offer_nodes
                        MapSet.put(acc, offer)
                end

                # reduce while
                case MapSet.size(acc) == nodes_offered do
                    true -> { :halt, acc }
                    false -> { :cont, acc }
                end
            end

            { node, set }

        end

        Map.new(offerings)
    end

    defp risk_similarity(node1, node2, risk_scores, max_risk_score) do
        diff = risk_scores[node1] - risk_scores[node2]
        perc_diff = diff / max_risk_score
        Kernel.abs(perc_diff)
    end


    def direct_friends(network, node) do
        network.edge_map[node]
    end

    def indirect_friends(network, node) do
        # get direct friends
        direct = direct_friends(network, node)
        # get friends of friends
        indirect = Enum.reduce direct, MapSet.new([]), fn friend, acc ->
            MapSet.union(acc, network.edge_map[friend])
        end
        # remove direct friends
        indirect = MapSet.difference(indirect, direct)
        # remove node
        MapSet.difference(indirect, MapSet.new([node]))
    end


    def connect_nodes(edge_map, node_1, node_2) do
        # get neighbours of node_1
        neighbours = edge_map[node_1]
        # add node_2 to neighbours
        neighbours = MapSet.put(neighbours, node_2)
        # store
        edge_map = Map.put(edge_map, node_1, neighbours)

        # now do the same thing for node 2
        neighbours = edge_map[node_2]
        # add node_1 to neighbours
        neighbours = MapSet.put(neighbours, node_1)
        # store
        edge_map = Map.put(edge_map, node_2, neighbours)

        # return
        edge_map
    end


    def disconnect_nodes(edge_map, node_1, node_2) do
        # get neighbours of node_1
        neighbours = edge_map[node_1]
        # remove node_2 from neighbours
        neighbours = MapSet.delete(neighbours, node_2)
        # store
        edge_map = Map.put(edge_map, node_1, neighbours)

        # now do the same thing for node 2
        neighbours = edge_map[node_2]
        # remove node_1 from neighbours
        neighbours = MapSet.delete(neighbours, node_1)
        # store
        edge_map = Map.put(edge_map, node_2, neighbours)

        # return
        edge_map
    end


    # connect a list of user_ids to an available network
    def set_network(user_ids, queue_name) do
        # find empty network
        networks = Networks.available_networks()
        if Enum.count(networks) > 0 do
            # take the first available list
            [ network | _ ] = networks

            # sort user_ids by risk score
            users = user_ids
                |> Enum.map(&Users.get_user(&1))
                |> Enum.sort(&(&1.risk_score >= &2.risk_score))

            user_ids = Enum.map users, &(&1.id)

            # load seating arrangement
            arrangement = Networks.initial_seating_arrangement(network)

            # create node mapping by zipping the user_ids and the nodes
            # from the seating arrangement
            node_mapping = Map.new(Enum.zip(arrangement, user_ids))
            user_mapping = Map.new(Enum.zip(user_ids, arrangement))

            # get and add risk scores
            risk_scores = Enum.map users, fn user ->
                node_id = user_mapping[user.id]
                { node_id, user.risk_score }
            end
            risk_scores = Map.new(risk_scores)

            # generate the initial offerings
            tmp = %Network{ network | risk_scores: risk_scores }
            offerings = generate_offerings(tmp)

            # infect a node
            new_health = initial_infection(network)

            # update network
            changeset = Network.init_changeset(network, %{
                status: "warm_up",
                from_queue: queue_name,
                node_mapping: node_mapping,
                risk_scores: risk_scores,
                offerings: offerings,
                health: new_health
            })
            network = Networks.update(network, changeset)

            # also broadcast to admin
            Phoenix.PubSub.broadcast Nidm.PubSub, "admin", { :network_filled, network }

            # now connect the users and broadcast
            Enum.each users, fn user ->
                node_id = user_mapping[user.id]
                network_id = network.id
                Users.set_network(user, network_id, node_id)
                # broadcast this data over the wait channel
                Phoenix.PubSub.broadcast Nidm.PubSub, "user:#{ user.id }", :start_game
            end
            # return the network
            network
        else
            :no_network
        end
    end


    # connect a list of user_ids to an available network
    def reset_network(network) do

        # sort user_ids by risk score
        users = Map.values(network.node_mapping)
            |> Enum.map(&Users.get_user(&1))
            |> Enum.sort(&(&1.risk_score >= &2.risk_score))

        user_ids = Enum.map users, &(&1.id)

        # load seating arrangement
        arrangement = Networks.initial_seating_arrangement(network)

        # create node mapping by zipping the user_ids and the nodes
        # from the seating arrangement
        node_mapping = Map.new(Enum.zip(arrangement, user_ids))
        user_mapping = Map.new(Enum.zip(user_ids, arrangement))

        # get and add risk scores
        risk_scores = Enum.map users, fn user ->
            node_id = user_mapping[user.id]
            { node_id, user.risk_score }
        end
        risk_scores = Map.new(risk_scores)

        # infect a node
        new_health = reset_virus(network)

        new_network = %Network{ network |
            node_mapping: node_mapping,
            risk_scores: risk_scores,
            health: new_health
        }

        # also broadcast to admin
        Phoenix.PubSub.broadcast Nidm.PubSub, "admin", { :network_filled, new_network }

        # now connect the users and broadcast
        Enum.each users, fn user ->
            node_id = user_mapping[user.id]
            network_id = network.id
            Users.set_network(user, network_id, node_id)
        end
        # return the network
        new_network
    end


    def reset_virus(network) do
        new_health = Map.new(
            Enum.map network.edge_map, fn { node, _ } ->
                { node, { :susceptible, 0 } }
            end
        )
        network = %Network{ network | health: new_health }
        # infect one participant
        initial_infection(network)
    end


    def initial_infection(network) do
        # load seating arrangement
        arrangement = Networks.initial_seating_arrangement(network)

        # infect a poor schmuck, take the middle one
        no_nodes = Enum.count(network.edge_map)
        node = Enum.at(arrangement, Kernel.floor(no_nodes / 2) - 1)

        # and infect it
        Map.put(network.health, node, { :infected, 0 })
    end


    def subtree(network, node_id, max_depth \\ 1) do
        subtree = collect_subtree(network, node_id, max_depth, 0, MapSet.new([]))
        MapSet.to_list(subtree)
    end

    # recursively go through tree
    defp collect_subtree(network, node_id, max_depth, depth, collected) do
        # add this node to collected
        collected = MapSet.put(collected, node_id)
        # get the neighbours of node_id
        children = network.edge_map[node_id]
        # remove kids that were already done
        children = MapSet.difference(children, collected)

        # what are we going to do
        cond do
            Enum.count(children) == 0 -> collected
            max_depth == depth -> collected
            max_depth > depth ->
                Enum.reduce children, collected, fn n_id, col ->
                    grandkids = collect_subtree(network, n_id, max_depth, depth + 1, col)
                    MapSet.union(col, grandkids)
                end
        end
    end


    @doc """
    This function produces a topology suitable for vis-network.js. It takes
    a network (for the edge map), a non mandatory set of nodes that will override
    the complete set of nodes of the network and a non mandatory focus node.
    The function will create a data structure for the nodes first and then for the
    edges.
    """
    def get_topology(network, nodes \\ nil) do
        # get all relevant nodes
        nodes = case nodes != nil do
            true -> nodes # use the nodes from the subset
            false -> Map.keys(network.edge_map) # no subset, all nodes of the network
        end
        nodes_set = MapSet.new(nodes)

        # create an efficient loop to produce unique edges (we don't have a
        # directed graph)
        links = Enum.reduce nodes_set, MapSet.new([]), fn node_id, acc ->
            neighbours = network.edge_map[node_id]
            # make sure this still works when the total set of nodes is restricted
            neighbours = MapSet.intersection(neighbours, nodes_set)
            # collect edges
            edges = Enum.reduce neighbours, MapSet.new([]), fn neighbour, sub_acc ->
                pair = Enum.min_max([ node_id, neighbour ])
                MapSet.put(sub_acc, pair)
            end
            MapSet.union(acc, edges)
        end

        # create the data structure for the links
        link_data = Enum.map links, fn { from, to } ->
            %{ id: "#{from}-#{to}", from: from, to: to }
        end

        %{ nodes: nodes, edges: link_data }
    end

    def find_triads(network) do
        Enum.reduce network.edge_map, %{}, fn { node, friends }, triads ->
            friend_combs = combinations(MapSet.to_list(friends))
            found_triads = Enum.reduce friend_combs, %{open: 0, closed: 0}, fn { n1, n2 }, counter ->
                no_open = counter.open
                no_closed = counter.closed
                # check if n1 and n2 are connected?
                case MapSet.member?(network.edge_map[n1], n2) do
                    true -> Map.put(counter, :closed, no_closed + 1)
                    false -> Map.put(counter, :open, no_open + 1)
                end
            end
            Map.put(triads, node, found_triads)
        end
    end

    # get all the combinations of 2
    def combinations([]), do: []
    def combinations([_]), do: []
    def combinations([h|tail]) do
        Enum.map(tail, &({h, &1})) ++  combinations(tail)
    end



end
