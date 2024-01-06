defmodule Executive.Schema do
  @moduledoc """
  A schema declares options that can be parsed from mix task args.
  """
  alias Executive.ParseError
  alias Executive.Schema.Option
  alias Executive.Type

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

  @typep switch_errors() :: [{String.t(), IO.chardata()}]

  defstruct [:options]

  @doc """
  Create a new schema.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{options: %{}}
  end

  @doc """
  Parse `argv` into the structure described in `schema`.
  """
  @spec parse(t(), argv()) :: {:ok, argv(), keyword()} | {:error, ParseError.t()}
  def parse(schema, argv) do
    {raw_opts, new_argv, raw_errors} = parse_raw_opts(argv, schema)

    case raw_errors do
      [] ->
        {:ok, new_argv, raw_opts}

      switch_errors ->
        {:error, ParseError.exception(switch_errors)}
    end
  end

  @spec parse_raw_opts(argv(), t()) :: {keyword(Type.raw_value()), argv(), switch_errors()}
  defp parse_raw_opts(argv, schema) do
    switches = for option <- options(schema), do: {option.name, Option.raw_type(option)}
    aliases = for option <- options(schema), alias <- option.aliases, do: {alias, option.name}

    {opts, new_argv, invalid} = OptionParser.parse(argv, strict: switches, aliases: aliases)
    {opts, new_argv, format_raw_errors(schema, invalid)}
  end

  @spec options(t()) :: Enumerable.t(Option.t())
  defp options(schema) do
    %__MODULE__{options: options} = schema
    Stream.map(options, fn {_name, option} -> option end)
  end

  @spec format_raw_errors(t(), [{String.t(), String.t() | nil}]) :: switch_errors()
  defp format_raw_errors(schema, invalid_switches) do
    switches = build_switch_map(schema)

    for {switch, value} <- invalid_switches do
      case Map.fetch(switches, switch) do
        {:ok, option} when is_binary(value) ->
          {Option.switch(option),
           ["Expected type ", Option.type_name(option), ", got ", inspect(value)]}

        {:ok, option} when is_nil(value) ->
          {Option.switch(option), ["Missing argument of type ", Option.type_name(option)]}

        :error ->
          {switch, "Unknown option"}
      end
    end
  end

  @spec build_switch_map(t()) :: %{String.t() => Option.t()}
  defp build_switch_map(schema) do
    options = options(schema)
    switches = for option <- options, into: %{}, do: {Option.switch(option), option}
    for option <- options, alias <- option.aliases, into: switches, do: {"-#{alias}", option}
  end

  @doc """
  Assertive companion to `parse/2`.

  When parsing is successful it returns `{new_argv, opts}`.

  When parsing fails it raises an `Executive.ParseError`.
  """
  @spec parse!(t(), argv()) :: {argv(), keyword()}
  def parse!(schema, argv) do
    case parse(schema, argv) do
      {:ok, new_argv, opts} ->
        {new_argv, opts}

      {:error, error} ->
        raise error
    end
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
