defmodule Nidm.Repo.Migrations.AddRoundToFriendshipRequest do
  use Ecto.Migration

  def change do
    alter table("friendship_requests") do
        add :round, :integer
    end
  end
end
