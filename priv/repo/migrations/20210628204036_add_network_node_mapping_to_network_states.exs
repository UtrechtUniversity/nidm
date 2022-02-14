defmodule Nidm.Repo.Migrations.AddNetworkNodeMappingToNetworkStates do
  use Ecto.Migration

  def change do
    alter table(:network_states) do
       add :node_mapping, :map
    end
  end
end
