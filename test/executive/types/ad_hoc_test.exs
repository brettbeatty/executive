defmodule Executive.Types.AdHocTest do
  use ExUnit.Case, async: true
  alias Executive.Types.AdHoc, as: AdHocType
  doctest AdHocType

  describe "name/1" do
    test "fun.(:name)" do
      assert AdHocType.name(fn :name -> "my name" end) == "my name"
    end
  end

  describe "parse/2" do
    test "fun.({:parse, raw})" do
      ref = make_ref()
      fun = fn {:parse, "my raw value"} -> {:ok, ref} end
      assert AdHocType.parse(fun, "my raw value") == {:ok, ref}
    end
  end

  describe "raw_type/1" do
    test "fun.(:raw_type)" do
      assert AdHocType.raw_type(fn :raw_type -> :count end) == :count
    end
  end

  describe "spec/1" do
    test "fun.(:spec)" do
      assert AdHocType.spec(fn :spec -> quote(do: atom()) end) == quote(do: atom())
    end
  end
end
