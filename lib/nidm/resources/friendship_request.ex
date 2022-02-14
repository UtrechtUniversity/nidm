defmodule Nidm.Resources.FriendshipRequest do
    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    @primary_key {:id, Ecto.UUID, autogenerate: true}

    schema "friendship_requests" do
        field :round, :integer
        field :type, Ecto.Atom
        field :sender_id, :binary_id
        field :receiver_id, :binary_id
        field :network_id, :binary_id
        field :sending_node, :string
        field :receiving_node, :string
        field :timestamp, :integer
        field :accepted, :boolean
        field :network_status, :string

        timestamps()
    end

    def friendship_request_changeset(request, params) do
        fields = [:round, :type, :sender_id, :receiver_id, :network_id, :sending_node,
            :receiving_node, :timestamp, :accepted, :network_status]
        request
        |> cast(params, fields)
    end

end
