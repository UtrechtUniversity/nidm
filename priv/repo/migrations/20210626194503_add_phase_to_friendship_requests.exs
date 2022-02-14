defmodule Nidm.Repo.Migrations.AddPhaseToFriendshipRequests do
  use Ecto.Migration

  def change do
    alter table(:friendship_requests) do
        add :network_status, :string
    end
  end
end
