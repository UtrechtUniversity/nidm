defmodule Nidm.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :role, :string, default: "participant"
      add :access_token, :string
      add :exit_token, :string
      add :status, :string, default: nil
      add :agreed_personal_data, :boolean, default: false
      add :agreed_terms, :boolean, default: false

      timestamps()
    end

    create index("users", [:access_token, :role, :status])
  end
end
