defmodule Nidm.Repo.Migrations.AddNodeAndNeighboursToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :node_id, :string
      add :neighbours, { :array, :string }	
    end
  end
end
