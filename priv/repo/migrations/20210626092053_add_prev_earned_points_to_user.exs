defmodule Nidm.Repo.Migrations.AddPrevEarnedPointsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
        add :prev_earned_points, :float
    end

  end
end
