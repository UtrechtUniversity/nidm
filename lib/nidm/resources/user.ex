defmodule Nidm.Resources.User do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, Ecto.UUID, autogenerate: true}

    schema "users" do
        field :serial_number, :integer
        field :role, :string
        field :prolific_pid, :string
        field :session_id, :string
        field :access_token, :string
        field :exit_token, :string
        field :status, :string
        field :agreed_personal_data, :boolean
        field :agreed_terms, :boolean
        field :risk_score, :integer
        field :risk_money, :integer
        field :network_id, :binary_id
        field :node_id, :string
        field :earned_points, :integer, default: 0
        field :prev_earned_points, :integer
        field :redirect_url, :string
        field :fee, :float, default: 0.0

        timestamps()
    end

    def signin_changeset(user, params \\ %{}) do
        user
        |> cast(params, [:agreed_terms, :agreed_personal_data, :status])
        |> validate_acceptance(:agreed_terms, message: "Please agree to our terms of service.")
        |> validate_acceptance(:agreed_personal_data, message: "Please agree to our terms of data processing.")
    end

    def status_changeset(user, params) do
        user
        |> cast(params, [:status])
    end

    def round_changeset(user, params) do
        user
        |> cast(params, [:prev_earned_points, :earned_points])
    end

    def risk_score_changeset(user, params) do
        user
        |> cast(params, [:risk_score, :risk_money, :status, :earned_points])
    end

    def network_changeset(user, params) do
        user
        |> cast(params, [:network_id, :node_id, :status])
    end

end
