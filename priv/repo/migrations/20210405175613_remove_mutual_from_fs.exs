defmodule Nidm.Repo.Migrations.RemoveMutualFromFs do
  use Ecto.Migration

  def up do
    alter table("friendship_requests") do
        remove :mutual
    end
  end

  def down do
    alter table("friendship_requests") do
        add :mutual, :boolean
    end
  end

end
