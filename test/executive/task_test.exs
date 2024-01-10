defmodule Executive.TaskTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Mix.Tasks.MockTask

  defp module_type(module, name, arity) do
    {:ok, types} = Code.Typespec.fetch_types(module)

    Enum.find_value(types, fn
      {:type, type = {^name, _type, args}} when length(args) == arity ->
        Code.Typespec.type_to_quoted(type)

      {:type, _type} ->
        nil
    end)
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

  describe "with_schema/1" do
    test "allows injecting schema into module" do
      expected_schema =
        Schema.new()
        |> Schema.put_option(:ad_hoc_switch, {:ad_hoc, &MockTask.one_less/1}, alias: :a)
        |> Schema.put_option(:boolean_switch, :boolean, alias: :b)
        |> Schema.put_option(:count_switch, :count, alias: :c)
        |> Schema.put_option(:enum_switch, {:enum, [:alfa, :bravo]}, alias: :e)
        |> Schema.put_option(:float_switch, :float, alias: :f)
        |> Schema.put_option(:integer_switch, :integer, alias: :i)
        |> Schema.put_option(:string_switch, :string, alias: :s)

      assert MockTask.schema() == expected_schema
    end
  end
end
