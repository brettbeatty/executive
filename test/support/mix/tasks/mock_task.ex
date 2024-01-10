defmodule Mix.Tasks.MockTask do
  @shortdoc "A task that does something"
  @moduledoc """
  This is a task that does something.

  ## Usage

      mix mock_task [OPTIONS]
  """
  use Executive.Task

  with_schema fn schema ->
    quote do
      @moduledoc """
      #{@moduledoc}
      ## Options

      #{unquote(Executive.Schema.option_docs(schema, except: [:ad_hoc_switch]))}
      """
    end
  end

  option_type option(), only: [:boolean_switch, :count_switch, :enum_switch, :string_switch]
  options_type options(), except: [:ad_hoc_switch]

  @optdoc "we can't build docs for ad hoc"
  option :ad_hoc_switch, {:ad_hoc, &__MODULE__.one_less/1}, alias: :a

  @optdoc "something about the boolean switch"
  option :boolean_switch, :boolean, alias: :b

  @optdoc "counts stuff"
  option :count_switch, :count, alias: :c

  @optdoc "behaves differently based on alfa vs bravo"
  option :enum_switch, {:enum, [:alfa, :bravo]}, alias: :e

  @optdoc "not a whole number"
  option :float_switch, :float, alias: :f

  @optdoc "any integer will do"
  option :integer_switch, :integer, alias: :i

  @optdoc "some sort of silly string"
  option :string_switch, :string, alias: :s

  with_schema fn schema ->
    schema = Macro.escape(schema)

    quote do
      def schema, do: unquote(schema)
    end
  end

  @impl Executive.Task
  def run(argv, opts) do
    {argv, opts}
  end

  def one_less(request) do
    case request do
      :name ->
        "one less"

      {:parse, raw} ->
        {:ok, raw - 1}

      :raw_type ->
        :integer

      :spec ->
        quote(do: integer())
    end
  end
end
