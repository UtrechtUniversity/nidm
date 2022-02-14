defmodule Nidm.Resources.ExitQuestion do
    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    @primary_key {:id, Ecto.UUID, autogenerate: true}

    schema "exit_questions" do
        field :user_id, :binary_id
        field :q_age, :integer
        field :q_gender, :integer
        field :q_mtongue, :integer
        field :q_edu, :integer
        field :q_residence, :integer
        field :q_c19_concern, :integer
        field :q_c19_positive, :integer
        field :q_remarks, :string

        timestamps()
    end

    def exit_question_changeset(questions, params) do
        fields = [:user_id, :q_age, :q_gender, :q_mtongue, :q_edu,
            :q_residence, :q_c19_concern, :q_c19_positive, :q_remarks]
        questions
        |> cast(params, fields)
    end

end
