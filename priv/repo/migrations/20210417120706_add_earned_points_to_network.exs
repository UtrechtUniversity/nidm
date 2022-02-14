defmodule Nidm.Repo.Migrations.AddEarnedPointsToNetwork do
  use Ecto.Migration

  def change do
    alter table("networks") do
        add :earned_points, :map
      end

    alter table("network_states") do
        add :earned_points, :map
    end
  end

end
