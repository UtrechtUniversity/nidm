defmodule Nidm.NetworkStates do

    alias Nidm.Repo
    alias Nidm.Resources.NetworkState
    alias Nidm.GenServers.DatabaseQueue
    alias Nidm.GenServers.Cache

    import Ecto.Query, only: [order_by: 2]

    def insert(network, request_list \\ [], round_suffix \\ nil, store \\ :all) do
        # store the edge map
        id = Ecto.UUID.generate
        # process the request list

        total_requests = Enum.count(request_list)
        connects = Enum.count(Enum.filter request_list, &(&1.type == :connect))
        disconnects = total_requests - connects

        # create the network state
        network_state = %NetworkState{
            id: id,
            round: network.round,
            round_sub: round_suffix,
            status: network.status,
            gamma: network.gamma,
            network_id: network.id,
            condition_1: network.condition_1,
            condition_2: network.condition_2,
            node_mapping: network.node_mapping,
            edge_map: network.edge_map,
            health: network.health,
            offerings: network.offerings,
            earned_points: network.earned_points,
            timestamp: System.os_time(:second),
            edges: Kernel.floor(Enum.reduce(network.edge_map, 0, fn { _n, edges }, acc -> acc + Enum.count(edges) end) / 2),
            connects: connects,
            disconnects: disconnects,
            infected: Enum.count(network.health, fn { _node, { status, _round} } -> status == :infected end)
        }

        # store
        case store do
            :all ->
                # write to cache
                Cache.set(:network_states, id, network_state)
                # write to database
                DatabaseQueue.add(%{ action: "insert", id: id, resource: network_state })
            :cache ->
                # write to cache
                Cache.set(:network_states, id, network_state)
            :db ->
                # write to database
                DatabaseQueue.add(%{ action: "insert", id: id, resource: network_state })
        end

        # return the state
        network_state
    end

    def list_network_states(store \\ :cache) do
        case store do
            :cache ->
                Cache.list_values(:network_states)
                |> Enum.sort_by(&{&1.network_id, &1.timestamp, &1.round, &1.round_sub})
            :db ->
                NetworkState
                |> order_by(asc: :timestamp)
                |> Repo.all()
        end
    end

end
