defmodule Executive.SchemaTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Schema.Option

  describe "new/0" do
    test "creates new schema" do
      assert %Schema{} = Schema.new()
    end
  end

  describe "parse/2" do
    test "handles boolean switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :boolean)
        |> Schema.parse(["--my-option"])

      assert result == {:ok, [], my_option: true}
    end

    test "handles negated boolean switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :boolean)
        |> Schema.parse(["--no-my-option"])

      assert result == {:ok, [], my_option: false}
    end

    test "handles count switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :count)
        |> Schema.parse(["--my-option", "--my-option", "--my-option"])

      assert result == {:ok, [], my_option: 3}
    end

    test "handles float switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :float)
        |> Schema.parse(["--my-option", "0.25"])

      assert result == {:ok, [], my_option: 0.25}
    end

    test "handles integer switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :integer)
        |> Schema.parse(["--my-option", "0"])

      assert result == {:ok, [], my_option: 0}
    end

    test "handles string switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :string)
        |> Schema.parse(["--my-option", "my string"])

      assert result == {:ok, [], my_option: "my string"}
    end

    test "supports switch aliases" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :string, alias: :o)
        |> Schema.parse(["-o", "my string"])

      assert result == {:ok, [], my_option: "my string"}
    end

    test "errors when value can't parse to raw type" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :integer)
        |> Schema.parse(["--my-option", "not an integer"])

      expected_message =
        String.trim("""
        1 error found!
        --my-option : Expected type integer, got "not an integer"
        """)

      assert {:error, error} = result
      assert Exception.message(error) == expected_message
    end

    test "errors when switch not given value" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :string)
        |> Schema.parse(["--my-option"])

      expected_message =
        String.trim("""
        1 error found!
        --my-option : Missing argument of type string
        """)

      assert {:error, error} = result
      assert Exception.message(error) == expected_message
    end

    test "errors when switch not in schema" do
      result =
        Schema.new()
        |> Schema.parse(["--my-option", "my string"])

      expected_message =
        String.trim("""
        1 error found!
        --my-option : Unknown option
        """)

      assert {:error, error} = result
      assert Exception.message(error) == expected_message
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
