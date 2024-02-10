defmodule Executive.Types.BooleanTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.Boolean, as: BooleanType
  doctest BooleanType

  describe "name/1" do
    test "boolean" do
      assert BooleanType.name([]) == "boolean"
    end
  end

  describe "spec/1" do
    test "boolean()" do
      assert BooleanType.spec([]) == quote(do: boolean())
    end
  end
end
