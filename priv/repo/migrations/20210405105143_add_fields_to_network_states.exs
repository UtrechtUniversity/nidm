defmodule Nidm.Repo.Migrations.AddFieldsToNetworkStates do
  use Ecto.Migration

  def change do
    alter table("network_states") do
        add :round, :integer
        add :infected, :map
        add :introductions, :map
    end
  end
end
