defmodule Executive.TaskTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Mix.Tasks.MockTask

  defp module_doc(module) do
    {:docs_v1, _annotation, :elixir, _format, %{"en" => module_doc}, _metadata, _docs} =
      Code.fetch_docs(module)

    module_doc
  end

  defp module_type(module, name, arity) do
    {:ok, types} = Code.Typespec.fetch_types(module)

    Enum.find_value(types, fn
      {:type, type = {^name, _type, args}} when length(args) == arity ->
        Code.Typespec.type_to_quoted(type)

      {:type, _type} ->
        nil
    end)
  end

  describe ":start_application opt" do
    defmodule StartsApplication do
      use Executive.Task, start_application: true

      @impl Executive.Task
      def run(_argv, _opts), do: :ok
    end

    defmodule DoesNotStartApplication do
      use Executive.Task

      @impl Executive.Task
      def run(_argv, _opts), do: :ok
    end

    test "when start_application: true runs mix app.start" do
      StartsApplication.run([])
      assert_received :application_started
    end

    test "when start_application: false does not run mix app.start" do
      DoesNotStartApplication.run([])
      refute_received :application_started
    end
  end

  describe "option_docs/1 + hook" do
    test "builds docs for options" do
      expected = """
      This is a task that does something.

      ## Usage

          mix mock_task [OPTIONS]

      ## Cool Options

        - `--enum-switch`, `-e` - enum (alfa, bravo) - behaves differently based on alfa vs bravo

      ## Useful Options

        - `--string-switch`, `-s` - string - some sort of silly string
        - `--integer-switch`, `-i` - integer - any integer will do
        - `--boolean-switch`, `--no-boolean-switch`, `-b` - boolean - something about the boolean switch

      ## I'm Not Sure These Will Get Used

        - `--float-switch`, `-f` - float - not a whole number

      ## All Options

        - `--base64-switch` - base 64 string - a base64-encoded binary
        - `--boolean-switch`, `--no-boolean-switch`, `-b` - boolean - something about the boolean switch
        - `--enum-switch`, `-e` - enum (alfa, bravo) - behaves differently based on alfa vs bravo
        - `--float-switch`, `-f` - float - not a whole number
        - `--integer-switch`, `-i` - integer - any integer will do
        - `--string-switch`, `-s` - string - some sort of silly string

      """

      assert module_doc(MockTask) == expected
    end
  end

  describe "option/3" do
    test "parses options" do
      argv = [
        "--no-boolean-switch",
        "--float-switch",
        "0.1",
        "--integer-switch",
        "10",
        "--string-switch",
        "my string",
        "some args",
        "that won't",
        "end up as opts"
      ]

      expected_argv = ["some args", "that won't", "end up as opts"]

      expected_opts = [
        boolean_switch: false,
        float_switch: 0.1,
        integer_switch: 10,
        string_switch: "my string"
      ]

      assert MockTask.run(argv) == {expected_argv, expected_opts}
    end

    test "parsing fails if options not correct type" do
      argv = [
        "--float-switch",
        "half",
        "--integer-switch",
        "4.0",
        "--string-switch",
        "--unknown-switch",
        "additional",
        "args"
      ]

      expected_message =
        String.trim("""
        4 errors found!
        --float-switch : Expected type float, got "half"
        --integer-switch : Expected type integer, got "4.0"
        --string-switch : Missing argument of type string
        --unknown-switch : Unknown option
        """)

      assert_raise Executive.ParseError, expected_message, fn ->
        MockTask.run(argv)
      end
    end

    test "parsing fails if validations don't pass" do
      argv = ["--float-switch", "-1.0", "--base64-switch", "bXkgc3RyaW5n"]

      expected_message =
        String.trim("""
        2 errors found!
        --float-switch : Value -1.0 failed validation Mix.Tasks.MockTask.validate_positive/1
        --base64-switch : Expected exactly 8 decoded bytes
        """)

      assert_raise Executive.ParseError, expected_message, fn ->
        MockTask.run(argv)
      end
    end
  end

  describe "option type hook" do
    test "builds type for option" do
      actual_type = module_type(MockTask, :option, 0)

      expected_type =
        quote do
          option() ::
            {:boolean_switch, boolean()}
            | {:enum_switch, :alfa | :bravo}
            | {:string_switch, String.t()}
        end

      assert Macro.to_string(actual_type) == Macro.to_string(expected_type)
    end
  end

  describe "options type hook" do
    test "builds type for options" do
      actual_type = module_type(MockTask, :options, 0)

      expected_type =
        quote do
          options() :: [
            base64_switch: binary(),
            boolean_switch: boolean(),
            enum_switch: :alfa | :bravo,
            float_switch: float(),
            integer_switch: integer(),
            string_switch: String.t()
          ]
        end

      assert Macro.to_string(actual_type) == Macro.to_string(expected_type)
    end
  end

  describe "start_application/0" do
    test "starts application using mix app.start" do
      Executive.Task.start_application()
      assert_received :application_started
    end
  end

  describe "with_schema/1" do
    test "allows operations on actual schema" do
      expected_options = [
        :base64_switch,
        :boolean_switch,
        :enum_switch,
        :float_switch,
        :integer_switch,
        :string_switch
      ]

      assert MockTask.options() == expected_options
    end
  end

  describe "with_schema/2" do
    test "allows injecting schema into module" do
      expected_schema =
        Schema.new()
        |> Schema.put_option(:base64_switch, :base64, doc: "a base64-encoded binary")
        |> Schema.put_option(:boolean_switch, :boolean,
          alias: :b,
          doc: "something about the boolean switch"
        )
        |> Schema.put_option(:enum_switch, {:enum, [:alfa, :bravo]},
          alias: :e,
          doc: "behaves differently based on alfa vs bravo"
        )
        |> Schema.put_option(:float_switch, :float, alias: :f, doc: "not a whole number")
        |> Schema.put_option(:integer_switch, :integer, alias: :i, doc: "any integer will do")
        |> Schema.put_option(:string_switch, :string, alias: :s, doc: "some sort of silly string")

      assert MockTask.schema() == expected_schema
    end
  end
end
