defmodule NidmWeb.WaitLive do
  use NidmWeb, :live_view

  alias Nidm.Users
  alias Nidm.GenServers.{ Gate, Cache }

  require Logger

    def mount(_params, session, socket) do
        # get user_id from session
        %{ "user_id" => user_id } = session
        # get user
        user = Users.get_user(user_id)
        # make sure the status is correct
        user = case user.status do
            "final_instructions" ->
                Users.set_status(user, "waiting")
            _ -> user
        end

        # add this user to the queue
        case user.status == "waiting" do
            true -> Gate.add_user(user)
            false -> :ok
        end

        # get the state of the queue
        %{ queue_filled: queue_filled } = Gate.get_state()
        case connected?(socket) do
            true ->
                # subscribe to the wait channel
                Phoenix.PubSub.subscribe(Nidm.PubSub, "wait")
                # also subscribe to the user channel
                Phoenix.PubSub.subscribe(Nidm.PubSub, "user:#{ user_id }")
                # start a polling timer
                :timer.send_interval(3_000, self(), :pulse)
            false ->
                :nothing
        end
        # assign queue state to the socket and the user_id
        socket = socket
        |> assign(queue_filled: queue_filled)
        |> assign(user_id: user_id)

        # redirect user immediately if the status is -game-
        socket = case user.status do
            "game" -> redirect_to_pause(socket)
            "flushed" -> redirect_to_exit(socket)
            "exit" -> redirect_to_exit(socket)
            _ -> socket
        end

        { :ok, socket, layout: { NidmWeb.LayoutView, "live-wide.html" } }
    end


    def handle_info(:pulse, socket) do
        user = Cache.get(:users, socket.assigns.user_id, false)
        socket = case user do
            false -> socket
            _ ->
                case user.status do
                    "game" -> redirect_to_pause(socket)
                    "flushed" -> redirect_to_exit(socket)
                    _ -> socket
                end
        end
        { :noreply, socket }
    end


    # Call with
    # Phoenix.PubSub.broadcast Nidm.PubSub, "wait", { :progress, %{ queue_filled: 12.5 }}
    def handle_info({ :progress, %{ queue_filled: queue_filled } }, socket) do
        socket = socket
        |> assign(queue_filled: queue_filled)
        # how do I get info from conn into
        {:noreply, socket }
    end


    def handle_info(:start_game, socket) do
        # redirect
        {:noreply, redirect_to_pause(socket) }
    end


    defp redirect_to_pause(socket) do
        redirect(socket, to: "/pause")
    end


    defp redirect_to_game(socket) do
        redirect(socket, to: "/task2")
    end


    defp redirect_to_exit(socket) do
        redirect(socket, to: "/exit")
    end

end
