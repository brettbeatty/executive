defmodule Executive.Type do
  @moduledoc """
  Provides a behaviour for types that can be parsed from mix task args.
  """

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
  The raw value passed to `c:parse/2` after `OptionParser` parsing.
  """
  @type raw_value() :: boolean() | float() | integer() | String.t()

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
  @callback parse(raw_value(), params()) :: {:ok, term()} | {:error, IO.chardata()}

  @doc """
  Each type has an underlying `OptionParser` type.

  Most types will want to build on `:string`, but there can be advantages to
  starting with another raw type.

  This callback will affect the type of `raw` in `c:parse/2`.

  `c:raw_type/1` returns | `c:parse/w` receives
  ---------------------- | --------------------
  :boolean               | `t:boolean/0`
  :count                 | `t:pos_integer/0`
  :float                 | `t:float/0`
  :integer               | `t:integer/0`
  :string                | `t:String.t/0`

  """
  @callback raw_type(params()) :: raw_type()

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
end
