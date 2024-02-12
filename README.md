# Executive

Executive accelerates mix task development.

## Executive tasks

The primary offering in Executive is the `Executive.Task` module. It provides a domain-specific language for declaring options that can be passed to the mix task.

```elixir
defmodule Mix.Tasks.Something.Do do
  use Executive.Task

  option :id, :uuid
  option :timeout, :integer

  @impl Executive.Task
  def run(argv, opts) do
    MyApp.do_something(argv, opts)
  end
end
```

See the `Executive.Task` docs for more information about available features.

## mix executive.gen.task

Writing tasks by hand can be tedious, so Executive provides a mix task to generate new tasks.

Options are passed using switches for their respective type aliases.

```
mix executive.gen.task some_other_thing.do --string message --no-unique --alias m --string cursor --required --doc "where to start" --integer limit
```

The above mix task would generate a task that would look something like this:

```elixir
# in lib/mix/tasks/some_other_thing.do.ex
defmodule Mix.Tasks.SomeOtherThing.Do do
  @shortdoc "TODO Describe this task in one line"
  @moduledoc """
  TODO Describe what this task does

      $ mix some_other_thing.do

  ## Command line options

  #{Executive.Task.option_docs()}

  """
  use Executive.Task

  option_type option()
  options_type options()

  option :message, :string, unique: false, alias: :m

  @optdoc "where to start"
  option :cursor, :string, required: true
  option :limit, :integer

  @impl Executive.Task
  def run(argv, opts) do
    # TODO implement this task
  end
end
```

See the `mix executive.gen.task` docs for more information.

## Executive types

Executive parses options using modules that implement the `Executive.Type` behaviour. It provides a number of built-in options as well as some aliases to make them easier to reference, but custom types can be built just by implementing the behaviour. A list of available built-in types and their aliases is available in the docs for `t:Executive.Type.alias/0`.
