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

  describe "moduledoc_append/2" do
    test "builds docs for options" do
      expected = """
      This is a task that does something.

      ## Usage

          mix mock_task [OPTIONS]

      ## Cool Options

        - `--enum-switch` (`-e`) - enum (alfa, bravo) - behaves differently based on alfa vs bravo

      ## Useful Options

        - `--string-switch` (`-s`) - string - some sort of silly string
        - `--integer-switch` (`-i`) - integer - any integer will do
        - `--boolean-switch` (`-b`) - boolean - something about the boolean switch

      ## I'm Not Sure These Will Get Used

        - `--count-switch` (`-c`) - count - counts stuff
        - `--float-switch` (`-f`) - float - not a whole number

      """

      assert module_doc(MockTask) == expected
    end
  end

  describe "option/3" do
    test "parses options" do
      argv = [
        "--ad-hoc-switch",
        "16",
        "--no-boolean-switch",
        "--count-switch",
        "--count-switch",
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
        # count switches seem to always end up first the in the list
        count_switch: 2,
        ad_hoc_switch: 15,
        boolean_switch: false,
        float_switch: 0.1,
        integer_switch: 10,
        string_switch: "my string"
      ]

      assert MockTask.run(argv) == {expected_argv, expected_opts}
    end

    test "fails if options invalid" do
      argv = [
        "--ad-hoc-switch",
        "zero",
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
        5 errors found!
        --ad-hoc-switch : Expected type one less, got "zero"
        --float-switch : Expected type float, got "half"
        --integer-switch : Expected type integer, got "4.0"
        --string-switch : Missing argument of type string
        --unknown-switch : Unknown option
        """)

      assert_raise Executive.ParseError, expected_message, fn ->
        MockTask.run(argv)
      end
    end
  end

  describe "option_type/2" do
    test "builds type for option" do
      actual_type = module_type(MockTask, :option, 0)

      expected_type =
        quote do
          option() ::
            {:boolean_switch, boolean()}
            | {:count_switch, pos_integer()}
            | {:enum_switch, :alfa | :bravo}
            | {:string_switch, String.t()}
        end

      assert Macro.to_string(actual_type) == Macro.to_string(expected_type)
    end
  end

  describe "options_type/2" do
    test "builds type for options" do
      actual_type = module_type(MockTask, :options, 0)

      expected_type =
        quote do
          options() :: [
            boolean_switch: boolean(),
            count_switch: pos_integer(),
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
    test "allows injecting schema into module" do
      expected_schema =
        Schema.new()
        |> Schema.put_option(:ad_hoc_switch, {:ad_hoc, &MockTask.one_less/1},
          alias: :a,
          doc: "we can't build docs for ad hoc"
        )
        |> Schema.put_option(:boolean_switch, :boolean,
          alias: :b,
          doc: "something about the boolean switch"
        )
        |> Schema.put_option(:count_switch, :count, alias: :c, doc: "counts stuff")
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
