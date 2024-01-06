defmodule Executive.Schema.OptionTest do
  use ExUnit.Case, async: true
  alias Executive.Schema.Option

  describe "new/3" do
    test "creates new option" do
      assert %Option{name: :my_option, type: MyType, type_params: []} =
               Option.new(:my_option, MyType, [])
    end

    test "supports parametrized types" do
      params = [my: :params]

      assert %Option{type: MyType, type_params: ^params} =
               Option.new(:my_option, {MyType, params}, [])
    end

    test "resolves type aliases" do
      assert %Option{type: Executive.Types.Integer} = Option.new(:my_option, :integer, [])
    end

    test "supports :alias option" do
      assert %Option{aliases: [:o]} = Option.new(:my_option, MyType, alias: :o)
      assert %Option{aliases: [:m, :o]} = Option.new(:my_option, MyType, alias: [:m, :o])
    end
  end
end
