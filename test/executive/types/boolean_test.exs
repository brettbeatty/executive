defmodule Executive.Types.BooleanTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.Boolean, as: BooleanType
  doctest BooleanType

  describe "capture?/2" do
    test "false for truthy switches" do
      assert BooleanType.capture?([], true) == false
    end

    test "true for falsy switches" do
      assert BooleanType.capture?([], false) == false
    end
  end

  describe "name/1" do
    test "boolean" do
      assert BooleanType.name([]) == "boolean"
    end
  end

  describe "parse/2" do
    test "true" do
      assert BooleanType.parse([], true, nil) == {:ok, true}
    end

    test "false" do
      assert BooleanType.parse([], false, nil) == {:ok, false}
    end
  end

  describe "spec/1" do
    test "boolean()" do
      assert BooleanType.spec([]) == quote(do: boolean())
    end
  end

  describe "switches/3" do
    test "includes negation switch" do
      expected_switches = [
        {"--my-switch", true},
        {"--no-my-switch", false},
        {"-s", true},
        {"-t", true}
      ]

      assert BooleanType.switches([], :my_switch, [:s, :t]) == expected_switches
    end
  end
end
