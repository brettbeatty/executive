defmodule Executive.Types.IntegerTest do
  use ExUnit.Case, async: true
  alias Executive.Types.Integer, as: IntegerType

  describe "name/1" do
    test "integer" do
      assert IntegerType.name([]) == "integer"
    end
  end

  describe "parse/2" do
    test "parses integer" do
      assert IntegerType.parse([], nil, "12") == {:ok, 12}
    end

    test "error if not an integer" do
      assert IntegerType.parse([], nil, "4.0") == :error
    end
  end

  describe "spec/1" do
    test "integer()" do
      assert IntegerType.spec([]) == quote(do: integer())
    end
  end
end
