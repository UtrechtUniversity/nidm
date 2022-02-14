defmodule Nidm.Repo.Migrations.ChangePointsIntoIntegers do
  use Ecto.Migration

  def up do
    alter table(:users) do
        modify :earned_points, :integer
        modify :prev_earned_points, :integer
    end
  end

  def down do
    alter table(:users) do
        modify :earned_points, :float
        modify :prev_earned_points, :float
    end
  end
end
