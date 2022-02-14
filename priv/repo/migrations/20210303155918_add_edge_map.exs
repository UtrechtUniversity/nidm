defmodule Nidm.Repo.Migrations.AddEdgeMap do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :edge_mapping, :map
    end
  end
end
