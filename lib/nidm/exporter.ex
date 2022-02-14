defmodule Nidm.Exporter do

    alias Nidm.Repo
    alias Nidm.Resources.{ User, ExitQuestion }
    alias Nidm.{ Users, Networks, NetworkStates, ExitQuestions, FriendshipRequests, RiskQuestions }
    alias CSV

    @root_folder Application.get_env(:nidm, :export_path)

    def export_access_tokens(users, url \\ false, filename \\ "tokens.csv") do
        file = open_file(filename)

        tokens = Enum.map users, &([&1.access_token, &1.exit_token])
        headers = ["access_token", "exit_token"]
        { headers, tokens } = case url do
            false -> { headers, tokens }
            _ -> { headers ++ ["url"], Enum.map(tokens, &(&1 ++ ["#{url}?access_token=#{List.first(&1)}"])) }
        end

        Repo.transaction(fn ->
            [headers]
            |> Stream.concat(Stream.map(tokens, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)
        # return path
        :ok
    end

    def export() do
        ts = System.os_time(:second)
        requests = FriendshipRequests.list_friendship_requests()
            |> Enum.filter(fn req -> req.network_status != "warm_up" end)

        requests_sender = process_requests(requests, :sender)
        requests_receiver = process_requests(requests, :receiver)

        users()
        network_data()
        stage1_data(requests_sender)
        stage2_data(requests_receiver)
        prolific()

        # #export_network_states()
        # #export_requests()

        # remove all zip files
        Path.wildcard("#{@root_folder}/*.zip") |> Enum.each(&File.rm(&1))

        # zip both files and send
        zip_file = "#{@root_folder}/#{ts}-export.zip"
        files = ["users.csv", "network_data.csv", "stage_1_data.csv",
            "stage_2_data.csv", "prolific.csv"]
            |> Enum.map(&String.to_charlist/1)
        { _, path } = :zip.create(zip_file, files, cwd: @root_folder)

        # broadcast to live view
        Phoenix.PubSub.broadcast(
            Nidm.PubSub,
            "admin",
            { :export_ready, path }
        )

        :ok
    end


    def users() do
        file = open_file("users.csv")
        states = NetworkStates.list_network_states(:db)
        columns = [
            "session_id", "time_stamp", "r_score", "cond_mixing",
            "cond_game_run1", "net_node_id_a", "net_node_id_b",
            "completed", "q_age", "q_gender", "q_mtongue", "q_edu",
            "q_residence", "q_c19_concern", "q_c19_positive", "remarks"
        ]

        subjects = Users.list_subjects(:db)
        data = Enum.reduce subjects, [], fn user, acc ->
            { condition, mixing, node_a, node_b } = process_user_info_from_states(user, states)
            exit_questions = ExitQuestions.get_by_user_id(user.id) || %ExitQuestion{}
            completed = case Enum.member?(["exit", "exit_questions"], user.status) do
                true -> 1
                false -> 0
            end
            record = [
                user.network_id,
                NaiveDateTime.to_string(user.updated_at),
                user.risk_score,
                mixing,
                condition,
                node_a,
                node_b,
                completed,
                exit_questions.q_age,
                exit_questions.q_gender,
                exit_questions.q_mtongue,
                exit_questions.q_edu,
                exit_questions.q_residence,
                exit_questions.q_c19_concern,
                exit_questions.q_c19_positive,
                exit_questions.q_remarks
            ]
            [record | acc ]
        end
        Repo.transaction(fn ->
            [columns]
            |> Stream.concat(Stream.map(data, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)
        # return path
        :ok
    end

    def network_data() do
        file = open_file("network_data.csv")
        states = Enum.filter NetworkStates.list_network_states(:db), fn ns ->
            ns.round_sub == "B" and (Enum.member?(["phase_1", "phase_2"], ns.status))
        end
        nodes = Enum.map(1..60, &("#{&1}"))

        columns = [
            "session_id", "net_type", "game_round", "net_node_id",
            "net_node_state", "net_tie"
        ]

        data = Enum.reduce states, [], fn ns, result ->
            r2 = Enum.reduce nodes, [], fn node, records ->
                r1 = Enum.map ns.edge_map[node], fn other ->
                    [
                        ns.network_id,
                        (if (ns.condition_1 == :clustered), do: "B", else: "A"),
                        ns.round,
                        node,
                        get_health(node, ns.health),
                        other
                    ]
                end
                records ++ r1
            end
            result ++ r2
        end

        Repo.transaction(fn ->
            [columns]
            |> Stream.concat(Stream.map(data, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)

        :ok
    end

    defp get_health(node, health) do
        { state, _ } = health[node]
        case state do
            :susceptible -> 1
            :infected -> 2
            :recovered -> 3
        end
    end

    def stage1_data(requests) do
        file = open_file("stage_1_data.csv")
        states = Enum.filter NetworkStates.list_network_states(:db), fn ns ->
            ns.round_sub == "B" and (Enum.member?(["phase_1", "phase_2"], ns.status))
        end
        nodes = Enum.map(1..60, &("#{&1}"))

        columns = [
            "session_id", "net_type", "game_round", "net_node_id",
            "offer", "offer_accepted", "action"
        ]

        data = Enum.reduce states, [], fn ns, result ->
            r2 = Enum.reduce nodes, [], fn node, records ->
                haystack = requests[{ node, ns.network_id }] || []
                r1 = Enum.map ns.offerings[node], fn offer ->
                    needle = Enum.find haystack, fn straw ->
                        straw.receiving_node == offer and
                            straw.network_status == ns.status and
                            straw.round == ns.round
                    end
                    [
                        ns.network_id,
                        (if (ns.condition_1 == :clustered), do: "B", else: "A"),
                        ns.round,
                        node,
                        offer,
                        (if needle == nil, do: 0, else: 1),
                        process_request_decision(needle)
                    ]
                end
                records ++ r1
            end
            result ++ r2
        end

        Repo.transaction(fn ->
            [columns]
            |> Stream.concat(Stream.map(data, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)

        :ok
    end


    def stage2_data(requests) do
        file = open_file("stage_2_data.csv")
        states = Enum.filter NetworkStates.list_network_states(:db), fn ns ->
            ns.round_sub == "B" and (Enum.member?(["phase_1", "phase_2"], ns.status))
        end
        nodes = Enum.map(1..60, &("#{&1}"))

        columns = [
            "session_id", "net_type", "game_round", "net_node_id",
            "request_in", "request_accept"
        ]

        data = Enum.reduce states, [], fn ns, result ->
            r2 = Enum.reduce nodes, [], fn receiver, records ->
                connects = requests[{ receiver, ns.network_id }]
                    |> Enum.filter(fn req ->
                        req.network_status == ns.status and
                            req.round == ns.round and
                            req.type == :connect
                    end)
                r1 = Enum.map connects, fn con ->
                    [
                        ns.network_id,
                        (if (ns.condition_1 == :clustered), do: "B", else: "A"),
                        ns.round,
                        receiver,
                        con.sending_node,
                        (if con.accepted == true, do: 1, else: 0)
                    ]
                end
                records ++ r1
            end
            result ++ r2
        end

        Repo.transaction(fn ->
            [columns]
            |> Stream.concat(Stream.map(data, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)

        :ok
    end


    def prolific() do
        file = open_file("prolific.csv")

        columns = [
            "session_id", "time_stamp", "prolific_pid", "completed",
            "dur_minutes", "score", "fee (pounds)"
        ]

        data = Enum.map Users.list_subjects(:db), fn u ->
            t0 = (RiskQuestions.get_question_by_user(u.id, :db)).updated_at
            t1 = u.updated_at
            diff = round(NaiveDateTime.diff(t1, t0, :second)/60)

            points = u.earned_points || 0.0
            fee = Float.round((points / 500), 2)
            [
                u.network_id,
                NaiveDateTime.to_string(u.updated_at),
                u.prolific_pid,
                (if Enum.member?(["exit", "exit_questions"], u.status), do: 1, else: 0),
                diff,
                points,
                fee
            ]
        end

        Repo.transaction(fn ->
            [columns]
            |> Stream.concat(Stream.map(data, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)

        :ok
    end


    defp process_requests(requests, how) do
        Enum.reduce requests, %{}, fn req, result ->
            key = case how do
                :sender -> { req.sending_node, req.network_id }
                :receiver -> { req.receiving_node, req.network_id }
            end
            node_reqs = Map.get(result, key, [])
            node_reqs = [ req | node_reqs ]
            Map.put(result, key, node_reqs)
        end
    end


    defp process_request_decision(needle) do
        cond do
            needle == nil -> 0
            needle.type == :connect -> 1
            needle.type == :disconnect -> 2
        end
    end



    defp process_user_info_from_states(user, states) do
        phase_1 = Enum.find states, fn s ->
            s.network_id == user.network_id and s.status == "phase_1" and s.round == 0
        end
        phase_2 = Enum.find states, fn s ->
            s.network_id == user.network_id and s.status == "phase_2" and s.round == 0
        end

        if not(phase_1 == nil or phase_2 == nil) do

            condition = if phase_1.condition_1 == :clustered, do: "B", else: "A"
            mixing = if phase_1.condition_2 == :random, do: 1, else: 2

            user_mapping_1 = Map.new(phase_1.node_mapping, fn {key, val} -> {val, key} end)
            user_mapping_2 = Map.new(phase_2.node_mapping, fn {key, val} -> {val, key} end)

            node_b = case phase_1.condition_1 == :clustered do
                true -> user_mapping_1[user.id]
                false -> user_mapping_2[user.id]
            end

            node_a = case phase_1.condition_1 == :clustered do
                true -> user_mapping_2[user.id]
                false -> user_mapping_1[user.id]
            end

            { condition, mixing, node_a, node_b }
        else
            { nil, nil, nil, nil }
        end
    end





    defp open_file(file) do
        path = "#{@root_folder}/#{file}"
        File.open!(path, [:write, :utf8])
    end

    defp build_csv_row(data, fields) do
        Enum.map fields, fn field -> Map.get(data, field, "") end
    end

    # defp get_session_name() do
    #     network_name = Enum.reduce Networks.list_networks(:db), nil, fn n, _ ->
    #         n.name
    #     end
    #     Regex.replace(~r/_network.*$/, network_name, "")
    # end


    # #############################
    #             OLD
    # #############################

    def export_network_states() do
        file = open_file("network_states.csv")
        # create a network map
        networks = Enum.reduce Networks.list_networks(:db), %{}, fn n, acc ->
            Map.put(acc, n.id, n)
        end
        states = NetworkStates.list_network_states()

        dataset = Enum.reduce states, [], fn state, record ->
            network = networks[state.network_id]
            size = Enum.count(network.edge_map)
            all_nodes = Enum.map 1..size, &("#{&1}")
            srs = Enum.reduce all_nodes, [], fn node, sub_record ->
                r = []
                r = r ++ [state.timestamp]             # timestamp
                r = r ++ [network.id]                  # network id
                r = r ++ [state.condition_1]           # condition 1
                r = r ++ [state.condition_2]           # condition 2
                n = case state.status do
                    "warm_up" -> "WU"
                    "phase_1" -> "A"
                    "phase_2" -> "B"
                end
                r = r ++ [n]
                r = r ++ [state.status]                # status
                r = r ++ [state.round]                 # round
                r = r ++ [state.round_sub]             # sub round
                r = r ++ [node]                        # node
                { health, _ } = state.health[node]
                r = r ++ [health]                      # health
                points = case is_integer(state.earned_points[node]) do
                    true -> state.earned_points[node]
                    false -> nil
                end
                r = r ++ [points]   # points
                offerings = Enum.map all_nodes, fn other ->
                    case Enum.member?(state.offerings[node], other) do
                        true -> 1
                        false -> 0
                    end
                end
                r = r ++ offerings                    # offerings
                connections = Enum.map all_nodes, fn other ->
                    case Enum.member?(state.edge_map[node], other) do
                        true -> 1
                        false -> 0
                    end
                end
                r = r ++ connections                  # connections
                nodes = Enum.map all_nodes, fn n ->
                    state.node_mapping[n]
                end
                r = r ++ nodes                        # nodes
                [r | sub_record]
            end
            record ++ srs
        end

        [first_network | _] = Networks.list_networks()
        size = Enum.count(first_network.edge_map)

        headers = ["timestamp", "network_id", "condition_1", "condition_2",
            "network", "status", "round", "round-sub", "node", "health",
            "points"] ++ Enum.map(1..size, &("off_#{&1}")) ++
            Enum.map(1..size, &("rel_#{&1}")) ++
            Enum.map(1..size, &("node_#{&1}"))

        Repo.transaction(fn ->
            [headers]
            |> Stream.concat(Stream.map(dataset, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)

        :ok
    end

    def export_requests() do
        file = open_file("requests.csv")

        headers = ["timestamp", "network_id", "status", "round", "type",
            "sending_node", "receiving_node", "accepted"]

        dataset = Enum.map Nidm.FriendshipRequests.list_friendship_requests(), fn r ->
            [
                r.timestamp,
                r.network_id,
                r.network_status,
                r.round,
                r.type,
                r.sending_node,
                r.receiving_node,
                r.accepted
            ]
        end

        Repo.transaction(fn ->
            [headers]
            |> Stream.concat(Stream.map(dataset, &(&1)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)

        :ok
    end


    def export_users(columns \\ :all) do
        file = open_file("users.csv")

        columns = case columns do
            :all -> User.__schema__(:fields)
            _ -> columns
        end



        Repo.transaction(fn ->
            [columns]
            |> Stream.concat(Stream.map(Users.list_subjects(:db), &(&1)) |> Stream.map(&build_csv_row(&1, columns)))
            |> CSV.encode()
            |> Enum.each(&IO.write(file, &1))
        end)
        # return path
        :ok
    end

end
