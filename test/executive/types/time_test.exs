defmodule Executive.Types.TimeTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.Time, as: TimeType
  doctest TimeType

  describe "name/1" do
    test "datetime" do
      assert TimeType.name([]) == "time"
    end
  end

  describe "parse/3" do
    test "parses iso 8601" do
      raw = "12:34:56.789"
      expected = ~T[12:34:56.789]
      assert TimeType.parse([], nil, raw) == {:ok, expected}
    end

    test "error if format invalid" do
      raw = "12:34 P.M."
      assert TimeType.parse([], nil, raw) == :error
    end

    test "error if time invalid" do
      raw = "23:45:67"
      assert TimeType.parse([], nil, raw) == {:error, "invalid time"}
    end
  end

  describe "spec/1" do
    assert TimeType.spec([]) == quote(do: Time.t())
  end
end
