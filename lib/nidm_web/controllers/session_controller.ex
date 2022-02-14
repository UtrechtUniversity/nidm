defmodule NidmWeb.SessionController do

    use NidmWeb, :controller

    alias Nidm.{ Users, Networks }
    alias Nidm.Resources.User

    require Logger

    plug :put_root_layout, "root_no_header.html"
    plug :put_layout, "regular.html"
    plug :redirect_if_necessary

    def new(conn, params) do
        # make sure params keys are downcased
        params = Enum.reduce params, %{}, fn { key, value }, acc ->
            Map.put(acc, String.downcase(key), value)
        end
        # search user by prolific_pid
        user = case Enum.member?(Map.keys(params), "prolific_pid") do
            true -> Users.get_user_by_prolific_pid(params["prolific_pid"])
            false -> Users.get_user_by_access_token(params["access_token"])
        end

        # check if we have a user found by access token, if not redirect to unknown user
        case user do
            %User{} ->
                # does it make sense to let this guy follow through, are
                # there any available networks?
                signin_changeset = User.signin_changeset(user)
                # render welcome page
                render conn, :new, %{ user: user, signin_changeset: signin_changeset }
            _ ->
                conn
                |> put_flash(:error, "The provided access token is not associated with a user account")
                |> redirect(to: "/unknown_user")
        end
    end


    def create(conn, %{ "user" => params }) do
        # get id
        %{ "id" => id } = params
        # get user
        user = Users.get_user(id)
        # if there is a user continue to task_1, otherwise exit
        case user do
            %User{} ->
                status = infer_user_status(user)
                # update status
                params = Map.put(params, "status", status)
                # create changeset
                signin_changeset = User.signin_changeset(user, params)
                # update User
                updated_user = Users.update(user, signin_changeset)
                # if a changeset is returned, then something is wrong
                case updated_user do
                    %Ecto.Changeset{} ->
                        conn
                        |> put_flash(:error, "Please agree to our terms of service.")
                        |> render(:new, %{ user: user, signin_changeset: updated_user })
                    _ ->
                        redirect_path = case updated_user.status do
                            "signed_in" -> "/task1"
                            "assessment" -> "/task1"
                            "flushed" -> "/exit"
                            "exit_questions" -> "/exit"
                            "exit" -> "/exit"
                            "waiting" -> "/wait"
                            "game" -> "/task2"
                            "question_1" -> "/task1"
                            "question_2" -> "/task1"
                            "question_3" -> "/task1"
                            "question_4" -> "/task1"
                            "question_5" -> "/task1"
                            "final_instructions" -> "/final_instructions"
                        end
                        conn
                        |> login(updated_user)
                        |> redirect(to: redirect_path)
                end
            _ ->
                conn
                |> put_flash(:error, "The ID of the user account could not be found")
                |> redirect(to: "/unknown_user")
        end
    end


    defp infer_user_status(user) do
        case user.status == nil do
            true ->
                # no status
                available_networks = Networks.available_networks()
                case Enum.empty?(available_networks) do
                    true -> "flushed"
                    false -> "signed_in"
                end
            false ->
                # keep status
                user.status
        end
    end


    defp redirect_if_necessary(conn, _params) do
        # if logged in redirect
        conn
    end


    defp login(conn, user) do
        conn = conn
        |> put_session(:user_id, user.id)
        conn
    end



end
