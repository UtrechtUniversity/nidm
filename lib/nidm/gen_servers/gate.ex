defmodule Nidm.GenServers.Gate do
    use GenServer

    alias Nidm.Resources.Network
    alias Nidm.GenServers.NetworkMonitor
    alias Nidm.{ Networks, NetworkTools, Users }

    require Logger

    def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(_) do
        {:ok, initial_state() }
    end


    def add_user(user) do
        GenServer.call(__MODULE__, {:add, user})
    end

    def get_state() do
        GenServer.call(__MODULE__, :get_state)
    end


    def set_network_capacity(capacity) do
        GenServer.call(__MODULE__, { :set_network_capacity, capacity })
    end


    def reset() do
        GenServer.call(__MODULE__, :reset)
    end

    def flush() do
        GenServer.call(__MODULE__, :flush)
    end

    def handle_call(:reset, _payload, _) do
        { :reply, :ok, initial_state() }
    end

    def handle_call(:flush, _payload, gate_data) do
        ids = (Enum.reduce gate_data.queues, [], fn { _, q }, acc ->
            acc ++ :queue.to_list(q)
        end) ++ gate_data.unseated
        Users.flush_users(ids)
        { :reply, initial_state(), initial_state() }
    end


    def handle_call(:get_state, _payload, gate_data) do
        additional = %{ queue_filled: percentage_filled(gate_data) }
        response = Map.merge(gate_data, additional)
        { :reply, response, gate_data }
    end

    def handle_call({ :set_network_capacity, capacity }, _payload, gate_data) do
        { :reply, capacity, %{ gate_data | network_capacity: capacity } }
    end


    def handle_call({ :add, user }, _payload, gate_data) do
        gate_data = case user_is_eligible?(user, gate_data) do
            # if user is already connected or waiting, etc
            false ->
                gate_data
            # user is not part of a queue or seat_me arrangement
            true ->
                # seat this person
                unseated = [ user | gate_data.unseated ]

                # alright, do we have enough people to bring to the
                # queues?
                case Enum.count(unseated) < gate_data.queue_count do
                    # not enough people to move to the queues
                    true ->
                        %{ gate_data | unseated: unseated }
                    # there are enough people
                    _ ->
                        # sort unseated people to distribute over queues
                        # override this function if you want a different
                        # distribution
                        unseated = distribution_order(unseated)
                        # get the queues
                        queues = gate_data.queues

                        # add user ids to the queues
                        queues = for { i, queue } <- queues, into: %{}, do: { i, :queue.in(Enum.at(unseated, i).id, queue) }

                        # try to fill the networks
                        queues = for { i, queue } <- queues, into: %{}, do: { i, try_fill_network(queue, i, gate_data.network_capacity) }

                        # update the gate data
                        gate_data = %{ gate_data | unseated: [], queues: queues }

                        # broadcast this data over the wait channel
                        Phoenix.PubSub.broadcast Nidm.PubSub, "wait",
                            { :progress, %{ queue_filled: percentage_filled(gate_data) }}

                        # broadcast this data over the wait channel
                        Phoenix.PubSub.broadcast Nidm.PubSub, "admin",
                            { :gate, gate_data }

                        gate_data
                end
        end

        { :reply, user.id, gate_data }
    end




    defp user_is_eligible?(user, gate_data) do
        # check if user is not waiting in the seat_me list
        # and is not already waiting in a queue
        not_in_unseated = Enum.member?(gate_data.unseated, user) == false
        not_in_queues = Enum.any?( gate_data.queues, fn { _key, queue } -> :queue.member(user.id, queue) end ) == false
        # if both are true then the use is eligible
        not_in_unseated and not_in_queues
    end

    def distribution_order(unseated) do
        Enum.sort unseated, &(&1.risk_score >= &2.risk_score)
    end

    # if this queue has reached critical mass we can split it and assign a network with users
    defp try_fill_network(queue, queue_name, network_capacity) do
        if :queue.len(queue) >= network_capacity do
            { selected, remaining } = :queue.split(network_capacity, queue)
            filled_network = NetworkTools.set_network(:queue.to_list(selected), "#{queue_name}")
            case filled_network do
                # no network was returned, continue with queue
                :no_network -> queue
                # we had enough people to fill a network
                %Network{} ->
                    # start the clock for this network
                    NetworkMonitor.start_clock(filled_network.id)
                    # and return the remaining queue
                    remaining
                _ -> queue
            end
        else
            queue
        end
    end

    defp percentage_filled(data) do
        Float.round((:queue.len(data.queues[0]) / data.network_capacity) * 100, 1)
    end

    defp initial_state() do
        # first try available networks
        networks = Networks.available_networks()
        # and try all networks later
        networks = case Enum.count(networks) do
            0 -> Networks.list_networks()
            _ -> networks
        end
        # and try to get a capacity
        capacity = case Enum.count(networks) do
            0 -> 60
            _ ->
                [n | _] = networks
                Enum.count(Map.keys(n.edge_map))
        end
        # create all necessary queues
        no_queues = Application.get_env(:nidm, :queues, 1)
        queues = for key <- 0..(no_queues - 1), into: %{}, do: { key, :queue.new() }
        %{ unseated: [], queues: queues, queue_count: Enum.count(queues), network_capacity: capacity }
    end

end
