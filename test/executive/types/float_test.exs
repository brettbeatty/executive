defmodule Executive.Types.FloatTest do
  use ExUnit.Case, async: true
  alias Executive.Types.Float, as: FloatType

  describe "name/1" do
    test "float" do
      assert FloatType.name([]) == "float"
    end
  end

  describe "parse/2" do
    test "float" do
      assert FloatType.parse([], 0.5) == {:ok, 0.5}
    end
  end

  describe "raw_type/1" do
    test ":float" do
      assert FloatType.raw_type([]) == :float
    end
  end

  describe "spec/1" do
    test "float()" do
      assert FloatType.spec([]) == quote(do: float())
    end
  end
end
