defmodule Nidm.Repo.Migrations.AddEarnedPoints do
  use Ecto.Migration

  def change do
    alter table("users") do
       add :earned_points, :float, default: 0
    end
  end
end
