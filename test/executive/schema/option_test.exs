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
    def raw_type(ref) do
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

  describe "docs/1" do
    test "builds docs without docstring" do
      option = Option.new(:my_option, :string, [])

      actual = option |> Option.docs() |> to_string()

      expected = """
        - `--my-option` - string
      """

      assert actual == expected
    end

    test "builds docs with docstring" do
      option = Option.new(:my_option, :integer, doc: "does something amazing")

      actual = option |> Option.docs() |> to_string()

      expected = """
        - `--my-option` - integer - does something amazing
      """

      assert actual == expected
    end

    test "annotates required options" do
      option = Option.new(:my_option, :uuid, required: true)

      actual = option |> Option.docs() |> to_string()

      expected = """
        - `--my-option` - UUID, required
      """

      assert actual == expected
    end

    test "lists any aliases" do
      option = Option.new(:my_option, :count, alias: [:c, :k])

      actual = option |> Option.docs() |> to_string()

      expected = """
        - `--my-option` (`-c`, `-k`) - count
      """

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

      expected = """
        - `--my-option` (`-e`) - enum (a, b, c), required - some description of what each thing does
      """

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

  describe "parse/2" do
    test "calls type's parse callback" do
      refined = make_ref()
      ref = MockType.return({:ok, refined})
      option = Option.new(:my_option, {MockType, ref}, [])

      assert Option.parse(option, "raw value") == {:ok, refined}
      assert_received {^ref, raw: "raw value"}
    end
  end

  describe "raw_type/1" do
    test "gets type's raw type" do
      ref = MockType.return(:count)
      option = Option.new(:my_option, {MockType, ref}, [])

      assert Option.raw_type(option) == :count
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

  describe "switch/1" do
    test "handles multi-word options" do
      option = Option.new(:multi_word_option, MyType, [])
      assert Option.switch(option) == "--multi-word-option"
    end

    test "handles single-word options" do
      option = Option.new(:option, MyType, [])
      assert Option.switch(option) == "--option"
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
