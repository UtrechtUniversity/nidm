defmodule Nidm.Repo.Migrations.AddNetworkIdToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :network_id, :uuid
    end
  end
end
