defmodule Nidm.Repo.Migrations.AddNetworks do
  use Ecto.Migration

  def change do
    create table(:networks) do
      add :name, :string
      add :user_mapping, :map
      add :node_mapping, :map
      timestamps()
    end

    create index("networks", [:name])
  end
end
