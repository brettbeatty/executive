defmodule Executive.Task do
  @moduledoc ~S"""
  `Executive.Task` aims to accelerate mix task development.

  It builds on `Mix.Task` and provides a few niceties, such as more powerful
  option parsing.

  > #### `use Executive.Task` {: .info}
  >
  > When you `use Executive.Task`, it does a few things:
  >
  >   - `use Mix.Task` and implement `c:Mix.Task.run/1`
  >   - import `option/2` and `option/3`
  >     - these are powered by a module attribute and `@before_compile` hook
  >   - set `@behaviour Executive.Task`
  >     - this will expect the module to implement `c:Executive.Task.run/2`

  Mix tasks built on `Executive.Task` implement `c:Executive.Task.run/2` instead
  of `c:Mix.Task.run/1`.

      defmodule Mix.Tasks.MyTask do
        use Executive.Task

        option :action, {:enum, [:start, :stop]}, alias: :a
        option :id, MyApp.ExecutiveTypes.ID

        @impl Executive.Task
        def run(argv, opts) do
          Mix.Task.run("app.start")

          action = Keyword.get(opts, :action, :start)
          id = Keyword.get(opts, :id)

          MyApp.MyService.do_something(action, id, argv)
        end
      end

  """
  alias Executive.Schema
  alias Executive.Schema.Option

  @typedoc """
  Intended to represent modules implementing the `Executive.Task` behaviour.
  """
  @type t() :: module()

  @doc """
  Tasks built with `Executive.Task` implement this instead of `c:Mix.Task.run/1`.
  """
  @callback run([String.t()], keyword()) :: any()

  @doc """
  Puts an option into task's schema.

  See `Executive.Schema.put_option/4`.
  """
  @spec option(atom(), Option.type(), Option.opts()) :: :ok
  defmacro option(name, type, opts \\ []) do
    :ok = Module.put_attribute(__CALLER__.module, :executive_task_option, {name, type, opts})
  end

  @spec _run(t(), Schema.t(), [String.t()]) :: any()
  def _run(module, schema, argv) do
    {argv, opts} = Schema.parse!(schema, argv)
    module.run(argv, opts)
  end

  defmacro __before_compile__(env) do
    schema = build_schema(env.module)

    quote do
      @impl Mix.Task
      def run(argv) do
        Executive.Task._run(__MODULE__, unquote(Macro.escape(schema)), argv)
      end
    end
  end

  @spec build_schema(t()) :: Schema.t()
  defp build_schema(module) do
    options = Module.get_attribute(module, :executive_task_option, [])

    Enum.reduce(options, Schema.new(), fn {name, type, opts}, schema ->
      Schema.put_option(schema, name, type, opts)
    end)
  end

  defmacro __using__(_opts) do
    Module.register_attribute(__CALLER__.module, :executive_task_option, accumulate: true)

    quote do
      use Mix.Task
      import Executive.Task, only: [option: 2, option: 3]

      @before_compile Executive.Task
      @behaviour Executive.Task
    end
  end
end
