defmodule Nidm.Repo.Migrations.AddDataToNetworkStates do
  use Ecto.Migration

  def change do
    alter table("network_states") do
        add :edges, :integer, default: 0
        add :connects, :integer, default: 0
        add :disconnects, :integer, default: 0
        add :infected, :integer, default: 0
        add :status, :string
    end

  end
end
