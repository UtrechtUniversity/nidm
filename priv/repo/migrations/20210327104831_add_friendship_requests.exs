defmodule Nidm.Repo.Migrations.AddFriendshipRequests do
  use Ecto.Migration

  def change do
    create table(:friendship_requests) do
        add :type, :string
        add :sender_id, :uuid
        add :receiver_id, :uuid
        add :network_id, :uuid
        add :sending_node, :string
        add :receiving_node, :string
        add :mutual, :boolean
        add :timestamp, :integer
        add :accepted, :boolean

        timestamps()
      end
  end
end
