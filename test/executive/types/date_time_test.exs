defmodule Executive.Types.DateTimeTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.DateTime, as: DateTimeType
  doctest DateTimeType

  describe "name/1" do
    test "datetime" do
      assert DateTimeType.name([]) == "datetime"
    end
  end

  describe "parse/3" do
    test "parses iso 8601" do
      raw = "1234-05-06T07:08:09Z"
      expected = ~U[1234-05-06 07:08:09Z]
      assert DateTimeType.parse([], raw) == {:ok, expected}
    end

    test "resolves offsets" do
      raw = "2024-01-01T01:23:45.678+03:45"
      expected = ~U[2023-12-31 21:38:45.678Z]
      assert DateTimeType.parse([], raw) == {:ok, expected}
    end

    test "error if format invalid" do
      raw = "January 1, 2024 at 12:00 A.M."
      assert DateTimeType.parse([], raw) == :error
    end

    test "error if date invalid" do
      raw = "2023-12-32T00:00:00Z"
      assert DateTimeType.parse([], raw) == {:error, "invalid date"}
    end

    test "error if time invalid" do
      raw = "2023-01-01T24:00:00Z"
      assert DateTimeType.parse([], raw) == {:error, "invalid time"}
    end

    test "error if missing offset" do
      raw = "2023-01-01T00:00:00"
      assert DateTimeType.parse([], raw) == {:error, "missing offset"}
    end
  end

  describe "spec/1" do
    assert DateTimeType.spec([]) == quote(do: DateTime.t())
  end
end
