defmodule Executive.Types.NaiveDateTimeTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.NaiveDateTime, as: NaiveDateTimeType
  doctest NaiveDateTimeType

  describe "name/1" do
    test "datetime" do
      assert NaiveDateTimeType.name([]) == "naive datetime"
    end
  end

  describe "parse/3" do
    test "parses iso 8601" do
      raw = "2024-01-01T12:34:56Z"
      expected = ~N[2024-01-01 12:34:56]
      assert NaiveDateTimeType.parse([], raw) == {:ok, expected}
    end

    test "omits offsets" do
      raw = "2024-01-01T01:23:45.678+02:15"
      expected = ~N[2024-01-01 01:23:45.678]
      assert NaiveDateTimeType.parse([], raw) == {:ok, expected}
    end

    test "error if format invalid" do
      raw = "January 1, 2024 at 11:23 P.M."
      assert NaiveDateTimeType.parse([], raw) == :error
    end

    test "error if date invalid" do
      raw = "2024-00-01T00:00:00Z"
      assert NaiveDateTimeType.parse([], raw) == {:error, "invalid date"}
    end

    test "error if time invalid" do
      raw = "2024-01-23T45:67:89Z"
      assert NaiveDateTimeType.parse([], raw) == {:error, "invalid time"}
    end
  end

  describe "spec/1" do
    assert NaiveDateTimeType.spec([]) == quote(do: NaiveDateTime.t())
  end
end
