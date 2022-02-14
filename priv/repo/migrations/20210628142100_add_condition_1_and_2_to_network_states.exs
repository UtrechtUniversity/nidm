defmodule Nidm.Repo.Migrations.AddCondition1And2ToNetworkStates do
  use Ecto.Migration

  def change do
    alter table(:network_states) do
        add :condition_1, :string
        add :condition_2, :string
    end
  end
end
