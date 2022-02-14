# This macro helps with testing, I get all kinds of
# error because the database is handled async, causing
# problems with the fact that database use is done after
# the test itself. This code "injects" a different
# version of the add-function depending on the environment.
# see config/test.exs
defmodule AddFunction do
    defmacro __before_compile__(_env) do
        if Application.get_env(:nidm, :test) == true do
            quote do
                def add(item), do: :ok
            end
        else
            quote do
                # add an item to the queue, <item> is a map containing either a
                # database instruction (action), an id and the thing that needs to
                # be done (a struct if it needs inserting, a changeset for an update)
                def add(item) do
                    GenServer.cast(__MODULE__, {:add, item})
                end
            end
        end
    end
end


defmodule Nidm.GenServers.DatabaseQueue do
    # this will get me the add function
    @before_compile AddFunction
    use GenServer

    alias Nidm.Repo
    require Logger

    # tick interval is every 0.01 seconds
    @tick_interval 10
    # pool size of database
    @pool_size Application.get_env(:nidm, Nidm.Repo)[:pool_size] || 25

    def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    # list the queue
    def get_queue() do
        GenServer.call(__MODULE__, :get_queue)
    end

    # reset the queue
    def flush() do
        GenServer.call(__MODULE__, :flush)
    end

    def init(_opts) do
        :timer.send_interval(@tick_interval, :tick)
        # add a queue
        {:ok, :queue.new()}
    end

    # handle adding to queue
    def handle_cast({ :add, item }, queue) do
        # add item to queue
        queue = :queue.in(item, queue)
        # return
        { :noreply, queue }
    end

    def handle_call(:flush, _payload, _queue) do
        { :reply, :ok, :queue.new()}
    end

    def handle_call(:get_queue, _payload, queue) do
        { :reply, :queue.to_list(queue), queue}
    end

    def handle_info(:tick, queue) do
        # how many elements are we going to remove, twice the size of pool_size to
        # make sure the database is pretty busy with handling race-condition-free jobs
        n = Enum.min([2 * @pool_size, :queue.len(queue)])

        # if we have more than 1 element:
        queue = if n > 0 do

            # remove <pool-size> elements in batch
            { batch, new_queue } = :queue.split(n, queue)
            # execute all elements in the batch: loop over queue items and check for potential
            # race conditions. The referee keeps track of what was executed and what needs to be
            # send back to the queue
            referee_map = %{ passed_items: MapSet.new(), problem_cases: :queue.new()}
            # loop over
            problems = Enum.reduce :queue.to_list(batch), referee_map, fn item, ref ->
                # get the identifier (which is the id/uuid)
                %{ id: identifier } = item
                # if this is a resource we have already encountered, we put it back in front of the queue
                # to avoid race conditions
                if MapSet.member?(ref.passed_items, identifier) do
                    # put in referee queue, send back latter
                    %{ ref | problem_cases: :queue.in(item, ref.problem_cases) }
                else
                    try do
                        # execute the query
                        execute(item)
                    rescue
                        # log this exception
                        e -> Logger.error("!! Database Queue: could not save item \n#{ inspect(item) }\n#{ inspect(e) }")
                    end
                    # and add to referee's passed items
                    %{ ref | passed_items: MapSet.put(ref.passed_items, identifier) }
                end
            end

            # return joined queue of problem cases (left-side, first to execute) and remaining queue
            :queue.join(problems.problem_cases, new_queue)
        else
            queue
        end

        # and return async
        { :noreply, queue}
    end

    # execute async with Repo
    defp execute(item) do
        case item.action do
            "insert" ->
                Repo.insert(item.resource)
            "update" ->
                Repo.update(item.resource)
        end
    end

end
