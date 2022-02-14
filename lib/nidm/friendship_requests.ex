defmodule Nidm.FriendshipRequests do
    alias Nidm.Repo
    alias Nidm.Resources.FriendshipRequest
    alias Nidm.GenServers.DatabaseQueue
    alias Nidm.GenServers.Cache

    import Ecto.Query, only: [order_by: 2]

    def insert(request) do
        # insert into cache
        Cache.set(:friendship_requests, request.id, request)
        # insert into postgres database
        DatabaseQueue.add(%{
            action: "insert",
            id: request.id,
            resource: request
        })
    end

    def insert(requests, request) do
        %FriendshipRequest{ receiving_node: receiving_node, sending_node: sending_node } = request
        all_received = Map.get(requests, receiving_node, %{})
        all_received = Map.put(all_received, sending_node, request)
        Map.put(requests, receiving_node, all_received)
    end

    def update(requests, request) do
        insert(requests, request)
    end

    def destroy(requests, request) do
        %FriendshipRequest{ receiving_node: receiving_node, sending_node: sending_node } = request
        all_received = Map.get(requests, receiving_node, %{})
        all_received = case Map.has_key?(all_received, sending_node) do
            true -> Map.delete(all_received, sending_node)
            false -> all_received
        end
        Map.put(requests, receiving_node, all_received)
    end

    def get(requests, receiver, sender, default \\ %{}) do
        all_received = Map.get(requests, receiver, %{})
        Map.get(all_received, sender, default)
    end

    def list_friendship_requests(store \\ :cache) do
        case store do
            :cache ->
                Cache.list_values(:friendship_requests)
            :db ->
                FriendshipRequest
                |> order_by(asc: :timestamp)
                |> Repo.all()
        end
    end

end
