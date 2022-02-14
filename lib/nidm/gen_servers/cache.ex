
# nicked this from https://thoughtbot.com/blog/make-phoenix-even-faster-with-a-genserver-backed-key-value-store

defmodule Nidm.GenServers.Cache do
    use GenServer

    # iex(18)> NetworkLab.GenServers.Cache.set(:message_cache, "B", 4)
    # iex(12)> NetworkLab.GenServers.Cache.set(:message_cache, "A", %{ a: 1, b: [1, 2, 3, 4]})
    # iex(17)> NetworkLab.GenServers.Cache.fetch(:message_cache, "U", :false)
    # {:not_found, false}
    # iex(16)> NetworkLab.GenServers.Cache.fetch(:message_cache, "A", :false)
    # %{a: 1, b: [1, 2, 3, 4]}

    def start_link(opts) do
        opts = if Enum.empty?(opts), do: [name: "cache"], else: opts
        # the process name is also used for the table name
        [name: table_name] = opts
        GenServer.start_link(
            __MODULE__,
            table_name,
            opts
        )
    end

    # get with a default value
    def get(pid, key, default_value) do
        case get(pid, key) do
            :not_found -> default_value
            result -> result
        end
    end

    # regular get
    def get(pid, key) do
        case GenServer.call(pid, {:get, key}) do
            [] -> :not_found
            [{_key, result}] -> result
        end
    end


    def select_by_attribute(pid, attribute, value) do
        case GenServer.call(pid, {:get, attribute, value}) do
            [] -> []
            [{_slug, result}] -> [result]
            list -> Enum.map(list, fn {_, item} -> item end)
        end
    end

    def set(pid, key, value) do
        GenServer.call(pid, {:set, key, value})
    end

    def is_member?(pid, key) do
        GenServer.call(pid, {:is_member, key})
    end

    def list_values(pid) do
        GenServer.call(pid, :list_values)
    end

    def list(pid) do
        GenServer.call(pid, :list)
    end

    def reset(pid) do
        GenServer.call(pid, :reset)
    end

    def handle_call({:get, key}, _from, table_id) do
        result = :ets.lookup(table_id, key)
        {:reply, result, table_id}
    end

    def handle_call({:get, attribute, value}, _from, table_id) do
        search_map = %{} |> Map.put(attribute, :"$1")
        search_function= [{{:_, search_map}, [{:==, :"$1", value}], [:"$_"]}]
        {:reply, :ets.select(table_id, search_function) , table_id}
    end

    def handle_call({:set, key, value}, _from, table_id) do
        true = :ets.insert(table_id,  {key, value})
        {:reply, value, table_id}
    end

    def handle_call({:is_member, key}, _from, table_id) do
        {:reply, :ets.member(table_id, key), table_id}
    end

    def handle_call(:list_values, _from, table_id) do
        {:reply, :ets.select(table_id, [{{:"$1", :"$2"}, [], [:"$2"]}]) , table_id}
    end

    def handle_call(:list, _from, table_id) do
        {:reply, :ets.select(table_id, [{{:"$1", :"$2"}, [], [[:"$1", :"$2"]]}]) , table_id}
    end

    def handle_call(:reset, _from, table_id) do
        {:reply, :ets.delete_all_objects(table_id), table_id}
    end

    def init(table_name) do
        # You could introduce multiple tables here
        table_identifier = :ets.new(table_name, [:named_table, :set, :private])
        {:ok, table_identifier}
    end

end
