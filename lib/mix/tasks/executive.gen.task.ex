defmodule Mix.Tasks.Executive.Gen.Task do
  @shortdoc "Generates an Executive task."
  @moduledoc """
  Generates an Executive task.

      $ mix executive.gen.task something.do --uuid id --required --string title

  The first argument is the name of the mix task to generate.

  Options can be passed in using type switches followed by the option name and a
  number of modifier switches.

  ## Type switches

  Each of these switches takes a name string and adds an option with that name
  to the generated task. The type of the option is the
  [alias](`t:Executive.Type.alias/0`) of the same name as the switch.

  #{Executive.Task.option_docs(only: ~W[
    base16
    base32
    base64
    boolean
    date
    datetime
    float
    integer
    naive_datetime
    neg_integer
    non_neg_integer
    pos_integer
    string
    time
    uri
    uuid
  ]a)}

  Running the following task

      $ mix executive.gen.task my.task --float my_float --string my_string

  Would result in options like these

      option :my_float, :float
      option :my_string, :string

  ## Modifier switches

  These switches modify the preceding option. Each corresponds with one of
  `t:Executive.Option.opts/0` and is described in greater detail in the docs for
  `Executive.Schema.put_option/4`.

  #{Executive.Task.option_docs(only: [:alias, :doc, :required, :unique])}

  Running the following task

      $ mix executive.gen.task my.task --string my_string --alias s --doc 'my doc' --required --no-unique

  Would result in an option like this

      option :my_string, :string,
        alias: [:s],
        doc: "my doc",
        required: true,
        unique: false

  ## Command line options

  These switches apply to the entire generated task, not a particular option.

  #{Executive.Task.option_docs(only: [:start_application])}

  """
  use Executive.Task
  alias Executive.Schema.Option
  alias Executive.Task.Generator

  option_type option()
  options_type options()

  # type switches
  @optdoc "See `Executive.Types.Base`"
  option :base16, :string, unique: false

  @optdoc "See `Executive.Types.Base`"
  option :base32, :string, unique: false

  @optdoc "See `Executive.Types.Base`"
  option :base64, :string, unique: false

  @optdoc "See `Executive.Types.Boolean`"
  option :boolean, :string, unique: false

  @optdoc "See `Executive.Types.Date`"
  option :date, :string, unique: false

  @optdoc "See `Executive.Types.DateTime`"
  option :datetime, :string, unique: false

  @optdoc "See `Executive.Types.Float`"
  option :float, :string, unique: false

  @optdoc "See `Executive.Types.Integer`"
  option :integer, :string, unique: false

  @optdoc "See `Executive.Types.NaiveDateTime`"
  option :naive_datetime, :string, unique: false

  @optdoc "See `Executive.Types.Integer`"
  option :neg_integer, :string, unique: false

  @optdoc "See `Executive.Types.Integer`"
  option :non_neg_integer, :string, unique: false

  @optdoc "See `Executive.Types.Integer`"
  option :pos_integer, :string, unique: false

  @optdoc "See `Executive.Types.String`"
  option :string, :string, unique: false

  @optdoc "See `Executive.Types.Time`"
  option :time, :string, unique: false

  @optdoc "See `Executive.Types.Base`"
  option :url_base64, :string, unique: false

  @optdoc "See `Executive.Types.URI`"
  option :uri, :string, unique: false

  @optdoc "See `Executive.Types.UUID`"
  option :uuid, :string, unique: false

  # modifier switches
  @optdoc "a one-letter alias for the option"
  option :alias, :string, unique: false

  @optdoc "a one-line docstring for the option"
  option :doc, :string, unique: false

  @optdoc "makes the option required"
  option :required, :boolean, unique: false

  @optdoc "de-duplicates option when parsing; default is `--unique`"
  option :unique, :boolean, unique: false

  # command line options
  @optdoc "include `start_application: true` in `use Executive.Task`"
  option :start_application, :boolean

  @impl Executive.Task
  def run(argv, opts) do
    with {:ok, task_name} <- parse_task(argv),
         {:ok, options, task_opts} <- parse_options(opts) do
      Generator.generate_task(task_name, options, task_opts)
    else
      {:error, message} when is_binary(message) ->
        raise message
    end
  end

  @spec parse_task([String.t()]) :: {:ok, String.t()} | {:error, String.t()}
  defp parse_task(argv)

  defp parse_task([task_name]) do
    {:ok, task_name}
  end

  defp parse_task(argv) do
    {:error, "Expected exactly 1 non-switch argument, got #{length(argv)}"}
  end

  @modifier_switches [:alias, :doc, :required, :unique]
  @opt_switches [:start_application]
  @type_switches [
    :base16,
    :base32,
    :base64,
    :boolean,
    :date,
    :datetime,
    :float,
    :naive_datetime,
    :neg_integer,
    :non_neg_integer,
    :pos_integer,
    :integer,
    :string,
    :time,
    :url_base64,
    :uri,
    :uuid
  ]

  @spec parse_options(options()) ::
          {:ok, [Generator.option()], Generator.task_opts()} | {:error, String.t()}
  defp parse_options(options) do
    case options |> Enum.reverse() |> Enum.reduce_while({:ok, [], [], []}, &parse_options/2) do
      {:ok, parsed_options, generator_opts, []} ->
        {:ok, parsed_options, generator_opts}

      {:ok, _parsed_options, _generator_opts, [{key, _value} | _option_opts]} ->
        {:error, "Modifier switch #{switch_name(key)} must follow a type switch"}

      {:error, message} ->
        {:error, message}
    end
  end

  @spec parse_options(
          option(),
          {:ok, [Generator.option()], Generator.task_opts(), Option.opts()} | {:error, String.t()}
        ) ::
          {:halt | :cont,
           {:ok, [Generator.option()], Generator.task_opts(), Option.opts()}
           | {:error, String.t()}}
  defp parse_options({type, name}, {:ok, parsed_options, generator_opts, option_opts})
       when type in @type_switches do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    option = {String.to_atom(name), type, option_opts}
    {:cont, {:ok, [option | parsed_options], generator_opts, _option_opts = []}}
  end

  defp parse_options({:alias, <<char>>}, {:ok, parsed_options, generator_opts, option_opts})
       when char in ?a..?z do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    alias = String.to_atom(<<char>>)
    {:cont, {:ok, parsed_options, generator_opts, [{:alias, alias} | option_opts]}}
  end

  defp parse_options({:alias, alias}, {:ok, _parsed_options, _generator_opts, _option_opts}) do
    {:halt, {:error, "Alias must be one letter, got #{inspect(alias)}"}}
  end

  defp parse_options({mod, value}, {:ok, parsed_options, generator_opts, option_opts})
       when mod in @modifier_switches do
    {:cont, {:ok, parsed_options, generator_opts, [{mod, value} | option_opts]}}
  end

  defp parse_options({key, value}, {:ok, parsed_options, generator_opts, option_opts})
       when key in @opt_switches do
    {:cont, {:ok, parsed_options, [{key, value} | generator_opts], option_opts}}
  end

  @spec switch_name(atom()) :: String.t()
  defp switch_name(key) do
    [name] = OptionParser.to_argv([{key, true}])
    name
  end
end
