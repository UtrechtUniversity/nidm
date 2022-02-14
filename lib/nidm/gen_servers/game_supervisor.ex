defmodule Nidm.GenServers.GameSupervisor do
    use Supervisor

    require Logger

    def start_link(_) do
        # this supervisor is called :genserver_supervisor (see integration tests)
        Supervisor.start_link(__MODULE__, :ok, name: :game_supervisor)
    end

    @impl true
    def init(:ok) do
        # CREATE EXPORT PATH
        :ok = File.mkdir_p!(Application.get_env(:nidm, :export_path))

        children = [
            # start the dynamic supervisor for the networks
            Nidm.GenServers.NetworkSupervisor,

            # the name-argument is the process name, I think the id-argument represents an
            # id in the Supervisor data structure
            Supervisor.child_spec({ Nidm.GenServers.Cache, name: :users }, id: :users),
            Supervisor.child_spec({ Nidm.GenServers.Cache, name: :risk_questions }, id: :risk_questions),
            Supervisor.child_spec({ Nidm.GenServers.Cache, name: :network_states }, id: :network_states),
            Supervisor.child_spec({ Nidm.GenServers.Cache, name: :friendship_requests }, id: :friendship_requests),

            Nidm.GenServers.Gate,
            Nidm.GenServers.DatabaseQueue,
            Nidm.GenServers.ImportData,
        ]

        Supervisor.init(children, strategy: :one_for_one)
    end

end
