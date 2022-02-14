defmodule NidmWeb.RiskController do

    use NidmWeb, :controller

    alias Nidm.Users
    alias Nidm.Resources.{ RiskQuestion, InstructionQuestion }
    alias Nidm.{ RiskQuestions, Networks }

    require Logger

    # This is a plug!!! See nidm_web > plugs > auth.ex
    # The plug is registered in routes.ex and nidm_web.ex
    # stuff from session is written in assigns, for every page
    # that I load and uses this plug in the controller.
    plug :logged_in_user
    plug :put_root_layout, "root_no_header.html"
    plug :put_layout, "regular.html"


    def action(conn, _) do
        apply(__MODULE__, action_name(conn),
            [conn, conn.params, Users.get_user(conn.assigns.user_id)])
    end


    def index(conn, _params, current_user) do
        # set status of user
        current_user = Users.set_status(current_user, "assessment")
        # get the record for the risk questions of this user (for the id)
        questions = RiskQuestions.get_question_by_user(current_user.id)
        # render
        render conn, :index, %{ id: questions.id }
    end


    def edit(conn, _params, current_user) do
        # get the answer record for this user
        question = RiskQuestions.get_question_by_user(current_user.id)
        # what column are we talking about
        column = RiskQuestions.get_column(question)
        # get the value for option B
        option_b = RiskQuestions.get_option_B(question)
        # set the status to the question number
        _current_user = Users.set_status(current_user, column)
        # gimme a changeset for the form
        risk_changeset = RiskQuestion.risk_changeset(question)
        # render
        render conn, :edit, %{
            question: question,
            risk_changeset:
            risk_changeset,
            option_b: option_b,
            column: String.to_atom(column),
            user: current_user        }
    end


    def update(conn, %{ "question" => decision }, current_user) do
        # finding out what the user did and what he/she earns
        earned = if Enum.member?(Map.values(decision), "A") do
            # the bet, draw number
            case :rand.uniform() < 0.5 do
                true -> 300
                false -> 0
            end
        else
            # the cash
            String.to_integer(decision["b_money"])
        end
        # update the user
        current_user = Users.set_earned_points(current_user, earned)

        # gimme the answer record for this user
        question = RiskQuestions.get_question_by_user(current_user.id)
        # get the changeset
        risk_changeset = RiskQuestion.risk_changeset(question, decision)
        # update the record
        updated_question = RiskQuestions.update(question, risk_changeset)

        # what can we do now:
        # no more networks -> flush
        # risk questions completed -> final instructions
        # continue if not completed
        cond do
            Enum.count(Networks.available_networks()) == 0 ->
                Users.set_status(current_user, "flushed")
                redirect(conn, to: "/exit")
            RiskQuestions.completed?(updated_question) == true ->
                # set the risk taking score
                score = RiskQuestions.risk_taking_score(updated_question)
                # set the risk score
                Users.set_risk_score(current_user, score)
                # set risk-taking-profile of user
                redirect(conn, to: "/final_instructions")
            true ->
                # otherwise go to the next question
                redirect(conn, to: "/task1/#{question.id}/edit")
        end

    end

    # this is no regular action and thus
    def final_instructions(conn, params, current_user) do
        answers = case Map.has_key?(params, "answers") do
            true ->
                Enum.reduce params["answers"], %{}, fn {k, v}, acc ->
                    Map.put(acc, String.to_atom(k), v)
                end
            false -> %{}
        end

        changeset = InstructionQuestion.answer_changeset(answers)

        cond do
            # condition for flushed
            Enum.count(Networks.available_networks()) == 0 ->
                Users.set_status(current_user, "flushed")
                redirect(conn, to: "/exit")
            answers == %{} ->
                message = """
                Please read the following instructions carefully and
                answer the questions below.
                """
                conn
                |> put_flash(:info, message)
                |> render(:final_instructions, %{
                    user: current_user,
                    changeset: changeset
                })
            answers != %{} ->
                case changeset.valid? do
                    true ->
                        redirect_to = case current_user.status do
                            "game" -> "/task2"
                            "exit" -> "/exit"
                            "exit_questions" -> "/exit"
                            "flushed" -> "/exit"
                            "waiting" -> "/wait"
                            "final_instructions" -> "/wait"
                        end
                        redirect(conn, to: redirect_to)
                    false ->
                        changeset = %{changeset | action: :insert, errors: changeset.errors}
                        message = """
                        Please make sure you have carefully read and
                        understood the instructions before you continue.
                        In case of questions, please contact the main
                        researcher Hendrik Nunner via the messaging
                        function on Prolific or via email
                        <a href="mailto:h.nunner@uu.nl">h.nunner@uu.nl</a>.
                        """
                        conn
                        |> put_flash(:error, message)
                        |> render(:final_instructions, %{
                            user: current_user,
                            changeset: changeset
                        })
                end
        end
    end

end
