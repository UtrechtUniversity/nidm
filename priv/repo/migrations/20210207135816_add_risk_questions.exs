defmodule Nidm.Repo.Migrations.AddRiskQuestions do
  use Ecto.Migration

  def change do
    create table(:risk_questions) do
      add :user_id, :uuid
      add :question_1, :string
      add :question_2, :string
      add :question_3, :string
      add :question_4, :string
      add :question_5, :string

      timestamps()
    end

  end
end
