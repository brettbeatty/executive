defmodule Executive.Type do
  @moduledoc """
  Provides a behaviour for types that can be parsed from mix task args.
  """
  alias Executive.Schema.Option

  @typedoc """
  Aliases can be used in lieu of module names for built-in types.

  Alias      | Module
  ---------- | ------
  `:boolean` | `Executive.Types.Boolean`
  `:enum`    | `Executive.Types.Enum`
  `:float`   | `Executive.Types.Float`
  `:integer` | `Executive.Types.Integer`
  `:string`  | `Executive.Types.String`
  `:uuid`    | `Executive.Types.UUID`

  """
  @type alias() :: :boolean | :enum | :float | :integer | :string | :uuid

  @typedoc """
  To support parametrization, all type callbacks accept parameters.

  If no parameters are provided, callbacks are instead given an empty list.
  """
  @type params() :: term() | []

  @typedoc """
  Corresponds with an underlying `OptionParser` type.
  """
  @type raw_type() :: :boolean | :count | :float | :integer | :string

  @typedoc """
  The raw value passed to `c:parse/3` after `OptionParser` parsing.
  """
  @type raw_value() :: boolean() | float() | integer() | String.t()

  @typedoc """
  Some types may parse differently based on the switch provided.

  Such types should implement `c:switches/3` and give switches flags
  that will be passed into `c:capture?/2` and `c:parse/3`.

  Any type that doesn't implement `c:switches/3` will receive a `nil` flag.
  """
  @type switch_flag() :: term() | nil

  @typedoc """
  Executive types implement `Executive.Type` behaviour.

  But the `t:t/0` typespec includes more than these modules:
  - Built-in types have [aliases](`t:alias/0`) that can be used in lieu of
    module names.
  - Types can be parametrized by wrapping them in a `{type, params}` tuple.
  """
  @type t() :: alias() | module()

  @doc """
  Most types of switches capture the value following.

  Some types, such as boolean, don't capture a value. These can implement
  `c:capture?/2` to return whether a value should be captured.
  """
  @callback capture?(params(), switch_flag()) :: boolean()

  @doc """
  Each type should provide a friendly name.

  This name is displayed when an argument is missing or if the provided value
  cannot be parsed into its "raw" value.

  Typically this name is a string, but implementations may choose to return any
  chardata.
  """
  @callback name(params()) :: IO.chardata()

  @doc """
  Parse a raw value to build a refined value.

  The type of the raw value is determined by `c:raw_type/1`.

  Implementations should return `{:ok, refined_value}` if the raw value is
  parsed successfully. Otherwise `{:error, message}` should be returned, where
  `message` briefly describes why parsing failed. This message can be a string,
  but the error messages are compiled into a larger string, so individual
  messages can be any chardata.
  """
  @callback parse(params(), switch_flag(), raw_value() | nil) ::
              {:ok, term()} | {:error, IO.chardata()}

  @doc """
  Each type has an underlying `OptionParser` type.

  Most types will want to build on `:string`, but there can be advantages to
  starting with another raw type.

  This callback will affect the type of `raw` in `c:parse/3`.

  `c:raw_type/1` returns | `c:parse/3` receives
  ---------------------- | --------------------
  `:boolean`             | `t:boolean/0`
  `:count`               | `t:pos_integer/0`
  `:float`               | `t:float/0`
  `:integer`             | `t:integer/0`
  `:string`              | `t:String.t/0`

  """
  @callback raw_type(params()) :: raw_type()

  @doc """
  Each type should provide a spec for the refined value returned by `c:parse/3`.

  This spec should be returned as a quoted AST.

  ## Examples
  If a type parsed into a string with a set size, its implementation of this call
  could look something like this:

      @impl Executive.Type
      def spec(params) do
        bits = Keyword.get(params, :size, 32)

        quote do
          <<_::unquote(bits)>>
        end
      end

  """
  @callback spec(params()) :: Macro.t()

  @doc """
  Some types may parse differently based on the switch provided.

  Such types should implement `c:switches/3` and give switches flags
  that will be passed into `c:capture?/2` and `c:parse/3`.

  Any type that doesn't implement `c:switches/3` will receive a `nil` flag.
  """
  @callback switches(params(), Option.name(), [Option.alias()]) :: [{String.t(), switch_flag()}]

  @optional_callbacks capture?: 2, switches: 3

  @doc """
  Resolves alias `type` and `params` into concrete type and params.
  """
  @spec unalias(t(), params()) :: {module(), params()}
  def unalias(type, params)
  def unalias(:boolean, params), do: {Executive.Types.Boolean, params}
  def unalias(:enum, params), do: {Executive.Types.Enum, params}
  def unalias(:float, params), do: {Executive.Types.Float, params}
  def unalias(:integer, params), do: {Executive.Types.Integer, params}
  def unalias(:string, params), do: {Executive.Types.String, params}
  def unalias(:uuid, params), do: {Executive.Types.UUID, params}
  def unalias(module, params) when is_atom(module), do: {module, params}
end
