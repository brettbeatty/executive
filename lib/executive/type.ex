# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule Executive.Type do
  @moduledoc """
  Provides a behaviour for types that can be parsed from mix task args.
  """

  @typedoc """
  Aliases can be used in lieu of module names for built-in types.

  Alias              | Type
  ------------------ | ----
  `:base`            | `Executive.Types.Base`
  `:base16`          | `{Executive.Types.Base, :"16"}`
  `:base32`          | `{Executive.Types.Base, :"32"}`
  `:base64`          | `{Executive.Types.Base, :"64"}`
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
  `:uri`             | `Executive.Types.URI`
  `:url_base64`      | `{Executive.Types.Base, :url_64}`
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
  Executive types implement `Executive.Type` behaviour.

  But the `t:t/0` typespec includes more than these modules:
  - Built-in types have [aliases](`t:alias/0`) that can be used in lieu of
    module names.
  - Types can be parametrized by wrapping them in a `{type, params}` tuple.
  """
  @type t() :: alias() | module()

  @doc """
  Each type should provide a friendly name.

  This name can appear in a number of places:
    - when options of type are missing
      - switch is given but has no value to capture
      - option is required, but switch isn't given
    - default error message if `c:parse/2` returns `:error`
    - when docs are built for options of type

  Typically this name is a string, but implementations may choose to return any
  chardata.
  """
  @callback name(params()) :: IO.chardata()

  @doc """
  Parse a raw value to build a refined value.

  This callback receives 2 args:
    - the type params given when creating the option
      - empty list if no parameters given
    - raw value string

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
  @callback parse(params(), String.t() | nil) :: {:ok, term()} | :error | {:error, IO.chardata()}

  @doc """
  Each type should provide a spec for the refined value returned by `c:parse/2`.

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
  Resolves alias `type` and `params` into concrete type and params.

  See `t:alias/0` for this mapping.
  """
  @spec unalias(t(), params()) :: {module(), params()}
  def unalias(type, params)
  def unalias(:base, params), do: {Executive.Types.Base, params}
  def unalias(:base16, params), do: {Executive.Types.Base, {:"16", params}}
  def unalias(:base32, params), do: {Executive.Types.Base, {:"32", params}}
  def unalias(:base64, params), do: {Executive.Types.Base, {:"64", params}}
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
  def unalias(:uri, params), do: {Executive.Types.URI, params}
  def unalias(:url_base64, params), do: {Executive.Types.Base, {:url_64, params}}
  def unalias(:uuid, params), do: {Executive.Types.UUID, params}
  def unalias(module, params) when is_atom(module), do: {module, params}
end
