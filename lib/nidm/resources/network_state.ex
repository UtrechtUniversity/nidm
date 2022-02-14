defmodule Nidm.Resources.NetworkState do
    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    @primary_key {:id, Ecto.UUID, autogenerate: true}

    schema "network_states" do
        field :network_id, :binary_id
        field :condition_1, Ecto.Atom
        field :condition_2, Ecto.Atom

        field :node_mapping, :map
        field :edge_map, SetMap
        field :timestamp, :integer

        field :gamma, :float
        field :round, :integer
        field :round_sub, :string
        field :health, HealthMap
        field :earned_points, :map
        field :offerings, SetMap

        field :status, :string
        field :edges, :integer, default: 0
        field :connects, :integer, default: 0
        field :disconnects, :integer, default: 0
        field :infected, :integer, default: 0

        timestamps()
    end

    def network_state_changeset(network_state, params) do
        fields = [:round, :round_sub, :gamma, :network_id, :edge_map, :health,
            :earned_points, :offerings, :timestamp, :edges, :connects,
            :disconnects, :infected, :status, :condition_1, :condition_2,
            :node_mapping
        ]
        network_state
        |> cast(params, fields)
    end

end
