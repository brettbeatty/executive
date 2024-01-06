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

  @doc """
  Parses `raw` using `option`'s type.

  Dispatches to type's `c:Executive.Type.parse/2` implementation.
  """
  @spec parse(t(), Type.raw_value()) :: {:ok, term()} | {:error, IO.chardata()}
  def parse(option, raw) do
    %__MODULE__{type: type, type_params: params} = option
    type.parse(raw, params)
  end

  @doc """
  Gets the raw type of `option`'s type.

  Dispatches to type's `c:Executive.Type.raw_type/1` implementation.
  """
  @spec raw_type(t()) :: Type.raw_type()
  def raw_type(option) do
    %__MODULE__{type: type, type_params: params} = option
    type.raw_type(params)
  end

  @doc """
  Gets the spec for parsed values of `option`'s type.

  Dispatches to type's `c:Executive.Type.spec/1` implementation.
  """
  @spec spec(t()) :: Macro.t()
  def spec(option) do
    %__MODULE__{type: type, type_params: params} = option
    type.spec(params)
  end

  @doc """
  Gets the switch name corresponding with `option`.

      iex> option = Option.new(:my_option, MyType, [])
      iex> Option.switch(option)
      "--my-option"

  """
  @spec switch(t()) :: String.t()
  def switch(option) do
    %__MODULE__{name: name} = option
    [switch_name] = OptionParser.to_argv([{name, true}])
    switch_name
  end

  @doc """
  Gets the name of `option`'s type.

  Dispatches to type's `c:Executive.Type.name/1` implementation.
  """
  @spec type_name(t()) :: IO.chardata()
  def type_name(option) do
    %__MODULE__{type: type, type_params: params} = option
    type.name(params)
  end
end
