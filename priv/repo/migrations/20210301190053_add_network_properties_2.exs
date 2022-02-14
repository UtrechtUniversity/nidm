defmodule Nidm.Repo.Migrations.AddNetworkProperties2 do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :condition_1, :string
      add :condition_2, :string
      add :from_queue, :string, default: nil
    end
  end
end
