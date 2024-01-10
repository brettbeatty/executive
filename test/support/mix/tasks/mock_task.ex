defmodule Mix.Tasks.MockTask do
  use Executive.Task

  option_type option(), only: [:boolean_switch, :count_switch, :enum_switch, :string_switch]
  options_type options(), except: [:ad_hoc_switch]

  option :ad_hoc_switch, {:ad_hoc, &__MODULE__.one_less/1}, alias: :a
  option :boolean_switch, :boolean, alias: :b
  option :count_switch, :count, alias: :c
  option :enum_switch, {:enum, [:alfa, :bravo]}, alias: :e
  option :float_switch, :float, alias: :f
  option :integer_switch, :integer, alias: :i
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
