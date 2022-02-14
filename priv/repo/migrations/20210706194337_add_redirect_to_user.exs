defmodule Nidm.Repo.Migrations.AddRedirectToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
        add :redirect_url, :string
        add :fee, :float, default: 0.0
    end
  end
end
