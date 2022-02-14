defmodule Nidm.Repo.Migrations.RemoveUserMappingInNetwork do
  use Ecto.Migration

  def up do
    alter table("networks") do
        remove :user_mapping
    end
  end

  def down do
    alter table("networks") do
        add :user_mapping, :map
    end
  end

end
