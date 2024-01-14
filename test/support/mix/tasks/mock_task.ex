defmodule Mix.Tasks.MockTask do
  @shortdoc "A task that does something"
  @moduledoc """
  This is a task that does something.

  ## Usage

      mix mock_task [OPTIONS]

  """
  use Executive.Task

  moduledoc_append """
  ## Cool Options

  #{Executive.Schema.option_docs(&1, only: [:enum_switch])}

  ## Useful Options

  #{Executive.Schema.option_docs(&1, only: [:string_switch, :integer_switch, :boolean_switch])}

  """

  moduledoc_append """
  ## I'm Not Sure These Will Get Used

  #{Executive.Schema.option_docs(&1, only: [:float_switch])}

  """

  option_type option(), only: [:boolean_switch, :enum_switch, :string_switch]
  options_type options()

  @optdoc "something about the boolean switch"
  option :boolean_switch, :boolean, alias: :b

  @optdoc "behaves differently based on alfa vs bravo"
  option :enum_switch, {:enum, [:alfa, :bravo]}, alias: :e

  @optdoc "not a whole number"
  option :float_switch, :float, alias: :f

  @optdoc "any integer will do"
  option :integer_switch, :integer, alias: :i

  @optdoc "some sort of silly string"
  option :string_switch, :string, alias: :s

  with_schema fn schema ->
    options = schema.options |> Map.keys() |> Enum.sort()

    quote do
      def options, do: unquote(options)
    end
  end

  with_schema :ast, fn schema ->
    quote do
      def schema, do: unquote(schema)
    end
  end

  @impl Executive.Task
  def run(argv, opts) do
    {argv, opts}
  end
end
