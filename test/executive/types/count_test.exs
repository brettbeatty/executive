defmodule Executive.Types.CountTest do
  use ExUnit.Case, async: true
  alias Executive.Types.Count, as: CountType

  describe "name/1" do
    test "count" do
      assert CountType.name([]) == "count"
    end
  end

  describe "parse/2" do
    test "positive integer" do
      assert CountType.parse([], 3) == {:ok, 3}
    end
  end

  describe "raw_type/1" do
    test ":count" do
      assert CountType.raw_type([]) == :count
    end
  end

  describe "spec/1" do
    test "pos_integer()" do
      assert CountType.spec([]) == quote(do: pos_integer())
    end
  end
end
