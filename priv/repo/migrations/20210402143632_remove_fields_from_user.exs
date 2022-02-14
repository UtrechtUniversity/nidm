defmodule Nidm.Repo.Migrations.RemoveFieldsFromUser do
  use Ecto.Migration

  def up do
    alter table("users") do
        remove :neighbours
    end
  end

  def down do
    alter table("users") do
        add :neighbours, { :array, :string }
    end
  end

end
