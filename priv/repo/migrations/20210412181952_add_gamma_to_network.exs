defmodule Nidm.Repo.Migrations.AddGammaToNetwork do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :gamma, :float
    end

    alter table("network_states") do
      add :gamma, :float
    end
  end
end
