defmodule Executive.Types.EnumTest do
  use ExUnit.Case, async: true
  alias Executive.Types.Enum, as: EnumType
  doctest EnumType

  describe "name/1" do
    test "enumerates allowed values" do
      name = EnumType.name([:alfa, :bravo, :charlie, :delta])
      assert to_string(name) == "enum (alfa, bravo, charlie, delta)"
    end
  end

  describe "parse/2" do
    test "returns atom value if in list of allowed values" do
      assert EnumType.parse([:alfa, :bravo, :charlie], nil, "bravo") == {:ok, :bravo}
    end

    test "returns error if value not in list of allowed values" do
      assert {:error, message} = EnumType.parse([:alfa, :bravo, :charlie], nil, "delta")
      assert to_string(message) == ~S[Expected one of (alfa, bravo, charlie), got "delta"]
    end
  end

  describe "spec/1" do
    test "union of allowed values" do
      expected = quote(do: :alfa | :bravo | :charlie | :delta | :echo)
      assert EnumType.spec([:alfa, :bravo, :charlie, :delta, :echo]) == expected
    end

    test "empty enums have can never parse a value successfully" do
      assert EnumType.spec([]) == quote(do: none())
    end
  end
end
