defmodule Executive.Task do
  @moduledoc """
  `Executive.Task` aims to accelerate mix task development.

  It builds on `Mix.Task` and provides a few niceties, such as more powerful
  option parsing.

  > #### `use Executive.Task` {: .info}
  >
  > When you `use Executive.Task`, it does a few things:
  >
  >   - `use Mix.Task` and implement `c:Mix.Task.run/1`
  >   - import the `Executive.Task` domain-specific language
  >     - `option/2` and `option/3`
  >     - `option_type/1` and `option_type/2`
  >     - `options_type/1` and `options_type/2`
  >     - `with_schema/1` and `with_schema/2`
  >   - set `@behaviour Executive.Task`
  >     - this will expect the module to implement `c:Executive.Task.run/2`
  >   - replaces in `@moduledoc` any calls to `option_docs/1`

  Mix tasks built on `Executive.Task` implement `c:Executive.Task.run/2` instead
  of `c:Mix.Task.run/1`.

      defmodule Mix.Tasks.MyTask do
        use Executive.Task, start_application: true

        option :action, {:enum, [:start, :stop]}, alias: :a
        option :id, MyApp.ExecutiveTypes.ID

        @impl Executive.Task
        def run(argv, opts) do
          action = Keyword.get(opts, :action, :start)
          id = Keyword.get(opts, :id)

          MyApp.MyService.do_something(action, id, argv)
        end
      end

  ## Options

    - `:start_application` - when true, application is started automatically

          use Executive.Task, start_application: true

  """
  alias Executive.Schema

  @typedoc """
  Intended to represent modules implementing the `Executive.Task` behaviour.
  """
  @type t() :: module()

  @doc """
  Tasks built with `Executive.Task` implement this instead of `c:Mix.Task.run/1`.
  """
  @callback run(argv :: [String.t()], opts :: keyword()) :: any()

  @doc """
  Puts an option into task's schema.

  See `Executive.Schema.put_option/4`.
  """
  defmacro option(name, type, opts \\ []) do
    quote do
      Executive.Task._put_option(
        __MODULE__,
        unquote(Macro.escape(name)),
        unquote(Macro.escape(type)),
        unquote(Macro.escape(opts))
      )
    end
  end

  @doc """
  Injects option documentation into module documentation.

  Since the options are not typically compiled before the moduledoc, this
  function actually generates a string that gets replaced by documentation once
  all options have been compiled. Moduledocs in modules with a `use
  Executive.Task` are the only place this value will be replaced.

  By default all options are documented.

      @moduledoc \"""
      Description of my task.

      ## Command line options

      \#{Executive.Task.option_docs()}

      \"""

  This can also be broken out with the `:only` or `:except` options.

      @moduledoc \"""
      Description of my task.

      ## Basic options

      \#{Executive.Task.option_docs(only: [:add, :subtract])}

      ## Advanced options

      \#{Executive.Task.option_docs(only: [:multiply, :divide])}

      ## Other options

      \#{Executive.Task.option_docs(except: [:add, :subtract, :multiply, :divide])}

      \"""

  """
  @spec option_docs(Schema.option_filter()) :: IO.chardata()
  def option_docs(names \\ []) do
    ["EXECUTIVE_OPTION_DOCS{", names |> :erlang.term_to_binary() |> Base.encode64(), "}"]
  end

  @mix_task Application.compile_env(:executive, Mix.Task, Mix.Task)

  @doc """
  Starts application using "mix app.start".

  This function is available to mix tasks that need to perform some setup before
  starting an OTP application. Mix tasks that do not need to set anything up can
  opt instead to pass `start_application: true` to `use Executive.Task`.

      iex> Executive.Task.start_application()
      :ok

  """
  @spec start_application() :: :ok
  def start_application do
    @mix_task.run("app.start")
    :ok
  end

  @doc """
  Create a hook for adding code to a module after schema has been built.

  Takes a function to be called with the schema. This function returns quoted
  code to be injected in the module.

      with_schema fn schema ->
        typespec = Executive.Schema.options_typespec(schema)

        quote do
          @type options() :: unquote(typespec)
        end
      end

  Values injected through unquote must be valid quoted expressions. The default
  `:value` mode works well for gathering data from the schema and building code
  with it. For injecting the schema itself, the `:ast` mode instead gives `fun`
  a quoted schema.

      with_schema :ast, fn schema ->
        quote do
          def schema do
            unquote(schema)
          end
        end
      end

  When `mode = :value` schemas given to `fun` will not have any option
  validations--this allows tasks to validate options with functions defined in
  the task (which will not have compiled when hooks are called).
  """
  defmacro with_schema(mode \\ :value, fun) do
    {fun, _binding} = Module.eval_quoted(__CALLER__, fun)
    :ok = Module.put_attribute(__CALLER__.module, :executive_task_with_schema, {mode, fun})
  end

  @spec _put_option(module(), Macro.t(), Macro.t(), keyword()) :: :ok
  def _put_option(module, name, type, opts) do
    opts =
      case Module.get_attribute(module, :optdoc) do
        doc when is_binary(doc) ->
          Keyword.put(opts, :doc, doc)

        nil ->
          opts
      end

    Module.delete_attribute(module, :optdoc)
    Module.put_attribute(module, :executive_task_option, {name, type, opts})
  end

  @spec _replace_option_docs(String.t(), Schema.t()) :: String.t()
  def _replace_option_docs(doc, schema) do
    Regex.replace(~R/EXECUTIVE_OPTION_DOCS{([a-zA-Z0-9+\/]+={0,3})}/, doc, fn _full, opts ->
      opts
      |> Base.decode64!()
      |> :erlang.binary_to_term()
      |> then(&Schema.option_docs(schema, &1))
    end)
  end

  @spec _run(t(), Schema.t(), [String.t()]) :: any()
  def _run(module, schema, argv) do
    {argv, opts} = Schema.parse!(schema, argv)
    module.run(argv, opts)
  end

  defmacro __before_compile__(env) do
    schema_ast = build_schema(env.module, _include_validations? = true)

    {schema, _binding} =
      env.module
      |> build_schema(_include_validations? = false)
      |> then(&Module.eval_quoted(env, &1))

    hooks = env.module |> Module.get_attribute(:executive_task_with_schema, []) |> Enum.reverse()

    blocks =
      for {type, fun} <- hooks do
        case type do
          :value -> fun.(schema)
          :ast -> fun.(schema_ast)
        end
      end

    quote do
      unquote_splicing(blocks)
      :ok
    end
  end

  @spec build_schema(t(), boolean()) :: Macro.t()
  defp build_schema(module, include_validations?) do
    options = Module.get_attribute(module, :executive_task_option, [])

    schema =
      quote do
        Executive.Schema.new()
      end

    Enum.reduce(options, schema, fn {name, type, opts}, schema ->
      new_opts =
        if include_validations? do
          opts
        else
          Keyword.delete(opts, :validate)
        end

      quote do
        Executive.Schema.put_option(
          unquote(schema),
          unquote(name),
          unquote(type),
          unquote(new_opts)
        )
      end
    end)
  end

  defmacro __using__(opts) do
    Module.register_attribute(__CALLER__.module, :executive_task_option, accumulate: true)
    Module.register_attribute(__CALLER__.module, :executive_task_with_schema, accumulate: true)

    setup =
      if Keyword.get(opts, :start_application, false) do
        quote do
          Executive.Task.start_application()
        end
      else
        :ok
      end

    quote do
      use Mix.Task
      import Executive.Task, only: [option: 2, option: 3, with_schema: 1, with_schema: 2]
      @before_compile Executive.Task
      @behaviour Executive.Task

      with_schema fn schema ->
        if doc = @moduledoc do
          quote do
            @moduledoc unquote(Executive.Task._replace_option_docs(doc, schema))
          end
        end
      end

      with_schema :ast, fn schema ->
        setup = unquote(Macro.escape(setup))

        quote do
          @impl Mix.Task
          def run(argv) do
            unquote(setup)
            Executive.Task._run(__MODULE__, unquote(schema), argv)
          end
        end
      end
    end
  end
end
