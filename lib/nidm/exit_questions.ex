defmodule Nidm.ExitQuestions do
    alias Nidm.Repo
    alias Nidm.Resources.ExitQuestion

    import Ecto.Query, only: [order_by: 2]

    def create_exit_question(attrs \\ %{}) do
        %ExitQuestion{}
        |> ExitQuestion.exit_question_changeset(attrs)
        |> Repo.insert()
    end

    def update_exit_question(%ExitQuestion{} = questions, attrs \\ %{}) do
        questions
        |> ExitQuestion.exit_question_changeset(attrs)
        |> Repo.update()
    end

    def get_exit_question(id) do
        Repo.get(ExitQuestion, id)
    end

    def get_by_user_id(user_id) do
        Repo.get_by(ExitQuestion, user_id: user_id)
    end

    def list_exit_questions() do
        ExitQuestion
        |> order_by(asc: :id)
        |> Repo.all()
    end

end
