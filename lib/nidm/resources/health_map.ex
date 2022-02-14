defmodule HealthMap do
    use Ecto.Type

    def type, do: :map

    def cast(%{} = my_map), do: {:ok, my_map}
    def cast(_), do: :error

    def load(data) when is_map(data) do
        { :ok, (for {key, [ status, round ] } <- data, into: %{}, do: {key, { String.to_atom(status), round }} ) }
    end

    def dump(%{} = data) do
        { :ok, (for {key, { status, round }} <- data, into: %{}, do: {key, [ status, round ] } ) }
    end

end
