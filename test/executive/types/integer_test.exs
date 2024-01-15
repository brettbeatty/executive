defmodule Executive.Types.IntegerTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.Integer, as: IntegerType
  doctest IntegerType

  describe "name/1" do
    test "integer" do
      name = IntegerType.name([])
      assert name == "integer"
    end

    test "negative integer" do
      name = IntegerType.name(max: -1)
      assert name == "negative integer"
    end

    test "non-negative integer" do
      name = IntegerType.name(min: 0)
      assert name == "non-negative integer"
    end

    test "positive integer" do
      name = IntegerType.name(min: 1)
      assert name == "positive integer"
    end

    test "integer at least min" do
      name = IntegerType.name(min: 5)
      assert to_string(name) == "integer at least 5"
    end

    test "integer at most max" do
      name = IntegerType.name(max: -7)
      assert to_string(name) == "integer at most -7"
    end

    test "integer between min and max" do
      name = IntegerType.name(min: -3, max: 6)
      assert to_string(name) == "integer between -3 and 6"
    end

    test "range" do
      name = IntegerType.name(-4..-1)
      assert to_string(name) == "integer between -4 and -1"
    end
  end

  describe "parse/2" do
    test "parses integer" do
      assert IntegerType.parse([], nil, "12") == {:ok, 12}
    end

    test "accepts integer > min" do
      assert IntegerType.parse([min: 1], nil, "2") == {:ok, 2}
    end

    test "accepts integer = min" do
      assert IntegerType.parse([min: 0], nil, "0") == {:ok, 0}
    end

    test "error if integer < min" do
      assert IntegerType.parse([min: -1], nil, "-2") == :error
    end

    test "accepts integer < max" do
      assert IntegerType.parse([max: 2], nil, "1") == {:ok, 1}
    end

    test "accepts integer = max" do
      assert IntegerType.parse([max: -3], nil, "-3") == {:ok, -3}
    end

    test "error if integer > max" do
      assert IntegerType.parse([max: -1], nil, "0") == :error
    end

    test "error if integer < min < max" do
      assert IntegerType.parse([min: 0, max: 1], nil, "-1") == :error
    end

    test "accepts min = integer < max" do
      assert IntegerType.parse([min: 2, max: 4], nil, "2") == {:ok, 2}
    end

    test "accepts min < integer < max" do
      assert IntegerType.parse([min: -1, max: 1], nil, "0") == {:ok, 0}
    end

    test "accepts min < integer = max" do
      assert IntegerType.parse([min: -2, max: 3], nil, "3") == {:ok, 3}
    end

    test "error if min < max < integer" do
      assert IntegerType.parse([min: -3, max: 5], nil, "6") == :error
    end

    test "error if integer < min < max from range" do
      assert IntegerType.parse(-6..6, nil, "-7") == :error
    end

    test "accepts min = integer < max from range" do
      assert IntegerType.parse(-4..8, nil, "-4") == {:ok, -4}
    end

    test "accepts min < integer < max from range" do
      assert IntegerType.parse(19..23, nil, "20") == {:ok, 20}
    end

    test "accepts min < integer = max from range" do
      assert IntegerType.parse(-15..42, nil, "42") == {:ok, 42}
    end

    test "error if min < max < integer from range" do
      assert IntegerType.parse(16..23, nil, "25") == :error
    end
  end

  describe "spec/1" do
    test "integer()" do
      spec = IntegerType.spec([])
      assert Macro.to_string(spec) == "integer()"
    end

    test "neg_integer()" do
      spec = IntegerType.spec(max: -1)
      assert Macro.to_string(spec) == "neg_integer()"
    end

    test "non_neg_integer()" do
      spec = IntegerType.spec(min: 0)
      assert Macro.to_string(spec) == "non_neg_integer()"
    end

    test "pos_integer()" do
      spec = IntegerType.spec(min: 1)
      assert Macro.to_string(spec) == "pos_integer()"
    end

    test "min..max" do
      spec = IntegerType.spec(min: 2, max: 4)
      assert Macro.to_string(spec) == "2..4"
    end

    test "range" do
      spec = IntegerType.spec(-2..3)
      assert Macro.to_string(spec) == "-2..3"
    end
  end
end
