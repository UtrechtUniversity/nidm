defmodule Nidm.RiskQuestions do

    alias Nidm.Repo
    alias Nidm.Resources.RiskQuestion
    alias Nidm.GenServers.Cache
    alias Nidm.GenServers.DatabaseQueue

    import Ecto.Changeset
    import Ecto.Query, only: [order_by: 2]

    require Logger

    def create(question) do
        # store in cache_token
        Cache.set(:risk_questions, question.user_id, question)
        # store async in database
        DatabaseQueue.add(
            %{ action: "insert", id: question.id, resource: question }
        )
        # return inserted question record
        question
    end

    # returns a changeset if validation
    def update(%RiskQuestion{} = question, changeset) do
        case changeset.valid? do
            false ->
                # make sure the action is set so the form will pick up the errors for
                # the error tags
                %{ changeset | action: :update}
            true ->
                updated_question = apply_changes(changeset)
                # store in cache
                Cache.set(:risk_questions, question.user_id, updated_question)
                # store async in database
                DatabaseQueue.add(
                    %{ action: "update", id: question.user_id, resource: changeset }
                )
                # return updated user
                updated_question
        end
    end

    def get_question_by_user(id, store \\ :cache) do
        case store do
            :cache ->
                Cache.get(:risk_questions, id)
            :db ->
                Repo.get_by(RiskQuestion, user_id: id)
        end
    end

    def list_questions(store \\ :cache) do
        case store do
            :cache ->
                Cache.list_values(:risk_questions)
            :db ->
                RiskQuestion
                |> order_by(asc: :inserted_at)
                |> Repo.all()
        end
    end

    # def get_user_by_access_token(token) do
    #     token = if token == nil, do: "", else: token
    #     Repo.get_by(User, access_token: token)
    # end

    def get_option_B(question) do
        answers = {
            question.question_1,
            question.question_2,
            question.question_3,
            question.question_4,
        }
        case answers do
            { nil, nil, nil, nil } -> 160

            { "A", nil, nil, nil } -> 240
            { "B", nil, nil, nil } -> 80

            { "A", "A", nil, nil } -> 280
            { "A", "B", nil, nil } -> 200

            { "B", "A", nil, nil } -> 120
            { "B", "B", nil, nil } -> 40

            { "A", "A", "A", nil } -> 300
            { "A", "A", "B", nil } -> 260
            { "A", "B", "A", nil } -> 220
            { "A", "B", "B", nil } -> 180

            { "B", "A", "A", nil } -> 140
            { "B", "A", "B", nil } -> 100
            { "B", "B", "A", nil } -> 60
            { "B", "B", "B", nil } -> 20

            { "A", "A", "A", "A" } -> 310
            { "A", "A", "A", "B" } -> 290
            { "A", "A", "B", "A" } -> 270
            { "A", "A", "B", "B" } -> 250
            { "A", "B", "A", "A" } -> 230
            { "A", "B", "A", "B" } -> 210
            { "A", "B", "B", "A" } -> 190
            { "A", "B", "B", "B" } -> 170

            { "B", "A", "A", "A" } -> 150
            { "B", "A", "A", "B" } -> 130
            { "B", "A", "B", "A" } -> 110
            { "B", "A", "B", "B" } -> 90
            { "B", "B", "A", "A" } -> 70
            { "B", "B", "A", "B" } -> 50
            { "B", "B", "B", "A" } -> 30
            { "B", "B", "B", "B" } -> 10
        end
    end

    def risk_taking_score(question) do
        answers = {
            question.question_1,
            question.question_2,
            question.question_3,
            question.question_4,
            question.question_5
        }
        case answers do
            { "A", "A", "A", "A", "A" } -> 32
            { "A", "A", "A", "A", "B" } -> 31
            { "A", "A", "A", "B", "A" } -> 30
            { "A", "A", "A", "B", "B" } -> 29
            { "A", "A", "B", "A", "A" } -> 28
            { "A", "A", "B", "A", "B" } -> 27
            { "A", "A", "B", "B", "A" } -> 26
            { "A", "A", "B", "B", "B" } -> 25
            { "A", "B", "A", "A", "A" } -> 24
            { "A", "B", "A", "A", "B" } -> 23
            { "A", "B", "A", "B", "A" } -> 22
            { "A", "B", "A", "B", "B" } -> 21
            { "A", "B", "B", "A", "A" } -> 20
            { "A", "B", "B", "A", "B" } -> 19
            { "A", "B", "B", "B", "A" } -> 18
            { "A", "B", "B", "B", "B" } -> 17

            { "B", "A", "A", "A", "A" } -> 16
            { "B", "A", "A", "A", "B" } -> 15
            { "B", "A", "A", "B", "A" } -> 14
            { "B", "A", "A", "B", "B" } -> 13
            { "B", "A", "B", "A", "A" } -> 12
            { "B", "A", "B", "A", "B" } -> 11
            { "B", "A", "B", "B", "A" } -> 10
            { "B", "A", "B", "B", "B" } -> 9
            { "B", "B", "A", "A", "A" } -> 8
            { "B", "B", "A", "A", "B" } -> 7
            { "B", "B", "A", "B", "A" } -> 6
            { "B", "B", "A", "B", "B" } -> 5
            { "B", "B", "B", "A", "A" } -> 4
            { "B", "B", "B", "A", "B" } -> 3
            { "B", "B", "B", "B", "A" } -> 2
            { "B", "B", "B", "B", "B" } -> 1
        end
    end

    def get_column(question) do
        l = [
            { question.question_1, "question_1" },
            { question.question_2, "question_2" },
            { question.question_3, "question_3" },
            { question.question_4, "question_4" },
            { question.question_5, "question_5" },
        ]
        { _, result } = Enum.at(Enum.sort(l), 0)
        result
    end

    def completed?(question) do
        answers = [
            question.question_1 != nil,
            question.question_2 != nil,
            question.question_3 != nil,
            question.question_4 != nil,
            question.question_5 != nil
        ]
        Enum.all?(answers)
    end

end
