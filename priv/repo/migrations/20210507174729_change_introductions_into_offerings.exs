defmodule Nidm.Repo.Migrations.ChangeIntroductionsIntoOfferings do
  use Ecto.Migration

  def change do
    rename table("networks"), :introductions, to: :offerings
    rename table("network_states"), :introductions, to: :offerings
  end


end
