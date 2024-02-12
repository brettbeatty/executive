defmodule Executive.Schema do
  @moduledoc """
  A schema declares options that can be parsed from mix task args.
  """
  alias Executive.ParseError
  alias Executive.Schema.Option

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
           errors: [{String.t(), IO.chardata()}],
           opts: keyword(),
           schema: t(),
           seen: MapSet.t(Option.name())
         }

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

  This typespec is in the form of a quoted AST and intended to be injected using
  `Executive.Task.with_schema/1`.

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
      errors: [],
      opts: [],
      schema: schema,
      seen: MapSet.new()
    }

    parse(acc, argv, build_parse_opts(schema))
  end

  @spec build_parse_opts(t()) :: OptionParser.options()
  defp build_parse_opts(schema) do
    [
      strict: switches(schema),
      aliases: aliases(schema)
    ]
  end

  @spec switches(t()) :: [{atom(), :boolean | :string}]
  defp switches(schema) do
    for option <- options(schema) do
      raw_type =
        if option.type == Executive.Types.Boolean do
          :boolean
        else
          :string
        end

      {option.name, raw_type}
    end
  end

  @spec aliases(t()) :: [{atom(), atom()}]
  defp aliases(schema) do
    for option <- options(schema),
        alias <- option.aliases do
      {alias, option.name}
    end
  end

  @spec parse(parse_acc(), argv(), OptionParser.options()) ::
          {:ok, argv(), keyword()} | {:error, ParseError.t()}
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp parse(acc, argv, parse_opts) do
    case OptionParser.next(argv, parse_opts) do
      {:ok, name, value, rest} ->
        acc
        |> parse_and_validate(name, value, hd(argv))
        |> put_seen(name)
        |> parse(rest, parse_opts)

      {:invalid, switch, nil, rest} ->
        option = lookup_option(acc, switch)

        acc
        |> put_error(switch, ["Missing argument of type " | Option.type_name(option)])
        |> put_seen(option.name)
        |> parse(rest, parse_opts)

      {:undefined, switch, _value, rest} ->
        acc
        |> put_error(switch, "Unknown option")
        |> parse(rest, parse_opts)

      {:error, [arg | rest]} ->
        acc
        |> Map.update!(:argv, &[arg | &1])
        |> parse(rest, parse_opts)

      {:error, []} ->
        to_parse_result(acc)
    end
  end

  @spec parse_and_validate(parse_acc(), atom(), String.t() | boolean(), String.t()) :: parse_acc()
  defp parse_and_validate(acc, key, value, switch)

  defp parse_and_validate(acc, key, value, switch) when is_binary(value) do
    case acc |> lookup_option(key) |> Option.parse_and_validate(value) do
      {:ok, parsed_value} ->
        put_parsed_option(acc, key, parsed_value)

      {:error, error} ->
        put_error(acc, switch, error)
    end
  end

  defp parse_and_validate(acc, key, value, _switch) when is_boolean(value) do
    put_parsed_option(acc, key, value)
  end

  @spec lookup_option(parse_acc(), atom() | String.t()) :: Option.t()
  defp lookup_option(acc, name_or_switch)

  defp lookup_option(acc, name) when is_atom(name) do
    %{schema: %__MODULE__{options: %{^name => option}}} = acc
    option
  end

  defp lookup_option(acc, switch) when is_binary(switch) do
    {[{name, true}], []} = OptionParser.parse!([switch], switches: [])
    lookup_option(acc, name)
  end

  @spec put_parsed_option(parse_acc(), atom(), term()) :: parse_acc()
  defp put_parsed_option(acc, name, value) do
    Map.update!(acc, :opts, &[{name, value} | &1])
  end

  @spec put_error(parse_acc(), String.t(), IO.chardata()) :: parse_acc()
  defp put_error(acc, switch, message) do
    Map.update!(acc, :errors, &[{switch, message} | &1])
  end

  @spec put_seen(parse_acc(), atom()) :: parse_acc()
  defp put_seen(acc, name) do
    Map.update!(acc, :seen, &MapSet.put(&1, name))
  end

  @spec to_parse_result(parse_acc()) :: {:ok, argv(), keyword()} | {:error, ParseError.t()}
  defp to_parse_result(acc) do
    %{argv: argv, errors: errors, opts: opts, schema: schema} = check_required(acc)

    case errors do
      [] ->
        {:ok, Enum.reverse(argv), resolve_unique(opts, schema, [], MapSet.new())}

      [_ | _] ->
        {:error, errors |> Enum.reverse() |> ParseError.exception()}
    end
  end

  @spec check_required(parse_acc()) :: parse_acc()
  defp check_required(acc) do
    for option <- options(acc.schema), reduce: acc do
      acc ->
        if option.required and not MapSet.member?(acc.seen, option.name) do
          [switch] = OptionParser.to_argv([{option.name, true}])
          put_error(acc, switch, ["Missing argument of type " | Option.type_name(option)])
        else
          acc
        end
    end
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

    - `:validate` - one or more functions that validate refined value

          iex> validate = fn date ->
          ...>   case Date.compare(date, ~D[2024-01-01]) do
          ...>     :gt -> :ok
          ...>     :eq -> :ok
          ...>     :lt -> {:error, "Expected a date after 2024-01-01"}
          ...>   end
          ...> end
          iex> Schema.new()
          ...> |> Schema.put_option(:my_option, :date, validate: validate)
          ...> |> Schema.parse!(["--my-option", "2023-12-31"])
          ** (Executive.ParseError) 1 error found!
          --my-option : Expected a date after 2024-01-01

  """
  @spec put_option(t(), atom(), Option.type()) :: t()
  @spec put_option(t(), atom(), Option.type(), Option.opts()) :: t()
  def put_option(schema, name, type, opts \\ []) do
    option = Option.new(name, type, opts)
    Map.update!(schema, :options, &Map.put(&1, name, option))
  end
end
