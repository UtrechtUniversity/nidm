defmodule NidmWeb.ExitController do
    use NidmWeb, :controller

    alias Nidm.Users
    alias Nidm.Resources.ExitQuestion
    alias Nidm.ExitQuestions

    plug :logged_in_user when action in [:index]
    plug :put_root_layout, "root_no_header.html"
    plug :put_layout, "regular.html"

    def action(conn, _) do
        user_id = Map.get(conn.assigns, :user_id, nil)
        apply(__MODULE__, action_name(conn),
            [conn, conn.params, Users.get_user(user_id)])
    end

    def unknown_user(conn, _params, current_user) do
        render conn, :unknown, %{ user: current_user }
    end

    def prolific(conn, _params, current_user) do
        old_status = current_user.status
        current_user = Users.set_status(current_user, "exit")
        render(conn, :prolific, %{ user: current_user, old_status: old_status })
    end

    def index(conn, _params, current_user) do
        case current_user.status == "flushed" do
            true ->
                redirect(conn, to: "/exit/#{current_user.id}/prolific")
            false ->
                questions = ExitQuestions.get_by_user_id(current_user.id)
                questions = case questions == nil do
                    true ->
                        { :ok, questions } = ExitQuestions.create_exit_question(%{ user_id: current_user.id })
                        questions
                    false -> questions
                end
                changeset = ExitQuestion.exit_question_changeset(questions, %{})
                render(conn, :index, %{
                    user: current_user,
                    changeset: changeset,
                    questions: questions
                })
        end
    end

    def update(conn, %{ "id" => id, "exit_question" => params }, current_user) do
        question = ExitQuestions.get_exit_question(id)

        question
        |> ExitQuestion.exit_question_changeset(params)
        |> Nidm.Repo.update()
        |> case do
            { :ok, _ } ->
                redirect(conn, to: "/exit/#{current_user.id}/prolific")
            { :error, %Ecto.Changeset{} = changeset } ->
                render(conn, "index.html", %{
                    user: current_user,
                    changeset: changeset,
                    questions: question
                })
        end

    end



end
