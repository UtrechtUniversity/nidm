defmodule Nidm.Repo.Migrations.AddNetworkProperties do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :status, :string, default: "available"
      add :started_at, :naive_datetime
      add :finished_at, :naive_datetime
    end
  end
end
