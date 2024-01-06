defmodule Executive.ParseErrorTest do
  use ExUnit.Case, async: true
  alias Executive.ParseError

  describe "exception/1" do
    test "creates a new error" do
      switch_errors = [{"--my-switch", ["something", " went horribly wrong"]}]
      assert %ParseError{switch_errors: ^switch_errors} = ParseError.exception(switch_errors)
    end
  end

  describe "message/1" do
    test "handles one switch error" do
      error = ParseError.exception([{"--my-switch", ["Missing argument of type ", "integer"]}])

      expected_message =
        String.trim("""
        1 error found!
        --my-switch : Missing argument of type integer
        """)

      assert ParseError.message(error) == expected_message
    end

    test "handles multiple switch errors" do
      error =
        ParseError.exception([
          {"--my-switch", ["Expected argument of type ", "float", ", got ", ~S("some string")]},
          {"--another-switch", ["Missing argument of type ", "string"]},
          {"--one-more-switch", "Unknown option"}
        ])

      expected_message =
        String.trim("""
        3 errors found!
        --my-switch : Expected argument of type float, got "some string"
        --another-switch : Missing argument of type string
        --one-more-switch : Unknown option
        """)

      assert ParseError.message(error) == expected_message
    end
  end
end
