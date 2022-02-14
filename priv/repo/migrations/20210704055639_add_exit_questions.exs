defmodule Nidm.Repo.Migrations.AddExitQuestions do
  use Ecto.Migration

  def change do
    create table(:exit_questions) do
        add :user_id, :uuid
        add :q_age, :integer
        add :q_gender, :integer
        add :q_mtongue, :integer
        add :q_edu, :integer
        add :q_residence, :integer
        add :q_c19_concern, :integer
        add :q_c19_positive, :integer
        add :q_remarks, :text
        timestamps()
    end
  end
end
