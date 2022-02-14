defmodule Nidm.GenServers.ImportData do
    use GenServer

    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, nil, opts)
    end


    def init(_) do
        # fill caches
        fill_caches()
        # return
        {:ok, :ok}
    end


    def fill_caches() do

        # USERS
        for user <- Nidm.Users.list_users(:db) do
            Nidm.GenServers.Cache.set(:users, user.id, user)
        end

        # RISK_QUESTIONS
        for question <- Nidm.RiskQuestions.list_questions(:db) do
            Nidm.GenServers.Cache.set(:risk_questions, question.user_id, question)
        end

        # NETWORK_STATES
        for state <- Nidm.NetworkStates.list_network_states(:db) do
            Nidm.GenServers.Cache.set(:network_states, state.id, state)
        end

        # FRIENDSHIP REQUESTS
        for request <- Nidm.FriendshipRequests.list_friendship_requests(:db) do
            Nidm.GenServers.Cache.set(:friendship_requests, request.id, request)
        end

        # NETWORKS
        for network <- Nidm.Networks.list_networks(:db) do
            # at this stage the dynamic networksupervisor exists
            # per network create a network_monitor genserver
            # the pid is the network id
            spec = { Nidm.GenServers.NetworkMonitor, network: network }
            Nidm.GenServers.NetworkSupervisor.start_child(spec)
        end

        # RESET THE GATE
        Nidm.GenServers.Gate.reset


    end

end
