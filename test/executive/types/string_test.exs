defmodule Executive.Types.StringTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.String, as: StringType
  doctest StringType

  describe "name/1" do
    test "string" do
      assert StringType.name([]) == "string"
    end
  end

  describe "parse/2" do
    test "string" do
      assert StringType.parse([], "my string") == {:ok, "my string"}
    end
  end

  describe "spec/1" do
    test "string()" do
      assert StringType.spec([]) == quote(do: String.t())
    end
  end
end
