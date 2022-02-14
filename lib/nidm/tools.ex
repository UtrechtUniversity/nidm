defmodule Nidm.Tools do

    alias Nidm.Repo
    alias Nidm.GenServers.{ Gate, Cache, NetworkSupervisor, NetworkMonitor }
    alias Nidm.Resources.{ User, RiskQuestion, Network, FriendshipRequest, NetworkState, ExitQuestion }
    alias Nidm.{ Users, Networks, RiskQuestions, Exporter }

    require Logger
    require ExUnit.Assertions

    @chars "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.codepoints

    # reset all tables
    # Nidm.Tools.reset_db
    def reset_db do
        Repo.delete_all(Network)
        Repo.delete_all(User)
        Repo.delete_all(RiskQuestion)
        Repo.delete_all(FriendshipRequest)
        Repo.delete_all(NetworkState)
        Repo.delete_all(ExitQuestion)
    end

    def reset_servers do
        Gate.reset
        Cache.reset(:users)
        Cache.reset(:risk_questions)
        Cache.reset(:network_states)
        Cache.reset(:friendship_requests)

        # remove all instances of NetworkMonitors
        Enum.map DynamicSupervisor.which_children(NetworkSupervisor), fn { _, pid, _, _ } ->
            DynamicSupervisor.terminate_child(NetworkSupervisor, pid)
        end

        # and spin the whole goddamn thing up again
        { :ok, _ } = Application.ensure_all_started(:nidm)
    end

    # generate a random string of length <length>
    def generate_rand_string(length) do
        Enum.reduce((1..length), [], fn (_i, acc) ->
            [ Enum.random(@chars) | acc ]
        end) |> Enum.join("")
    end

    def pick_unique_token(length \\ 8, tokens \\ []) do
        token = generate_rand_string(length)
        if Enum.member? tokens, token do
            pick_unique_token(length, tokens)
        else
            token
        end
    end

    # generate a bunch of user accounts
    # Nidm.Tools.generate_user_accounts(20)
    def generate_user_accounts(n \\ 100) do
        # create user accounts
        result = Enum.reduce (1..n), %{ users: [], tokens: [] }, fn i, acc ->
            # start creating the user accounts
            new_token = pick_unique_token(8, acc.tokens)
            # create user account
            user = %User{
                serial_number: i,
                role: "subject",
                id: Ecto.UUID.generate,
                access_token: new_token,
                exit_token: generate_rand_string(12)
            }
            # insert
            Users.create(user)

            acc = Map.put(acc, :users, [user | acc.users])
            acc = Map.put(acc, :tokens, [user.access_token | acc.tokens])
            acc
        end
        # return the users
        result.users
    end

    def generate_admin_account() do
        token = "rollthedice"
        user = %User{
            serial_number: 0,
            role: "admin",
            id: Ecto.UUID.generate,
            access_token: token,
            exit_token: "whatever"
        }
        # is there an admin?
        admin = Nidm.Repo.get_by(User, role: "admin")
        case admin do
            nil ->  Nidm.Repo.insert!(user)
            _ -> admin
        end
    end

    def import_user_tokens(path, store \\ :all) do
        tokens = path
        |> File.stream!
        |> CSV.decode
        |> Enum.map(&(&1))

        # remove header
        [ _header | tokens ] = tokens

        Enum.map Enum.with_index(tokens), fn {{ :ok, [prolific_pid, session_id, access_token, exit_token, redirect_url] }, index } ->
            user = %User{
                serial_number: index + 1,
                role: "subject",
                id: Ecto.UUID.generate,
                prolific_pid: prolific_pid,
                session_id: session_id,
                access_token: access_token,
                exit_token: exit_token,
                redirect_url: redirect_url
            }
            case store do
                :db -> Nidm.Repo.insert!(user)
                _ -> Users.create(user)
            end
        end
    end

    def generate_risk_questions(store \\ :all) do
        Enum.each Users.list_users(store), fn user ->
            # create a risk record for this user
            question = %RiskQuestion{
                id: Ecto.UUID.generate,
                user_id: user.id
            }
            case store do
                :db -> Nidm.Repo.insert!(question)
                _ -> RiskQuestions.create(question)
            end
        end
        :ok
    end

    def generate_network(
        name \\ "network", condition_1 \\ :clustered,
        condition_2 \\ :random, gamma \\ 0.15, store \\ :all) do

        topo = case condition_1 do
            :clustered -> Nidm.NetworkTopologies.clustered
            :unclustered -> Nidm.NetworkTopologies.unclustered
            :test -> Nidm.NetworkTopologies.test
            :big_test -> Nidm.NetworkTopologies.big_test
            _ -> %{}
        end

        network = %Network{
            id: Ecto.UUID.generate,
            name: name,
            condition_1: condition_1,
            condition_2: condition_2,
            status: "available",
            edge_map: topo,
            gamma: gamma
        }

        IO.inspect(Enum.member?([:clustered, :unclustered], network.condition_1) == true)
        IO.inspect(Enum.member?([:random, :assortative], network.condition_2) == true)

        case store do
            :db ->
                # infections
                health = Map.new(Enum.map network.edge_map, fn { node, _ } -> { node, { :susceptible, 0 } } end)
                # make sure the network is set to round 0
                network = %Network{ network | round: 0, health: health }
                # insert
                Nidm.Repo.insert(network)
            _ ->
                # create normally
                Networks.create(network)
        end
    end

    def generate_test_network(
        name \\ "network", condition_1 \\ :clustered,
        condition_2 \\ :random, gamma \\ 0.15) do

        topo = case condition_1 do
            :clustered -> Nidm.NetworkTopologies.clustered
            :unclustered -> Nidm.NetworkTopologies.unclustered
            :test -> Nidm.NetworkTopologies.test
            :big_test -> Nidm.NetworkTopologies.big_test
            _ -> %{}
        end

        network = %Network{
            id: Ecto.UUID.generate,
            name: name,
            condition_1: condition_1,
            condition_2: condition_2,
            status: "available",
            edge_map: topo,
            gamma: gamma
        }

        nodes = Map.keys(network.edge_map)
        risk_scores = Map.new(
            Enum.map nodes, &({ &1, Enum.random(1..32)})
        )
        network = %Network{ network | risk_scores: risk_scores }

        Networks.create(network)
    end


    def export_user_accounts(n \\ 200, url \\ false, filename \\ "tokens.csv") do
        users = generate_user_accounts(n)
        Nidm.Exporter.export_access_tokens(users, url, filename)
    end

    # Nidm.Tools.bootstrap
    def bootstrap(n \\ 200) do
        reset_db()
        reset_servers()
        generate_user_accounts(n)
        generate_risk_questions()
        # create networks
        networks = 1..(div(n, 80) + 1)
        Enum.each networks, fn n ->
           generate_network("network_#{n}")
        end
        [ user | _ ] = Users.list_users()
        "localhost:4000/welcome?access_token=#{user.access_token}"
    end

    def bootstrap_test() do
        reset_db()
        reset_servers()
        # n1 = generate_network("network_1", :big_test)
        # _ = generate_network("network_2", :big_test)

        n1 = generate_network("network_1", :test)
        _ = generate_network("network_2", :test)

        generate_user_accounts(Enum.count(Map.keys(n1.edge_map)))
        generate_risk_questions()

        # kill the gate genserver and restart to get the appropriate capacity
        GenServer.stop(Gate)
        # This ensures that all is running again after crashing te supervisor
        { :ok, _ } = Application.ensure_all_started(:nidm)
        # export the csv
        Exporter.export_users([:access_token, :exit_token])
    end

    def fill_queue(n \\ 20) do
        # select users who are not waiting
        users = Enum.filter(Users.list_users(), fn u -> u.status == nil end)

        # users = if Enum.count(users) < n do
        #     generate_user_accounts(n)
        # else
        #     users
        # end

        # take a number of them
        users = Enum.take(users, n)
        # set the risk score of those
        users = Enum.map(users, fn u -> Users.set_risk_score(u, Enum.random(1..32)) end)

        for u <- users do
            Gate.add_user(u)
            :timer.sleep(100)
        end
    end

    def simulate(network_id, node, n \\ 1, type \\ :connect, clock_start \\ true) do
        # start the clock
        case clock_start do
            true -> NetworkMonitor.start_clock(network_id)
            false -> :ok
        end
        # get network
        %{ network: network } = NetworkMonitor.get_state(network_id)
        # reset friendships
        NetworkMonitor.reset_friendship_requests(network_id)
        # find a nice node
        others = find_unconnected_nodes(network, node, n)
        # set up friendship requests
        Enum.each others, fn other ->
            request = %FriendshipRequest{
                id: Ecto.UUID.generate,
                type: type,
                sending_node: other,
                receiving_node: node,
                timestamp: System.os_time(:second),
                accepted: false
            }
            # send it
            NetworkMonitor.add_friendship_request(network_id, request)
        end
    end


    def find_unconnected_nodes(network, node, n) do
        # get all nodes
        all_nodes = MapSet.new(Map.keys(network.edge_map))
        # get the neighbours of this node
        dont_choose = MapSet.put(network.edge_map[node], node)
        choose = MapSet.difference(all_nodes, dont_choose)
        Enum.take_random(choose, n)
    end

end
