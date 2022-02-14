defmodule SetMap do
    use Ecto.Type

    def type, do: :map

    def cast(%{} = my_map), do: {:ok, my_map}
    def cast(_), do: :error

    def load(data) when is_map(data) do
        { :ok, (for {key, value } <- data, into: %{}, do: { key, MapSet.new(value) } ) }
    end

    def dump(%{} = data) do
        { :ok, (for {key, value} <- data, into: %{}, do: { key, MapSet.to_list(value) } ) }
    end

end
