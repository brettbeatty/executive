defmodule Executive.SchemaTest do
  use ExUnit.Case, async: true
  alias Executive.ParseError
  alias Executive.Schema
  alias Executive.Schema.Option
  doctest Schema

  describe "new/0" do
    test "creates new schema" do
      assert %Schema{} = Schema.new()
    end
  end

  describe "option_docs/2" do
    test "builds docs for schema options" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_boolean, :boolean, alias: :b)
        |> Schema.put_option(:my_string, :string, required: true, doc: "some docs here")
        |> Schema.option_docs()
        |> to_string()

      expected =
        String.trim_trailing("""
          - `--my-boolean` (`-b`) - boolean
          - `--my-string` - string, required - some docs here
        """)

      assert actual == expected
    end

    test "supports :except" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_enum, {:enum, [:fork, :spoon]},
          alias: [:f, :s],
          doc: "fork or spoon?",
          required: true
        )
        |> Schema.put_option(:my_integer, :integer, doc: "some docs about my integer")
        |> Schema.put_option(:my_uuid, :uuid, alias: :u, required: true)
        |> Schema.option_docs(except: [:my_uuid])
        |> to_string()

      expected =
        String.trim_trailing("""
          - `--my-enum` (`-f`, `-s`) - enum (fork, spoon), required - fork or spoon?
          - `--my-integer` - integer - some docs about my integer
        """)

      assert actual == expected
    end

    test "supports :only" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_float, :float, alias: :f, doc: "my float")
        |> Schema.put_option(:my_integer, :integer, alias: :i, doc: "my integer")
        |> Schema.put_option(:my_string, :string, alias: :s, required: true)
        |> Schema.option_docs(only: [:my_float, :my_string])
        |> to_string()

      expected =
        String.trim_trailing("""
          - `--my-float` (`-f`) - float - my float
          - `--my-string` (`-s`) - string, required
        """)

      assert actual == expected
    end
  end

  describe "option_typespec/2" do
    test "builds typespec for parsed option" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_boolean, :boolean)
        |> Schema.put_option(:my_enum, {:enum, [:a, :b, :c]})
        |> Schema.put_option(:my_uuid, :uuid)
        |> Schema.option_typespec()

      expected =
        quote do
          {:my_boolean, boolean()}
          | {:my_enum, :a | :b | :c}
          | {:my_uuid, <<_::288>>}
        end

      assert Macro.to_string(actual) == Macro.to_string(expected)
    end

    test "supports :except" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_boolean, :boolean)
        |> Schema.put_option(:my_float, :float)
        |> Schema.put_option(:my_string, :string)
        |> Schema.option_typespec(except: [:my_float])

      expected =
        quote do
          {:my_boolean, boolean()} | {:my_string, String.t()}
        end

      assert Macro.to_string(actual) == Macro.to_string(expected)
    end

    test "supports :only" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_enum, {:enum, [:x, :y]})
        |> Schema.put_option(:my_float, :float)
        |> Schema.put_option(:my_integer, :integer)
        |> Schema.option_typespec(only: [:my_integer, :my_float])

      expected =
        quote do
          {:my_integer, integer()} | {:my_float, float()}
        end

      assert Macro.to_string(actual) == Macro.to_string(expected)
    end
  end

  describe "options_typespec/2" do
    test "builds typespec for parsed options" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_boolean, :boolean)
        |> Schema.put_option(:my_float, :float)
        |> Schema.options_typespec()

      expected =
        quote do
          [my_boolean: boolean(), my_float: float()]
        end

      assert Macro.to_string(actual) == Macro.to_string(expected)
    end

    test "supports :except" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_float, :float)
        |> Schema.put_option(:my_integer, :integer)
        |> Schema.put_option(:my_uuid, :uuid)
        |> Schema.options_typespec(except: [:my_uuid])

      expected =
        quote do
          [my_float: float(), my_integer: integer()]
        end

      assert Macro.to_string(actual) == Macro.to_string(expected)
    end

    test "supports :only" do
      actual =
        Schema.new()
        |> Schema.put_option(:my_enum, {:enum, [:one, :two, :three]})
        |> Schema.put_option(:my_string, :string)
        |> Schema.put_option(:my_uuid, :uuid)
        |> Schema.options_typespec(only: [:my_uuid, :my_string])

      expected =
        quote do
          [my_uuid: <<_::288>>, my_string: String.t()]
        end

      assert Macro.to_string(actual) == Macro.to_string(expected)
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

    test "handles enum switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, {:enum, [:one, :two, :three]})
        |> Schema.parse(["--my-option", "two"])

      assert result == {:ok, [], my_option: :two}
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

    test "handles uuid switches" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :uuid)
        |> Schema.parse(["--my-option", "7ac420a7-4ddf-4652-84bc-29cd13d3700a"])

      assert result == {:ok, [], my_option: "7ac420a7-4ddf-4652-84bc-29cd13d3700a"}
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

    test "errors when switch fails parsing by type" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, {:enum, [:duck, :goose]})
        |> Schema.parse(["--my-option", "swan"])

      expected_message =
        String.trim("""
        1 error found!
        --my-option : Expected one of (duck, goose), got "swan"
        """)

      assert {:error, error} = result
      assert Exception.message(error) == expected_message
    end

    test "succeeds when required options provided" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :boolean, required: true)
        |> Schema.parse(["--no-my-option"])

      assert {:ok, [], my_option: false} = result
    end

    test "required options don't show up as missing when they're missing because they're invalid" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :uuid, required: true)
        |> Schema.parse(["--my-option", "something else"])

      expected_message =
        String.trim("""
        1 error found!
        --my-option : Expected type UUID, got "something else"
        """)

      assert {:error, error} = result
      assert Exception.message(error) == expected_message
    end

    test "errors when required options not given" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :uuid, required: true)
        |> Schema.parse([])

      expected_message =
        String.trim("""
        1 error found!
        --my-option : Missing argument of type UUID
        """)

      assert {:error, error} = result
      assert Exception.message(error) == expected_message
    end

    test "keeps last value when unique: true" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :string)
        |> Schema.parse(["--my-option", "one value", "--my-option", "another value"])

      assert result == {:ok, [], my_option: "another value"}
    end

    test "keeps all values for option when unique: false" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, {:enum, [:duck, :goose]}, unique: false)
        |> Schema.parse(["--my-option", "duck", "--my-option", "duck", "--my-option", "goose"])

      assert result == {:ok, [], my_option: :duck, my_option: :duck, my_option: :goose}
    end
  end

  describe "parse!/2" do
    test "parses options from argv" do
      result =
        Schema.new()
        |> Schema.put_option(:my_option, :string)
        |> Schema.put_option(:another_option, :integer, alias: :a)
        |> Schema.parse!(["some", "args", "--my-option", "my string", "-a", "5"])

      assert result == {["some", "args"], my_option: "my string", another_option: 5}
    end

    test "raises if parsing fails" do
      expected_message =
        String.trim("""
        4 errors found!
        --my-option : Missing argument of type string
        --another-option : Expected type integer, got "not an integer"
        -b : Unknown option
        --one-more-option : Expected one of (x, y, z), got "w"
        """)

      assert_raise ParseError, expected_message, fn ->
        Schema.new()
        |> Schema.put_option(:my_option, :string)
        |> Schema.put_option(:another_option, :integer, alias: :a)
        |> Schema.put_option(:one_more_option, {:enum, [:x, :y, :z]}, alias: :o)
        |> Schema.parse!(["--my-option", "-a", "not an integer", "-b", "4", "-o", "w"])
      end
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
