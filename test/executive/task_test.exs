defmodule Executive.TaskTask do
  use ExUnit.Case, async: true

  defmodule MockTask do
    use Executive.Task

    option :boolean_switch, :boolean, alias: :b
    option :count_switch, :count, alias: :c
    option :enum_switch, {:enum, [:alfa, :bravo]}, alias: :e
    option :float_switch, :float, alias: :f
    option :integer_switch, :integer, alias: :i
    option :string_switch, :string, alias: :s

    @impl Executive.Task
    def run(argv, opts) do
      {argv, opts}
    end
  end

  describe "option parsing" do
    test "parses options" do
      argv = [
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
        boolean_switch: false,
        float_switch: 0.1,
        integer_switch: 10,
        string_switch: "my string"
      ]

      assert MockTask.run(argv) == {expected_argv, expected_opts}
    end

    test "fails if options invalid" do
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
  end
end
