defmodule Executive.Schema.Option do
  @moduledoc """
  A schema option defines an option that can be parsed from mix task args.
  """
  alias Executive.Type

  @typedoc """
  Option aliases are one-letter atoms.
  """
  @type alias() :: atom()

  @typedoc """
  Option names are the keys of the parsed options.
  """
  @type name() :: atom()

  @type opts() :: [
          alias: atom() | [atom()],
          doc: String.t(),
          required: boolean(),
          unique: boolean()
        ]
  @type t() :: %__MODULE__{
          aliases: [atom()],
          doc: String.t(),
          name: atom(),
          required: boolean(),
          type: module(),
          type_params: term(),
          unique: boolean()
        }
  @type type() :: Type.t() | {Type.t(), Type.params()}

  defstruct [:aliases, :doc, :name, :required, :type, :type_params, :unique]

  @doc """
  Whether `option` switch with `switch_flag` should capture the next value.

  For most option types this will return true.

      iex> option = Option.new(:my_option, MyType, [])
      iex> Option.capture?(option, nil)
      true

  But types that implement `c:Executive.Type.capture?/2` may choose to return
  false.

      iex> option = Option.new(:my_option, :boolean, [])
      iex> Option.capture?(option, true)
      false

  """
  @spec capture?(t(), Type.switch_flag()) :: boolean()
  def capture?(option, switch_flag) do
    %__MODULE__{type: type, type_params: type_params} = option

    if function_exported?(type, :capture?, 2) do
      type.capture?(type_params, switch_flag)
    else
      true
    end
  end

  @doc """
  Build chardata documenting `option`.
  """
  @spec docs(t()) :: IO.chardata()
  def docs(option) do
    %__MODULE__{aliases: aliases, doc: doc, required: required} = option

    aliased =
      case aliases |> Enum.map(&["`-", to_string(&1), ?`]) |> Enum.intersperse(", ") do
        [] ->
          []

        aliased ->
          [?(, aliased, ") "]
      end

    required_string = if required, do: ", required", else: []
    docstring = if byte_size(doc) > 0, do: [" - ", doc], else: []

    [
      "  - `",
      switch(option),
      "` ",
      aliased,
      "- ",
      type_name(option),
      required_string,
      docstring
    ]
  end

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
      doc: opts |> Keyword.get(:doc, "") |> String.trim(),
      required: Keyword.get(opts, :required, false),
      type: type,
      type_params: type_params,
      unique: Keyword.get(opts, :unique, true)
    }
  end

  @spec unalias(type()) :: {Type.t(), Type.params()}
  defp unalias(type)
  defp unalias(type) when is_atom(type), do: Type.unalias(type, [])
  defp unalias({type, params}) when is_atom(type), do: Type.unalias(type, params)

  @doc """
  Parses `raw` using `option`'s type.

  Dispatches to type's `c:Executive.Type.parse/3` implementation.
  """
  @spec parse(t(), Type.switch_flag(), Type.raw_value()) ::
          {:ok, term()} | {:error, IO.chardata()}
  def parse(option, flag, raw) do
    %__MODULE__{type: type, type_params: params} = option
    type.parse(params, flag, raw)
  end

  @doc """
  Gets the raw type of `option`'s type.

  Dispatches to type's `c:Executive.Type.raw_type/1` implementation.
  """
  @spec raw_type(t()) :: Type.raw_type()
  def raw_type(option) do
    %__MODULE__{type: type, type_params: params, unique: unique} = option
    raw_type = type.raw_type(params)

    if unique || raw_type == :count do
      raw_type
    else
      [:keep, raw_type]
    end
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
  Build the available switches for `option`.

  This dispatches to type's `c:Executive.Type.switches/3` if implemented.
  """
  @spec switches(t()) :: [{String.t(), Type.switch_flag()}]
  def switches(option) do
    %__MODULE__{aliases: aliases, name: name, type: type, type_params: type_params} = option

    if function_exported?(type, :switches, 3) do
      type.switches(type_params, name, aliases)
    else
      switches(name, aliases)
    end
  end

  @doc """
  Build switches for option `name` and `aliases`.

  This serves as a default implementation for `c:Executive.Type.switches/3`.
  """
  @spec switches(name(), [alias()]) :: [{String.t(), Type.switch_flag()}]
  def switches(name, aliases) do
    [{switch_name(name), nil} | Enum.map(aliases, &{switch_alias(&1), nil})]
  end

  @doc """
  Create a switch string from option `alias`.

      iex> Option.switch_alias(:s)
      "-s"

  Option `alias` can also be a string. This can be used in
  `c:Executive.Type.switches/3` for generated switch aliases.

      iex> Option.switch_alias("v")
      "-v"

  """
  @spec switch_alias(alias() | String.t()) :: String.t()
  def switch_alias(alias) do
    "-#{alias}"
  end

  @doc """
  Create a switch string from option `name`.

      iex> Option.switch_name(:my_switch)
      "--my-switch"

  Option `name` can also be a string. This can be used in
  `c:Executive.Type.switches/3` for generated switch names.

      iex> Option.switch_name("no_my_switch")
      "--no-my-switch"

  """
  @spec switch_name(name() | String.t()) :: String.t()
  def switch_name(name) do
    name
    |> to_string()
    |> String.replace("_", "-")
    |> then(&<<"--", &1::binary>>)
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
