defmodule Nidm.Networks do
    alias Nidm.Repo
    alias Nidm.Resources.Network
    alias Nidm.GenServers.{ DatabaseQueue, NetworkMonitor, NetworkSupervisor }
    alias Nidm.NetworkTools

    import Ecto.Changeset
    import Ecto.Query, only: [order_by: 2]

    require Logger

    def create(network) do
        # make sure a uuid is set
        network = case network.id == nil do
            true -> %Network{ network | id: Ecto.UUID.generate }
            false -> network
        end

        # infections
        health = Map.new(
            Enum.map network.edge_map, fn { node, _ } ->
                { node, { :susceptible, 0 } }
            end
        )

        # offerings
        offerings = NetworkTools.generate_offerings(network)

        # make sure the network is set to round 0
        network = %Network{ network | round: 0, health: health, offerings: offerings }

        # store async in database
        DatabaseQueue.add(
            %{ action: "insert", id: network.id, resource: network }
        )

        # start a GenServer for this network
        spec = { Nidm.GenServers.NetworkMonitor, network: network }
        NetworkSupervisor.start_child(spec)

        # return inserted network
        network
    end

    # returns a changeset if validation
    def update(%Network{} = network, changeset, store \\ :all) do
        case changeset.valid? do
            false ->
                # make sure the action is set so the form will pick up the errors for
                # the error tags
                %{ changeset | action: :update}
            true ->
                updated_network = apply_changes(changeset)

                case store do
                    :all ->
                        DatabaseQueue.add(%{ action: "update", id: network.id, resource: changeset })
                        NetworkMonitor.set_network(network.id, updated_network)
                    :db ->
                        DatabaseQueue.add(%{ action: "update", id: network.id, resource: changeset })
                    :cache ->
                        NetworkMonitor.set_network(network.id, updated_network)
                end

                # return updated user
                updated_network
        end
    end

    def get_network(id, store \\ :cache) do
        case store do
            :cache ->
                NetworkMonitor.get_network(id)
            :db ->
                Repo.get(Network, id)
        end
    end

    def list_networks(store \\ :cache) do
        case store do
            :cache ->
                Enum.map DynamicSupervisor.which_children(NetworkSupervisor), fn { _, pid, _, _ } ->
                    NetworkMonitor.get_network(pid)
                end
            :db ->
                Network
                |> order_by(asc: :inserted_at)
                |> Repo.all()
        end
    end

    def available_networks() do
        Enum.filter(list_networks(), fn n -> n.status == "available" end)
        |> Enum.sort_by(&(&1.name))
    end

    def set_status(network, status) do
        changeset = Network.status_changeset(network, %{ status: status })
        update(network, changeset)
    end

    def initial_seating_arrangement(network) do
        cond do
            network.condition_1 == :unclustered and network.condition_2 == :random ->
                ["20", "27", "19", "38", "22", "59", "18", "55", "25", "41", "1", "30", "60",
                "42", "43", "47", "33", "40", "17", "6", "36", "16", "57", "44", "32", "51",
                "54", "37", "53", "35", "12", "48", "15", "21", "31", "8", "10", "24", "46",
                "56", "29", "45", "49", "3", "2", "4", "14", "11", "23", "13", "5", "50", "9",
                "26", "58", "34", "52", "7", "39", "28"]
            network.condition_1 == :unclustered and network.condition_2 == :assortative ->
                ["53", "3", "24", "19", "11", "29", "47", "22", "59", "5", "17", "28", "56",
                "13", "44", "34", "36", "57", "55", "12", "41", "43", "1", "21", "33", "31",
                "10", "39", "46", "35", "30", "16", "48", "50", "14", "37", "23", "20", "32",
                "7", "4", "8", "27", "58", "38", "42", "6", "60", "45", "9", "26", "49", "40",
                "52", "15", "51", "54", "25", "2", "18"]
            network.condition_1 == :clustered and network.condition_2 == :random ->
                ["28", "55", "18", "27", "3", "58", "34", "59", "46", "45", "54", "36", "29",
                "25", "38", "57", "60", "13", "39", "24", "49", "6", "8", "11", "41", "33",
                "14", "21", "37", "4", "50", "52", "40", "7", "23", "9", "22", "17", "20",
                "43", "1", "16", "31", "42", "12", "56", "5", "2", "26", "30", "48", "15",
                "53", "35", "10", "47", "32", "44", "51", "19"]
            network.condition_1 == :clustered and network.condition_2 == :assortative ->
                ["36", "6", "57", "48", "16", "21", "38", "47", "30", "27", "58", "12", "25",
                "53", "31", "19", "8", "56", "26", "20", "18", "35", "13", "15", "3", "59",
                "33", "23", "37", "4", "11", "2", "1", "34", "51", "32", "52", "28", "54", "7",
                "17", "22", "39", "10", "44", "49", "46", "9", "29", "42", "5", "40", "14",
                "45", "50", "55", "43", "24", "41", "60"]
            network.condition_1 == :test ->
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"]
        end
    end
end
