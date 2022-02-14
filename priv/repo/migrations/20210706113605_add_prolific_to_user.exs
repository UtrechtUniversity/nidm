defmodule Nidm.Repo.Migrations.AddProlificToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
        add :prolific_pid, :string
        add :session_id, :string
    end
  end
end
