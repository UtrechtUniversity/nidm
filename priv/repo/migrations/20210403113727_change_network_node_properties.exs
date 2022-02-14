defmodule Nidm.Repo.Migrations.ChangeNetworkNodeProperties do
  use Ecto.Migration

  def up do
    alter table("networks") do
        remove :node_properties
        add :infected, :map
        add :risk_scores, :map
        add :round, :integer, default: 0
    end
  end

  def down do
    alter table("networks") do
        remove :infected
        remove :risk_scores
        remove :round
        add :node_properties, :map
    end
  end

end
