defmodule Mix.Tasks.Executive.Gen.Task do
  @shortdoc "Generates an Executive task."
  @moduledoc """
  Generates an Executive task.

      $ mix executive.gen.task something.do --uuid id --required --string title

  The first argument is the name of the mix task to generate.

  Options can be passed in using type switches followed by the option name and a
  number of modifier switches.

  """
  use Executive.Task
  import Executive.Schema, only: [option_docs: 2]
  alias Executive.Schema.Option
  alias Executive.Task.Generator

  moduledoc_append """
  ## Type switches

  Each of these switches takes a name string and adds an option with that name
  to the generated task. The type of the option is the
  [alias](`t:Executive.Type.alias/0`) of the same name as the switch.

  #{option_docs(&1, only: [:boolean, :count, :float, :integer, :string, :uuid])}

  Running the following task

      $ mix executive.gen.task my.task --float my_float --string my_string

  Would result in options like these

      option :my_float, :float
      option :my_string, :string

  ## Modifier switches

  These switches modify the preceding option. Each corresponds with one of
  `t:Executive.Option.opts/0` and is described in greater detail in the docs for
  `Executive.Schema.put_option/4`.

  #{option_docs(&1, only: [:alias, :doc, :required, :unique])}

  Running the following task

      $ mix executive.gen.task my.task --string my_string \\
        --alias s --doc 'my doc' --required --no-unique

  Would result in an option like this

      option :my_string, :string,
        alias: [:s],
        doc: "my doc",
        required: true,
        unique: false

  ## Command line options

  These switches apply to the entire generated task, not a particular option.

  #{option_docs(&1, only: [:start_application])}

  """

  options_type options()

  # type switches
  @optdoc "See `Executive.Types.Boolean`"
  option :boolean, :string, unique: false

  @optdoc "See `Executive.Types.Count`"
  option :count, :string, unique: false

  @optdoc "See `Executive.Types.Float`"
  option :float, :string, unique: false

  @optdoc "See `Executive.Types.Integer`"
  option :integer, :string, unique: false

  @optdoc "See `Executive.Types.String`"
  option :string, :string, unique: false

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
  @type_switches [:boolean, :count, :float, :integer, :string, :uuid]

  @spec parse_options(options()) ::
          {:ok, [Generator.option()], Generator.task_opts()} | {:error, String.t()}
  defp parse_options(options) do
    case options |> Enum.reverse() |> do_parse_options() do
      {:ok, parsed_options, generator_opts, []} ->
        {:ok, parsed_options, generator_opts}

      {:ok, _parsed_options, _generator_opts, [{key, _value} | _option_opts]} ->
        {:error, "Modifier switch #{switch_name(key)} must follow a type switch"}

      {:error, message} ->
        {:error, message}
    end
  end

  @spec do_parse_options(options()) ::
          {:ok, [Generator.option()], Generator.opts(), Option.opts()} | {:error, String.t()}
  defp do_parse_options(options) do
    Enum.reduce_while(options, {:ok, [], [], []}, fn
      {type, name}, {:ok, parsed_options, generator_opts, option_opts}
      when type in @type_switches ->
        option = {String.to_atom(name), type, option_opts}
        {:cont, {:ok, [option | parsed_options], generator_opts, _option_opts = []}}

      {:alias, <<char>>}, {:ok, parsed_options, generator_opts, option_opts}
      when char in ?a..?z ->
        alias = String.to_atom(<<char>>)
        {:cont, {:ok, parsed_options, generator_opts, [{:alias, alias} | option_opts]}}

      {:alias, alias}, {:ok, _parsed_options, _generator_opts, _option_opts} ->
        {:halt, {:error, "Alias must be one letter, got #{inspect(alias)}"}}

      {mod, value}, {:ok, parsed_options, generator_opts, option_opts}
      when mod in @modifier_switches ->
        {:cont, {:ok, parsed_options, generator_opts, [{mod, value} | option_opts]}}

      {key, value}, {:ok, parsed_options, generator_opts, option_opts}
      when key in @opt_switches ->
        {:cont, {:ok, parsed_options, [{key, value} | generator_opts], option_opts}}
    end)
  end

  @spec switch_name(atom()) :: String.t()
  defp switch_name(key) do
    [name] = OptionParser.to_argv([{key, true}])
    name
  end
end
