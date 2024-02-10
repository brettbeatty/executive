defmodule Executive.Schema.OptionTest do
  use ExUnit.Case, async: true
  alias Executive.Schema.Option
  doctest Option

  defmodule MockType do
    @behaviour Executive.Type

    def return(value) do
      ref = make_ref()
      send(self(), {ref, return: value})
      ref
    end

    @impl Executive.Type
    def name(ref) do
      receive!(ref)
    end

    @impl Executive.Type
    def parse(ref, raw) do
      send(self(), {ref, raw: raw})
      receive!(ref)
    end

    @impl Executive.Type
    def spec(ref) do
      receive!(ref)
    end

    defp receive!(ref) when is_reference(ref) do
      receive do
        {^ref, return: value} ->
          value
      after
        0 ->
          raise "no value provided"
      end
    end
  end

  defp error(_value), do: :error

  describe "docs/1" do
    test "builds docs without docstring" do
      option = Option.new(:my_option, :string, [])

      actual = option |> Option.docs() |> to_string()
      expected = "  - `--my-option` - string"

      assert actual == expected
    end

    test "builds docs with docstring" do
      option = Option.new(:my_option, :integer, doc: "does something amazing")

      actual = option |> Option.docs() |> to_string()
      expected = "  - `--my-option` - integer - does something amazing"

      assert actual == expected
    end

    test "annotates required options" do
      option = Option.new(:my_option, :uuid, required: true)

      actual = option |> Option.docs() |> to_string()
      expected = "  - `--my-option` - UUID, required"

      assert actual == expected
    end

    test "lists all switches" do
      option = Option.new(:my_option, :boolean, alias: [:f, :n])

      actual = option |> Option.docs() |> to_string()
      expected = "  - `--my-option`, `--no-my-option`, `-f`, `-n` - boolean"

      assert actual == expected
    end

    test "put it all together" do
      option =
        Option.new(:my_option, {:enum, [:a, :b, :c]},
          alias: :e,
          doc: "some description of what each thing does",
          required: true
        )

      actual = option |> Option.docs() |> to_string()

      expected =
        "  - `--my-option`, `-e` - enum (a, b, c), required - some description of what each thing does"

      assert actual == expected
    end
  end

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

    test "resolves more-complex type aliases" do
      assert %Option{type: Executive.Types.Integer, type_params: [max: -1]} =
               Option.new(:my_option, :neg_integer, [])
    end

    test "supports :alias option" do
      assert %Option{aliases: [:o]} = Option.new(:my_option, MyType, alias: :o)
      assert %Option{aliases: [:m, :o]} = Option.new(:my_option, MyType, alias: [:m, :o])
    end

    test "supports :required option" do
      assert %Option{required: true} = Option.new(:my_option, MyType, required: true)
    end

    test "defaults to required: false" do
      assert %Option{required: false} = Option.new(:my_option, MyType, [])
    end
  end

  describe "parse_and_validate/2" do
    test "calls type's parse callback" do
      refined = make_ref()
      ref = MockType.return({:ok, refined})
      option = Option.new(:my_option, {MockType, ref}, [])

      assert Option.parse_and_validate(option, "raw value") == {:ok, refined}
      assert_received {^ref, raw: "raw value"}
    end

    test "allows passing validations" do
      refined = make_ref()
      ref = MockType.return({:ok, refined})

      validate = fn ^refined ->
        send(self(), {ref, :validate})
        :ok
      end

      option = Option.new(:my_option, {MockType, ref}, validate: validate)

      assert Option.parse_and_validate(option, "raw value") == {:ok, refined}
      assert_received {^ref, raw: "raw value"}
      assert_received {^ref, :validate}
    end

    test "builds a default error" do
      string = "my string"
      option = Option.new(:my_option, :string, validate: &error/1)

      assert {:error, message} = Option.parse_and_validate(option, string)

      assert to_string(message) ==
               ~S(Value "my string" failed validation Executive.Schema.OptionTest.error/1)
    end

    test "can return more helpful error" do
      string = "my string"
      message = ["Something", " went horribly ", "wrong"]
      validate = fn ^string -> {:error, message} end
      option = Option.new(:my_option, :string, validate: validate)

      assert Option.parse_and_validate(option, string) == {:error, message}
    end
  end

  describe "spec/1" do
    test "gets type's typespec" do
      spec = quote(do: pid() | reference())
      ref = MockType.return(spec)
      option = Option.new(:my_option, {MockType, ref}, [])

      assert Option.spec(option) == spec
    end
  end

  describe "type_name/1" do
    test "gets type's name" do
      name = ["integer", " between ", "1", " and ", "100"]
      ref = MockType.return(name)
      option = Option.new(:my_option, {MockType, ref}, [])

      assert Option.type_name(option) == name
    end
  end
end
