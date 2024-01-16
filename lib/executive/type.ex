defmodule Executive.Type do
  @moduledoc """
  Provides a behaviour for types that can be parsed from mix task args.
  """
  alias Executive.Schema.Option

  @typedoc """
  Aliases can be used in lieu of module names for built-in types.

  Alias              | Type
  ------------------ | ----
  `:base`            | `Executive.Types.Base`
  `:boolean`         | `Executive.Types.Boolean`
  `:date`            | `Executive.Types.Date`
  `:datetime`        | `Executive.Types.DateTime`
  `:enum`            | `Executive.Types.Enum`
  `:float`           | `Executive.Types.Float`
  `:integer`         | `Executive.Types.Integer`
  `:naive_datetime`  | `Executive.Types.NaiveDateTime`
  `:neg_integer`     | `{Executive.Types.Integer, max: -1}`
  `:non_neg_integer` | `{Executive.Types.Integer, min: 0}`
  `:pos_integer`     | `{Executive.Types.Integer, min: 1}`
  `:string`          | `Executive.Types.String`
  `:time`            | `Executive.Types.Time`
  `:uuid`            | `Executive.Types.UUID`

  """
  @type alias() ::
          :base
          | :boolean
          | :date
          | :datetime
          | :enum
          | :float
          | :integer
          | :naive_datetime
          | :neg_integer
          | :non_neg_integer
          | :pos_integer
          | :string
          | :time
          | :uuid

  @typedoc """
  To support parametrization, all type callbacks accept parameters.

  If no parameters are provided, callbacks are instead given an empty list.
  """
  @type params() :: term() | []

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
  Whether to capture the value after the switch.

  Most types of switches capture a value, but some--such as boolean switches--do
  not. Types that do not need to capture a value should implement this callback
  and return false.
  """
  @callback capture?(params(), switch_flag()) :: boolean()

  @doc """
  Each type should provide a friendly name.

  This name can appear in a number of places:
    - when options of type are missing
      - switch is given but has no value to capture
      - option is required, but switch isn't given
    - default error message if `c:parse/3` returns `:error`
    - when docs are built for options of type

  Typically this name is a string, but implementations may choose to return any
  chardata.
  """
  @callback name(params()) :: IO.chardata()

  @doc """
  Parse a raw value to build a refined value.

  This callback receives 3 args:
    - the type params given when creating the option
      - empty list if no parameters given
    - switch flag associated with the switch used
      - nil unless `c:switches/3` implemented
    - raw value string
      - nil if `c:capture?/2` is implemented and returns false

  There are also 3 things that can be returned:
    - `{:ok, refined_value}` if the raw value parses successfully
    - `:error` if parsing fails
    - `{:error, message}` if parsing fails and a more specific message than
      default can be given

  ## Error messages
  The default error message looks something akin to this:

      Expected type <type name>, got "<raw value>"

  Type name for the default error message comes from `c:name/1`.

  Custom error messasges can be a string, but the error messages are compiled
  into a larger string, so individual messages can be any chardata.
  """
  @callback parse(params(), switch_flag(), String.t() | nil) ::
              {:ok, term()} | :error | {:error, IO.chardata()}

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
  Generate switches for option name and aliases.

  Some types may parse differently based on the switch provided. Boolean
  switches, for example, don't capture the value after them. Instead they rely
  on knowing whether the primary switch or negation switch was given.

  These types should implement `c:switches/3` and give each switch a flag that
  will be passed in to `c:capture?/2` and `c:parse/3`.

  `Executive.Schema.Option` provides functions to aid in implementing this task:
    - `Executive.Schema.Option.switch_name/1` builds a switch name for an
      `t:Executive.Schema.Option.name/0` or its string equivalent.
    - `Executive.Schema.Option.switch_alias/1` builds a switch alias for an
      `t:Executive.Schema.Option.alias/0` or its string equivalent.

  Any type that doesn't implement this callback will receive a nil switch flag
  in `c:capture?/2` and `c:parse/3`.
  """
  @callback switches(params(), Option.name(), [Option.alias()]) :: [{String.t(), switch_flag()}]

  @optional_callbacks capture?: 2, switches: 3

  @doc """
  Resolves alias `type` and `params` into concrete type and params.

  See `t:alias/0` for this mapping.
  """
  @spec unalias(t(), params()) :: {module(), params()}
  def unalias(type, params)
  def unalias(:base, params), do: {Executive.Types.Base, params}
  def unalias(:boolean, params), do: {Executive.Types.Boolean, params}
  def unalias(:date, params), do: {Executive.Types.Date, params}
  def unalias(:datetime, params), do: {Executive.Types.DateTime, params}
  def unalias(:enum, params), do: {Executive.Types.Enum, params}
  def unalias(:float, params), do: {Executive.Types.Float, params}
  def unalias(:integer, params), do: {Executive.Types.Integer, params}
  def unalias(:naive_datetime, params), do: {Executive.Types.NaiveDateTime, params}
  def unalias(:neg_integer, _params), do: {Executive.Types.Integer, max: -1}
  def unalias(:non_neg_integer, _params), do: {Executive.Types.Integer, min: 0}
  def unalias(:pos_integer, _params), do: {Executive.Types.Integer, min: 1}
  def unalias(:string, params), do: {Executive.Types.String, params}
  def unalias(:time, params), do: {Executive.Types.Time, params}
  def unalias(:uuid, params), do: {Executive.Types.UUID, params}
  def unalias(module, params) when is_atom(module), do: {module, params}
end
