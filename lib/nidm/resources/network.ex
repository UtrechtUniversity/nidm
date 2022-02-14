defmodule Nidm.Resources.Network do
    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    @primary_key {:id, Ecto.UUID, autogenerate: true}

    schema "networks" do
        field :name, :string
        field :condition_1, Ecto.Atom
        field :condition_2, Ecto.Atom
        field :gamma, :float
        field :from_queue, :string
        field :status, :string

        field :node_mapping, :map
        field :edge_map, SetMap

        field :risk_scores, :map
        field :health, HealthMap
        field :earned_points, :map
        field :offerings, SetMap

        field :round, :integer, default: 0
        field :started_at, :naive_datetime
        field :finished_at, :naive_datetime

        timestamps()
    end

    def status_changeset(network, params) do
        network
        |> cast(params, [:status])
    end

    def round_changeset(network, params) do
        network
        |> cast(params, [:condition_1, :status, :edge_map, :health, :offerings,
            :round, :earned_points, :risk_scores, :node_mapping])
    end

    def init_changeset(network, params) do
        network
        |> cast(params, [:status, :gamma, :from_queue, :node_mapping, :risk_scores,
            :health, :offerings])
        |> validate_required([:gamma])
    end

end
