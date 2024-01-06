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

  When parsing is successful it returns `{:ok, new_argv, opts}`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_integer, :integer)
      ...> |> Schema.put_option(:my_string, :string, alias: :s)
      ...> |> Schema.put_option(:my_count, :count, alias: :c)
      ...> |> Schema.parse(["-c", "a", "-s", "bravo", "-c", "--my-integer", "7"])
      {:ok, ["a"], [my_count: 2, my_string: "bravo", my_integer: 7]}

  When parsing fails it raises an `Executive.ParseError`.

      iex> {:error, error} =
      ...>   Schema.new()
      ...>   |> Schema.put_option(:my_enum, {:enum, [:a, :b, :c]})
      ...>   |> Schema.parse(["--my-enum", "d", "--another-switch", "7"])
      iex> raise error
      ** (Executive.ParseError) 2 errors found!
      --another-switch : Unknown option
      --my-enum : Expected one of (a, b, c), got "d"

  """
  @spec parse(t(), argv()) :: {:ok, argv(), keyword()} | {:error, ParseError.t()}
  def parse(schema, argv) do
    {raw_opts, new_argv, raw_errors} = parse_raw_opts(schema, argv)
    {refined_opts, refined_errors} = refine_opts(schema, raw_opts)

    case raw_errors ++ refined_errors do
      [] ->
        {:ok, new_argv, refined_opts}

      switch_errors ->
        {:error, ParseError.exception(switch_errors)}
    end
  end

  @spec parse_raw_opts(t(), argv()) :: {keyword(Type.raw_value()), argv(), switch_errors()}
  defp parse_raw_opts(schema, argv) do
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

  @spec refine_opts(t(), keyword(Type.raw_value())) :: {keyword(), switch_errors()}
  defp refine_opts(schema, raw_opts) do
    for {name, raw} <- Enum.reverse(raw_opts), reduce: {[], []} do
      {refined_opts, errors} ->
        option = Map.fetch!(schema.options, name)

        case Option.parse(option, raw) do
          {:ok, refined} ->
            {[{name, refined} | refined_opts], errors}

          {:error, message} ->
            {refined_opts, [{Option.switch(option), message} | errors]}
        end
    end
  end

  @doc """
  Assertive companion to `parse/2`.

  When parsing is successful it returns `{new_argv, opts}`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_enum, {:enum, [:a, :b, :c]}, alias: :e)
      ...> |> Schema.put_option(:my_integer, :integer)
      ...> |> Schema.parse!(["some", "--my-integer", "29", "args", "-e", "c"])
      {["some", "args"], [my_integer: 29, my_enum: :c]}

  When parsing fails it raises an `Executive.ParseError`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_count, :count, alias: [:c, :k])
      ...> |> Schema.put_option(:my_string, :string, alias: :s)
      ...> |> Schema.put_option(:my_float, :float, alias: :f)
      ...> |> Schema.parse!(["more", "-c", "--my-string", "-f", "not a float"])
      ** (Executive.ParseError) 2 errors found!
      --my-string : Missing argument of type string
      --my-float : Expected type float, got "not a float"

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
