defmodule Nidm.Repo.Migrations.ChangeInfectionIntoHealth do
  use Ecto.Migration

  def up do
    alter table("networks") do
        remove :infected
        add :health, :map
    end

    alter table("network_states") do
        remove :infected
        add :health, :map
    end
  end

  def down do
    alter table("networks") do
        remove :health
        add :infected, :map
    end

    alter table("network_states") do
        remove :health
        add :infected, :map
    end
  end
end
