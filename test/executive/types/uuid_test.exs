defmodule Executive.Types.UUIDTest do
  use ExUnit.Case, async: true
  alias Executive.Types.UUID, as: UUIDType
  doctest UUIDType

  describe "name/1" do
    test "UUID" do
      assert UUIDType.name([]) == "UUID"
    end
  end

  describe "parse/2" do
    test "returns as is if format matches" do
      uuid = "87a4c922-9728-4f93-bfd2-1d9c52873725"
      assert UUIDType.parse([], nil, uuid) == {:ok, uuid}
    end

    test "returns error if format does not match" do
      assert UUIDType.parse([], nil, "afad1dfb") == :error
    end
  end

  describe "raw_type/1" do
    test "string" do
      assert UUIDType.raw_type([]) == :string
    end
  end

  describe "spec/1" do
    test "<<_::288>>" do
      spec = UUIDType.spec([])
      assert Macro.to_string(spec) == "<<_::288>>"
    end
  end
end
