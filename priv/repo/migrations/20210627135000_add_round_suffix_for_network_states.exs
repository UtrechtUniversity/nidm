defmodule Nidm.Repo.Migrations.AddRoundSuffixForNetworkStates do
  use Ecto.Migration

  def change do
    alter table(:network_states) do
        add :round_sub, :string
    end
  end
end
