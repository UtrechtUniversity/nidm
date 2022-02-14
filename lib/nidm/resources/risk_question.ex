defmodule Nidm.Resources.RiskQuestion do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, Ecto.UUID, autogenerate: true}

    schema "risk_questions" do
        field :user_id, :binary_id
        field :question_1, :string
        field :question_2, :string
        field :question_3, :string
        field :question_4, :string
        field :question_5, :string

        timestamps()
    end

    def risk_changeset(questions, params \\ %{}) do
        questions
        |> cast(params, [:question_1, :question_2, :question_3, :question_4, :question_5])
        |> validate_inclusion(:question_1, ["A", "B"])
        |> validate_inclusion(:question_2, ["A", "B"])
        |> validate_inclusion(:question_3, ["A", "B"])
        |> validate_inclusion(:question_4, ["A", "B"])
        |> validate_inclusion(:question_5, ["A", "B"])
    end

end