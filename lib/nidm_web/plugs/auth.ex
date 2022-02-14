defmodule Nidm.Auth do

    import Plug.Conn
    import Phoenix.Controller

    alias Nidm.Users

    require Logger

    # init
    def init(opts), do: opts

    #
    def call(conn, _opts) do
        id = get_session(conn, :user_id)
        user = id && Users.get_user(id)
        # is this an admin or a participant
        put_current_user(conn, user)
    end

    # if you -are- logged in, this function just passes the conn
    def logged_in_user(conn = %{assigns: %{ user_id: _}}, _), do: conn

    # if you are -not- logged in, this function will redirect you
    def logged_in_user(conn, _opts) do
        conn
        |> put_flash(:error, "You must be logged in to access the requested page")
        |> redirect(to: "/unknown_user")
        |> halt()
    end

    def logged_in?(%{assigns: assigns} = _conn) do
        Map.has_key?(assigns, :current_user_id) && is_integer(Map.get(assigns, :current_user_id))
    end

    # if you -are- an admin user, this function just passes the conn
    def admin_user(conn = %{assigns: %{ admin_user: true }}, _), do: conn

    # if you are -not- an admin user, this function will redirect you
    def admin_user(conn, _opts) do
        conn
        |> put_flash(:error, "You must be an admin to access the requested page")
        |> redirect(to: "/subject_removed")
        |> halt()
    end

    def is_admin?(%{assigns: assigns} = conn) do
        logged_in?(conn) && Map.has_key?(assigns, :admin_user) && Map.get(assigns, :admin_user, false)
   end

    # set current_user, and admin_user
    defp put_current_user(conn, user) do
        if user do
            # returns false if user does not exist
            token = user && Phoenix.Token.sign(
                conn,
                NidmWeb.Endpoint.config(:secret_key_base),
                user.id)

            conn
            |> assign(:user_id, user.id)
            |> assign(:status, user.status)
            |> assign(:user_token, token)
        else
            conn
        end
    end


end
