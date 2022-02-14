defmodule Nidm.Repo.Migrations.AddPropertiesToNetwork do
    use Ecto.Migration

    def change do
        alter table("networks") do
            add :node_properties, :map
            add :introductions, :map
        end
    end
end
