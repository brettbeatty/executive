defmodule Executive.Types.FloatTest do
  use ExUnit.Case, async: true
  alias Executive.Types.Float, as: FloatType

  describe "name/1" do
    test "float" do
      assert FloatType.name([]) == "float"
    end
  end

  describe "parse/2" do
    test "parses float" do
      assert FloatType.parse([], nil, "0.5") == {:ok, 0.5}
    end

    test "error if not a float" do
      assert FloatType.parse([], nil, "5x") == :error
    end
  end

  describe "spec/1" do
    test "float()" do
      assert FloatType.spec([]) == quote(do: float())
    end
  end
end
