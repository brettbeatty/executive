defmodule Executive.SchemaTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Schema.Option

  describe "new/0" do
    test "creates new schema" do
      assert %Schema{} = Schema.new()
    end
  end

  describe "put_option/4" do
    test "puts option into schema" do
      schema = Schema.new()

      assert %Schema{options: %{my_option: option}} =
               Schema.put_option(schema, :my_option, MyType)

      assert %Option{name: :my_option, type: MyType} = option
    end

    test "supports option opts" do
      schema = Schema.new()

      assert %Schema{options: %{my_option: option}} =
               Schema.put_option(schema, :my_option, MyType, alias: :o)

      assert %Option{aliases: [:o]} = option
    end

    test "overwrites options of same name" do
      schema =
        Schema.new()
        |> Schema.put_option(:my_option, AnotherType)
        |> Schema.put_option(:another_option, AnotherType)

      assert %Schema{
               options: %{
                 my_option: %Option{type: AnotherType, type_params: [], aliases: []},
                 another_option: %Option{type: AnotherType}
               }
             } = schema

      assert %Schema{
               options: %{
                 my_option: %Option{type: MyType, type_params: [my: :params], aliases: [:o]},
                 another_option: %Option{type: AnotherType}
               }
             } = Schema.put_option(schema, :my_option, {MyType, my: :params}, alias: :o)
    end
  end
end
