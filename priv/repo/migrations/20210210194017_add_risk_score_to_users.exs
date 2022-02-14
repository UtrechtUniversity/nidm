defmodule Nidm.Repo.Migrations.AddRiskScoreToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :risk_score, :integer
    end
  end
end
