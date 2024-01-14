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
  >     - `with_schema/1`
  >   - set `@behaviour Executive.Task`
  >     - this will expect the module to implement `c:Executive.Task.run/2`

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
  @callback run([String.t()], keyword()) :: any()

  @doc """
  Appends to moduledoc once schema is compiled.

  This macro expects a string interpolating values where the schema is available
  as `&1` (like the shorthand for an anonymous 1-arity function).

      moduledoc_append \"""
      ## Basic Options

      \#{Executive.Schema.option_docs(&1, only: [:add, :subtract])}

      ## Advanced Options

      \#{Executive.Schema.option_docs(&1, only: [:multiply, :divide])}

      \"""

  """
  defmacro moduledoc_append(addendum) do
    quote do
      with_schema(fn schema ->
        addendum = (&unquote(addendum)).(schema)

        quote do
          @moduledoc @moduledoc <> unquote(addendum)
        end
      end)
    end
  end

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
  Builds a type named `name` from schema options.

      option :my_enum, {:enum, [:lite, :basic, :premier]}
      option :my_string, :string
      option :my_uuid, :uuid

      option_type option()
      # Equivalent:
      # @type option() ::
      #         {:my_enum, :lite | :basic | :premier}
      #         | {:my_string, String.t()}
      #         | {:my_uuid, <<_::288>>}

  Supports options `:only` and `:except`.

      option :my_boolean, :boolean
      option :my_float, :float
      option :my_integer, :integer

      option_type option(), except: [:my_integer]
      # Equivalent:
      # @type option() :: {:my_boolean, boolean()} | {:my_float, float()}

  See `Executive.Schema.option_typespec/2`.
  """
  defmacro option_type(name, opts \\ []) do
    build_option_type(:option_typespec, name, opts)
  end

  @doc """
  Builds a type named `name` from schema options.

      option :my_float, :float
      option :my_integer, :integer
      option :my_uuid, :uuid

      option_type options()
      # Equivalent:
      # @type options() :: [
      #         my_float: float(),
      #         my_integer: integer(),
      #         my_uuid: <<_::288>>
      #       ]

  Supports options `:only` and `:except`.

      option :my_boolean, :boolean
      option :my_enum, {:enum, [:enabled, :disabled]}
      option :my_string, :string

      option_type options(), only: [:my_enum, :my_string]
      # Equivalent:
      # @type options() :: [
      #         my_enum: :enabled | :disabled,
      #         my_string: String.t()
      #       ]

  See `Executive.Schema.options_typespec/2`.
  """
  defmacro options_type(name, opts \\ []) do
    build_option_type(:options_typespec, name, opts)
  end

  @spec build_option_type(:option_typespec | :options_typespec, Macro.t(), Schema.option_filter()) ::
          Macro.t()
  defp build_option_type(fun, name, opts) do
    quote do
      with_schema(fn schema ->
        name = unquote(Macro.escape(name))
        typespec = Executive.Schema.unquote(fun)(schema, unquote(opts))

        quote do
          @type unquote(name) :: unquote(typespec)
        end
      end)
    end
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

  @spec _run(t(), Schema.t(), [String.t()]) :: any()
  def _run(module, schema, argv) do
    {argv, opts} = Schema.parse!(schema, argv)
    module.run(argv, opts)
  end

  defmacro __before_compile__(env) do
    schema_ast = build_schema(env.module)
    {schema, _binding} = Module.eval_quoted(env, schema_ast)
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

  @spec build_schema(t()) :: Macro.t()
  defp build_schema(module) do
    options = Module.get_attribute(module, :executive_task_option, [])

    schema =
      quote do
        Executive.Schema.new()
      end

    Enum.reduce(options, schema, fn {name, type, opts}, schema ->
      quote do
        Executive.Schema.put_option(unquote(schema), unquote(name), unquote(type), unquote(opts))
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

      import Executive.Task,
        only: [
          moduledoc_append: 1,
          option: 2,
          option: 3,
          option_type: 1,
          option_type: 2,
          options_type: 1,
          options_type: 2,
          with_schema: 1,
          with_schema: 2
        ]

      @before_compile Executive.Task
      @behaviour Executive.Task

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
