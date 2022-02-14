defmodule Nidm.Repo.Migrations.ChangeEdgeMapping do
  use Ecto.Migration

  def change do
    rename table(:networks), :edge_mapping, to: :edge_map
  end
end
