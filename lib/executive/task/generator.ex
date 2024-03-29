defmodule Executive.Task.Generator do
  @moduledoc """
  Generates Executive tasks.
  """
  alias Executive.Schema.Option
  alias Executive.Type
  require EEx

  @template_file Application.app_dir(:executive, ["priv", "templates", "task.ex.eex"])

  @typedoc """
  This is how options are passed in from `Mix.Tasks.Executive.Gen.Task`.
  """
  @type option() :: {atom(), Type.alias(), Option.opts()}

  @typedoc """
  These are task-level opts passed in from `Mix.Tasks.Executive.Gen.Task`.
  """
  @type task_opts() :: [start_application: boolean()]

  @doc """
  Generate a mix task with the given name and options.
  """
  @spec generate_task(String.t(), [option()], task_opts()) :: boolean()
  def generate_task(task_name, options, task_opts) do
    assigns = [
      options: build_options(options),
      task_module: task_module(task_name),
      task_name: task_name,
      task_opts: build_opts(task_opts)
    ]

    path = Path.join(["lib", "mix", "tasks", task_name <> ".ex"])

    Mix.Generator.copy_template(@template_file, path, assigns)
  end

  @spec build_options([option()]) :: IO.chardata()
  defp build_options(options)

  defp build_options([]) do
    []
  end

  defp build_options(options) do
    options
    |> Enum.reverse()
    |> build_options([?\n])
  end

  @spec build_options([option()], IO.chardata()) :: IO.chardata()
  defp build_options(options, chardata)

  defp build_options([option | options], chardata) do
    {key, type, opts} = option

    doc =
      if doc = Keyword.get(opts, :doc), do: ["@optdoc ", iodata_inspect(doc), "\n  "], else: []

    new_opts = Keyword.delete(opts, :doc)
    spacing = if options == [] or doc == [], do: "\n  ", else: "\n\n  "

    build_options(options, [
      spacing,
      doc,
      "option ",
      Macro.inspect_atom(:literal, key),
      ", ",
      iodata_inspect(type),
      build_opts(new_opts)
      | chardata
    ])
  end

  defp build_options([], chardata) do
    chardata
  end

  @spec build_opts(keyword()) :: IO.chardata()
  defp build_opts(opts) do
    for {key, value} <- opts do
      [", ", Macro.inspect_atom(:key, key), " ", iodata_inspect(value)]
    end
  end

  @spec iodata_inspect(term()) :: iodata()
  defp iodata_inspect(term) do
    inspect_opts = Inspect.Opts.new([])

    term
    |> Inspect.Algebra.to_doc(inspect_opts)
    |> Inspect.Algebra.group()
    |> Inspect.Algebra.format(:infinity)
  end

  @spec task_module(String.t()) :: IO.chardata()
  defp task_module(task_name) do
    task_name
    |> String.split(".")
    |> Enum.map_intersperse(?., &Macro.camelize/1)
    |> then(&["Mix.Tasks." | &1])
  end
end
