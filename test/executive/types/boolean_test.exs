defmodule Executive.Types.BooleanTest do
  use ExUnit.Case, async: true
  alias Executive.Types.Boolean, as: BooleanType

  describe "name/1" do
    test "boolean" do
      assert BooleanType.name([]) == "boolean"
    end
  end

  describe "parse/2" do
    test "true" do
      assert BooleanType.parse(true, []) == {:ok, true}
    end

    test "false" do
      assert BooleanType.parse(false, []) == {:ok, false}
    end
  end

  describe "raw_type/1" do
    test ":boolean" do
      assert BooleanType.raw_type([]) == :boolean
    end
  end

  describe "spec/1" do
    test "boolean()" do
      assert BooleanType.spec([]) == quote(do: boolean())
    end
  end
end
