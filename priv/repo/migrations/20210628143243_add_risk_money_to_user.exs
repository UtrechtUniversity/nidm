defmodule Nidm.Repo.Migrations.AddRiskMoneyToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
        add :risk_money, :integer
    end
  end
end
