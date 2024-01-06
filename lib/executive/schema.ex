defmodule Executive.Schema do
  @moduledoc """
  A schema declares options that can be parsed from mix task args.
  """
  alias Executive.Schema.Option

  @typedoc """
  Mix tasks receive a list of strings that may have switches.

  This type is used for the list of args both before and after removing any
  switches.
  """
  @type argv() :: [String.t()]

  @typedoc """
  A schema outlines the desired structure for parsed arguments.
  """
  @type t() :: %__MODULE__{options: %{atom() => Option.t()}}

  defstruct [:options]

  @doc """
  Create a new schema.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{options: %{}}
  end

  @doc """
  Add an option of `name` and `type` to `schema`.

  ## Options

  The following options are supported:

    - `:alias` - a single-letter atom or list of these that can be used as
      aliases for the switch name

  """
  @spec put_option(t(), atom(), Option.type()) :: t()
  @spec put_option(t(), atom(), Option.type(), Option.opts()) :: t()
  def put_option(schema, name, type, opts \\ []) do
    option = Option.new(name, type, opts)
    Map.update!(schema, :options, &Map.put(&1, name, option))
  end
end
