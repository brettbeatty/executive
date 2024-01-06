defmodule Executive.Schema.Option do
  @moduledoc """
  A schema option defines an option that can be parsed from mix task args.
  """
  alias Executive.Type

  @type opts() :: [alias: atom() | [atom()]]
  @type t() :: %__MODULE__{aliases: [atom()], name: atom(), type: module(), type_params: term()}
  @type type() :: Type.t() | {Type.t(), Type.params()}

  defstruct [:aliases, :name, :type, :type_params]

  @doc """
  Create a new schema option.

  Any type [aliases](`t:Executive.Type.alias/0`) are resolved here.

  This function is rarely called directly but instead powers
  `Executive.Schema.put_option/4`.
  """
  @spec new(atom(), type(), opts()) :: t()
  def new(name, type, opts) do
    {type, type_params} = unalias(type)

    %__MODULE__{
      aliases: opts |> Keyword.get(:alias) |> List.wrap(),
      name: name,
      type: type,
      type_params: type_params
    }
  end

  @spec unalias(type()) :: {Type.t(), Type.params()}
  defp unalias(type)
  defp unalias(type) when is_atom(type), do: Type.unalias(type, [])
  defp unalias({type, params}) when is_atom(type), do: Type.unalias(type, params)
end
