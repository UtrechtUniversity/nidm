defmodule Nidm.Users do

    alias Nidm.Repo
    alias Nidm.Resources.User
    alias Nidm.GenServers.Cache
    alias Nidm.GenServers.DatabaseQueue

    import Ecto.Changeset
    import Ecto.Query, only: [from: 2, order_by: 2]

    def create(user) do
        # store in cache_token
        Cache.set(:users, user.id, user)
        # store async in database
        DatabaseQueue.add(
            %{ action: "insert", id: user.id, resource: user }
        )
        # return inserted user
        user
    end

    # returns a changeset if validation
    def update(%User{} = user, changeset) do
        case changeset.valid? do
            false ->
                # make sure the action is set so the form will pick up the errors for
                # the error tags
                %{ changeset | action: :update}
            true ->
                updated_user = apply_changes(changeset)
                # store in cache
                Cache.set(:users, user.id, updated_user)
                # store async in database
                DatabaseQueue.add(
                    %{ action: "update", id: user.id, resource: changeset }
                )
                # return updated user
                updated_user
        end
    end

    def get_user(id, store \\ :cache) do
        case store do
            :cache ->
                Cache.get(:users, id, nil)
            :db ->
                Repo.get(User, id)
        end
    end

    def list_users(store \\ :cache) do
        case store do
            :cache ->
                Cache.list_values(:users)
            :db ->
                User
                |> order_by(asc: :serial_number)
                |> Repo.all()
        end
    end

    def list_subjects(store \\ :cache) do
        case store do
            :cache ->
                Enum.sort(
                    Cache.select_by_attribute(:users, :role, "subject"),
                    &(&1.serial_number <= &2.serial_number)
                )
            :db ->
                query = from(User, where: [role: "subject"], order_by: [asc: :serial_number])
                Repo.all(query)
        end
    end

    def list_busy_subjects(store \\ :cache) do
        case store do
            :cache ->
                Enum.filter Cache.list_values(:users), fn u ->
                    u.role == "subject" and not(Enum.member?(["", nil], u.status))
                end
            :db ->
                Repo.all(from u in User, order_by: u.id,
                where: u.role == "subject",
                where: not(is_nil(u.status))
            )
        end
    end

    def flush_users(ids) do
        ids
        |> Enum.map(&get_user(&1))
        |> Enum.each(&set_status(&1, "flushed"))
    end

    def set_status(user, status) do
        changeset = User.status_changeset(user, %{ status: status })
        update(user, changeset)
    end

    def set_earned_points(user, points, add_to_total \\ true) do
        total = case add_to_total do
            true -> user.earned_points + points
            false -> user.earned_points
        end

        changeset = User.round_changeset(user, %{
            prev_earned_points: points,
            earned_points: total
        })
        update(user, changeset)
    end

    def set_risk_score(user, score) do
        changeset = User.risk_score_changeset(user, %{
            risk_score: score,
            risk_money: user.earned_points,
            status: "final_instructions",
            earned_points: round(user.earned_points / 5)
        })
        update(user, changeset)
    end

    def set_network(user, network_id, node_id) do
        changeset = User.network_changeset(user, %{
            network_id: network_id,
            node_id: node_id,
            status: "game"
        })
        update(user, changeset)
    end

    def get_user_by_access_token(token) do
        token = if token == nil, do: "", else: token
        Repo.get_by(User, access_token: token)
    end

    def get_user_by_prolific_pid(pid) do
        pid = if pid == nil, do: "", else: pid
        Repo.get_by(User, prolific_pid: pid)
    end

end
