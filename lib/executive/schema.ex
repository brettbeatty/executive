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
  The `:only` and `:except` keywords are used to filter options.

  They two are mutually exclusive.
  """
  @type option_filter() :: [except: [atom()]] | [only: [atom()]]

  @typedoc """
  A schema outlines the desired structure for parsed arguments.
  """
  @type t() :: %__MODULE__{options: %{atom() => Option.t()}}

  @typep parse_acc() :: %{
           argv: argv(),
           error: ParseError.t(),
           opts: keyword(),
           schema: t(),
           seen: MapSet.t(Option.name())
         }
  @typep switch_map() :: %{String.t() => {Option.t(), Type.switch_flag()}}

  defstruct [:options]

  @doc """
  Create a new schema.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{options: %{}}
  end

  @doc """
  Build documentation for `schema`'s options.

      Schema.new()
      |> Schema.put_option(:my_boolean, :boolean, doc: "controls something")
      |> Schema.put_option(:my_enum, {:enum, [:x, :y, :z]}, doc: "an enum of some kind")
      |> Schema.put_option(:my_float, :float, doc: "some sort of rate, maybe", required: true)
      |> Schema.option_docs()
      # - `--my-boolean` - boolean - controls something
      # - `--my-enum` - enum (x, y, z) - an enum of some kind
      # - `--my-float` - float, required - some sort of rate, maybe

  """
  @spec option_docs(t()) :: IO.chardata()
  @spec option_docs(t(), option_filter()) :: IO.chardata()
  def option_docs(schema, opts \\ []) do
    %__MODULE__{options: options} = schema

    schema
    |> option_names(opts)
    |> Enum.map(&(options |> Map.fetch!(&1) |> Option.docs()))
    |> Enum.intersperse(?\n)
  end

  @doc """
  Build a typespec for an option parsed by `schema`.

  This typespec is in the form of a quoted AST and intended to be used by
  `Executive.Task.option_type/2`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_integer, :integer)
      ...> |> Schema.put_option(:my_string, :string)
      ...> |> Schema.option_typespec()
      ...> |> Macro.to_string()
      "{:my_integer, integer()} | {:my_string, String.t()}"

  Supports options `:only` and `:except`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_boolean, :boolean)
      ...> |> Schema.put_option(:my_enum, {:enum, [:a, :b, :c]})
      ...> |> Schema.put_option(:my_float, :float)
      ...> |> Schema.option_typespec(only: [:my_boolean, :my_enum])
      ...> |> Macro.to_string()
      "{:my_boolean, boolean()} | {:my_enum, :a | :b | :c}"

  """
  @spec option_typespec(t()) :: Macro.t()
  @spec option_typespec(t(), option_filter()) :: Macro.t()
  def option_typespec(schema, opts \\ []) do
    schema
    |> options_typespec(opts)
    |> Enum.reverse()
    |> Enum.reduce(&quote(do: unquote(&1) | unquote(&2)))
  end

  @doc """
  Build a typespec for options parsed by `schema`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_float, :float)
      ...> |> Schema.put_option(:my_string, :string)
      ...> |> Schema.put_option(:my_uuid, :uuid)
      ...> |> Schema.options_typespec()
      ...> |> Macro.to_string()
      "[my_float: float(), my_string: String.t(), my_uuid: <<_::288>>]"

  Supports options `:only` and `:except`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_boolean, :boolean)
      ...> |> Schema.put_option(:my_float, :float)
      ...> |> Schema.put_option(:my_integer, :integer)
      ...> |> Schema.options_typespec(except: [:my_boolean])
      ...> |> Macro.to_string()
      "[my_float: float(), my_integer: integer()]"

  """
  @spec options_typespec(t()) :: Macro.t()
  @spec options_typespec(t(), option_filter()) :: Macro.t()
  def options_typespec(schema, opts \\ []) do
    %__MODULE__{options: options} = schema

    schema
    |> option_names(opts)
    |> Enum.map(&{&1, options |> Map.fetch!(&1) |> Option.spec()})
  end

  @spec option_names(t(), option_filter()) :: [atom()]
  defp option_names(schema, opts)

  defp option_names(schema, []) do
    schema
    |> options()
    |> Enum.map(& &1.name)
    |> Enum.sort()
  end

  defp option_names(_schema, only: only) when is_list(only) do
    only
  end

  defp option_names(schema, except: except) when is_list(except) do
    option_names(schema, []) -- except
  end

  @doc """
  Parse `argv` into the structure described in `schema`.

  When parsing is successful it returns `{:ok, new_argv, opts}`.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_integer, :integer)
      ...> |> Schema.put_option(:my_string, :string, alias: :s)
      ...> |> Schema.put_option(:my_boolean, :boolean, alias: :b, unique: false)
      ...> |> Schema.parse(["-b", "a", "-s", "bravo", "-b", "--my-integer", "7"])
      {:ok, ["a"], [my_boolean: true, my_string: "bravo", my_boolean: true, my_integer: 7]}

  When parsing fails it raises an `Executive.ParseError`.

      iex> {:error, error} =
      ...>   Schema.new()
      ...>   |> Schema.put_option(:my_enum, {:enum, [:a, :b, :c]})
      ...>   |> Schema.parse(["--my-enum", "d", "--another-switch", "7"])
      iex> raise error
      ** (Executive.ParseError) 2 errors found!
      --my-enum : Expected one of (a, b, c), got "d"
      --another-switch : Unknown option

  """
  @spec parse(t(), argv()) :: {:ok, argv(), keyword()} | {:error, ParseError.t()}
  def parse(schema, argv) do
    acc = %{
      argv: [],
      error: ParseError.new(),
      opts: [],
      schema: schema,
      seen: MapSet.new()
    }

    parse(acc, argv, build_switch_map(schema))
  end

  @spec build_switch_map(t()) :: %{String.t() => {Option.t(), Type.switch_flag()}}
  defp build_switch_map(schema) do
    for option <- options(schema),
        {switch, switch_flags} <- Option.switches(option),
        into: %{} do
      {switch, {option, switch_flags}}
    end
  end

  @spec parse(parse_acc(), argv(), switch_map()) ::
          {:ok, argv(), keyword()} | {:error, ParseError.t()}
  defp parse(acc, argv, switches)

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp parse(acc, [switch = "-" <> _rest | argv], switches) do
    case parse_switch(switch, switches, argv) do
      {:ok, option, value, new_argv} ->
        acc
        |> Map.update!(:opts, &[{option.name, value} | &1])
        |> Map.update!(:seen, &MapSet.put(&1, option.name))
        |> parse(new_argv, switches)

      {:error, option_name, message} ->
        acc
        |> Map.update!(:error, &ParseError.put_switch_error(&1, switch, message))
        |> Map.update!(:seen, &MapSet.put(&1, option_name))
        |> parse(argv, switches)
    end
  end

  defp parse(acc, [arg | argv], switches) do
    acc
    |> Map.update!(:argv, &[arg | &1])
    |> parse(argv, switches)
  end

  defp parse(acc, [], _switches) do
    %{argv: argv, error: error, opts: opts} = check_required(acc)

    with :ok <- ParseError.check_empty(error) do
      {:ok, Enum.reverse(argv), resolve_unique(opts, acc.schema, [], MapSet.new())}
    end
  end

  @spec parse_switch(String.t(), switch_map(), [String.t()]) ::
          {:ok, Option.t(), term(), [String.t()]} | {:error, Option.name() | nil, IO.chardata()}
  defp parse_switch(switch, switches, argv) do
    with {:ok, option, switch_flag} <- lookup_switch(switches, switch),
         {:ok, raw_value, new_argv} <- capture(option, switch_flag, argv),
         {:ok, refined_value} <- parse_option(option, switch_flag, raw_value) do
      {:ok, option, refined_value, new_argv}
    end
  end

  @spec lookup_switch(switch_map(), String.t()) ::
          {:ok, Option.t(), Type.switch_flag()} | {:error, nil, IO.chardata()}
  defp lookup_switch(switches, switch) do
    case Map.fetch(switches, switch) do
      {:ok, {option, switch_flag}} ->
        {:ok, option, switch_flag}

      :error ->
        {:error, nil, "Unknown option"}
    end
  end

  @spec capture(Option.t(), Type.switch_flag(), [String.t()]) ::
          {:ok, String.t() | nil, [String.t()]} | {:error, Option.name(), IO.chardata()}
  defp capture(option, switch_flag, argv) do
    if Option.capture?(option, switch_flag) do
      case argv do
        ["-" <> _rest | _argv] ->
          {:error, option.name, ["Missing argument of type " | Option.type_name(option)]}

        [raw_value | new_argv] ->
          {:ok, raw_value, new_argv}

        [] ->
          {:error, option.name, ["Missing argument of type " | Option.type_name(option)]}
      end
    else
      {:ok, nil, argv}
    end
  end

  @spec parse_option(Option.t(), Type.switch_flag(), String.t()) ::
          {:ok, term()} | {:error, Option.name(), IO.chardata()}
  defp parse_option(option, switch_flag, raw_value) do
    with {:error, message} <- Option.parse(option, switch_flag, raw_value) do
      {:error, option.name, message}
    end
  end

  @spec check_required(parse_acc()) :: parse_acc()
  defp check_required(acc) do
    Map.update!(acc, :error, fn error ->
      for option <- options(acc.schema), reduce: error do
        error ->
          [{switch, _switch_flag} | _switches] = Option.switches(option)

          if option.required and not MapSet.member?(acc.seen, option.name) do
            message = ["Missing argument of type " | Option.type_name(option)]
            ParseError.put_switch_error(error, switch, message)
          else
            error
          end
      end
    end)
  end

  @spec resolve_unique(keyword(), t(), keyword(), MapSet.t(Option.name())) :: keyword()
  defp resolve_unique(opts, schema, acc, seen)

  defp resolve_unique([{key, value} | opts], schema, acc, seen) do
    option = Map.fetch!(schema.options, key)

    if option.unique do
      if MapSet.member?(seen, key) do
        resolve_unique(opts, schema, acc, seen)
      else
        resolve_unique(opts, schema, [{key, value} | acc], MapSet.put(seen, key))
      end
    else
      resolve_unique(opts, schema, [{key, value} | acc], seen)
    end
  end

  defp resolve_unique([], _schema, acc, _seen) do
    acc
  end

  @spec options(t()) :: Enumerable.t(Option.t())
  defp options(schema) do
    %__MODULE__{options: options} = schema
    Stream.map(options, fn {_name, option} -> option end)
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
      ...> |> Schema.put_option(:my_string, :string, alias: :s)
      ...> |> Schema.put_option(:my_float, :float, alias: :f)
      ...> |> Schema.parse!(["more", "--my-string", "-f", "not a float"])
      ** (Executive.ParseError) 2 errors found!
      --my-string : Missing argument of type string
      -f : Expected type float, got "not a float"

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

          iex> Schema.new()
          ...> |> Schema.put_option(:my_option, :string, alias: :m)
          ...> |> Schema.parse!(["-m", "my string"])
          {[], my_option: "my string"}

    - `:doc` - documentation for the option

          iex> Schema.new()
          ...> |> Schema.put_option(:my_option, :integer, doc: "some documentation")
          ...> |> Schema.option_docs()
          ...> |> to_string()
          "  - `--my-option` - integer - some documentation"

    - `:required` - when true, option is required

          iex> Schema.new()
          ...> |> Schema.put_option(:my_option, :uuid, required: true)
          ...> |> Schema.parse!([])
          ** (Executive.ParseError) 1 error found!
          --my-option : Missing argument of type UUID

    - `:unique` - when false, allows options to be passed more than once

          iex> Schema.new()
          ...> |> Schema.put_option(:my_option, :boolean, unique: false)
          ...> |> Schema.parse!(["--my-option", "--no-my-option", "--my-option"])
          {[], [my_option: true, my_option: false, my_option: true]}

  """
  @spec put_option(t(), atom(), Option.type()) :: t()
  @spec put_option(t(), atom(), Option.type(), Option.opts()) :: t()
  def put_option(schema, name, type, opts \\ []) do
    option = Option.new(name, type, opts)
    Map.update!(schema, :options, &Map.put(&1, name, option))
  end
end
