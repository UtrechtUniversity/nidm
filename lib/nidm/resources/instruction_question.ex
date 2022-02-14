defmodule Nidm.Resources.InstructionQuestion do

    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
        field(:q_1, :string)
        field(:q_2, :string)
        field(:q_3, :string)
        field(:q_4, :string)
    end

    def answer_changeset(params) do
        fields = [:q_1, :q_2, :q_3, :q_4]
        %__MODULE__{}
        |> cast(params, fields)
        |> validate_required(fields)
        |> validate_inclusion(:q_1, ["d"])
        |> validate_inclusion(:q_2, ["e"])
        |> validate_inclusion(:q_3, ["d"])
        |> validate_inclusion(:q_4, ["c"])
    end

end
