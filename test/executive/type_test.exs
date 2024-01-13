defmodule Executive.TypeTest do
  use ExUnit.Case, async: true
  alias Executive.Type

  describe "unalias/2" do
    test "alias :boolean" do
      params = make_ref()
      assert Type.unalias(:boolean, params) == {Executive.Types.Boolean, params}
    end

    test "alias :enum" do
      params = make_ref()
      assert Type.unalias(:enum, params) == {Executive.Types.Enum, params}
    end

    test "alias :float" do
      params = make_ref()
      assert Type.unalias(:float, params) == {Executive.Types.Float, params}
    end

    test "alias :integer" do
      params = make_ref()
      assert Type.unalias(:integer, params) == {Executive.Types.Integer, params}
    end

    test "alias :string" do
      params = make_ref()
      assert Type.unalias(:string, params) == {Executive.Types.String, params}
    end

    test "alias :uuid" do
      params = make_ref()
      assert Type.unalias(:uuid, params) == {Executive.Types.UUID, params}
    end

    test "module names" do
      params = make_ref()
      assert Type.unalias(MyType, params) == {MyType, params}
    end
  end
end
