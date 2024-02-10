defmodule Executive.Types.DateTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.Date, as: DateType
  doctest DateType

  describe "name/1" do
    test "datetime" do
      assert DateType.name([]) == "date"
    end
  end

  describe "parse/3" do
    test "parses iso 8601" do
      raw = "2024-01-23"
      expected = ~D[2024-01-23]
      assert DateType.parse([], raw) == {:ok, expected}
    end

    test "error if format invalid" do
      raw = "January 1, 2024"
      assert DateType.parse([], raw) == :error
    end

    test "error if date invalid" do
      raw = "2023-12-32"
      assert DateType.parse([], raw) == {:error, "invalid date"}
    end
  end

  describe "spec/1" do
    assert DateType.spec([]) == quote(do: Date.t())
  end
end
