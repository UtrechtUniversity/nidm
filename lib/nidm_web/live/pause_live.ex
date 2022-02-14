defmodule NidmWeb.PauseLive do
    use NidmWeb, :live_view

    alias Nidm.{ Users, Networks }
    alias Nidm.GenServers.Cache

    require Logger

    def mount(_params, session, socket) do
        # get user_id from session
        %{ "user_id" => user_id } = session
        # get user and network
        user = Users.get_user(user_id)
        network = Networks.get_network(user.network_id)

        case connected?(socket) do
            true ->
                # subscribe to the network channel
                Phoenix.PubSub.subscribe(Nidm.PubSub, "network:#{ user.network_id }")
                # start a polling timer
                pause_duration  = Application.get_env(:nidm, :pause_duration, 5_000)
                :timer.send_interval(pause_duration + 2_000, self(), :pulse)
            false ->
                :nothing
        end
        # assign queue state to the socket and the user_id
        socket = assign(socket,
            user_id: user_id,
            status: network.status,
            condition: network.condition_1
        )

        # redirect user immediately if the status is -game-
        socket = case user.status do
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
                    "game" -> redirect_to_game(socket)
                    "flushed" -> redirect_to_exit(socket)
                    "exit" -> redirect_to_exit(socket)
                    _ -> socket
                end
        end
        { :noreply, socket }
    end

    def handle_info({ _, _}, socket) do
        # redirect
        {:noreply, redirect_to_game(socket) }
    end


    def handle_info(:to_game, socket) do
        # redirect
        {:noreply, redirect_to_game(socket) }
    end


    defp redirect_to_game(socket) do
        redirect(socket, to: "/task2")
    end

    defp redirect_to_exit(socket) do
        redirect(socket, to: "/exit")
    end

end
