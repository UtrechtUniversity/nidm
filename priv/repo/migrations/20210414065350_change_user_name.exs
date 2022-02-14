defmodule Nidm.Repo.Migrations.ChangeUserName do
  use Ecto.Migration

  def up do
    alter table("users") do
        remove :username
        add :serial_number, :integer
    end
  end

  def down do
    alter table("users") do
        add :username, :string
        remove :serial_number
    end
  end

end
