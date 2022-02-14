defmodule Nidm.Repo.Migrations.AddNetworkStates do
  use Ecto.Migration

  def change do
    create table(:network_states) do
        add :network_id, :uuid
        add :edge_map, :map
        add :timestamp, :integer
        timestamps()
    end
  end
end
