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
    def capture?(ref, switch_flag) do
      send(self(), {ref, switch_flag: switch_flag})
      receive!(ref)
    end

    @impl Executive.Type
    def name(ref) do
      receive!(ref)
    end

    @impl Executive.Type
    def parse(ref, flag, raw) do
      send(self(), {ref, raw: raw, flag: flag})
      receive!(ref)
    end

    @impl Executive.Type
    def spec(ref) do
      receive!(ref)
    end

    @impl Executive.Type
    def switches(ref, name, aliases) do
      send(self(), {ref, name: name, aliases: aliases})
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

  describe "capture?/2" do
    test "defaults to true" do
      option = Option.new(:my_option, MyType, [])
      assert Option.capture?(option, nil) == true
    end

    test "calls type's capture?/2 if implemented" do
      switch_flag = make_ref()
      ref = MockType.return(false)
      option = Option.new(:my_option, {MockType, ref}, [])

      assert Option.capture?(option, switch_flag) == false
      assert_received {^ref, switch_flag: ^switch_flag}
    end
  end

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

  describe "parse/2" do
    test "calls type's parse callback" do
      refined = make_ref()
      flag = make_ref()
      ref = MockType.return({:ok, refined})
      option = Option.new(:my_option, {MockType, ref}, [])

      assert Option.parse(option, flag, "raw value") == {:ok, refined}
      assert_received {^ref, raw: "raw value", flag: ^flag}
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

  describe "switches/1" do
    test "creates switches for option without aliases" do
      option = Option.new(:my_option, MyType, [])
      assert Option.switches(option) == [{"--my-option", nil}]
    end

    test "creates switches for option with aliases" do
      option = Option.new(:my_option, MyType, alias: :o)
      assert Option.switches(option) == [{"--my-option", nil}, {"-o", nil}]
    end

    test "calls type's switches/2 if implemented" do
      switches = [
        {"--one-switch", make_ref()},
        {"--another-switch", make_ref()},
        {"-s", make_ref()}
      ]

      ref = MockType.return(switches)
      option = Option.new(:my_option, {MockType, ref}, alias: [:m, :o])
      assert Option.switches(option) == switches
      assert_received {^ref, name: :my_option, aliases: [:m, :o]}
    end
  end

  describe "switches/2" do
    test "creates switch for name" do
      assert Option.switches(:my_switch, []) == [{"--my-switch", nil}]
    end

    test "creates switches for name and aliases" do
      expected_switches = [{"--my-switch", nil}, {"-m", nil}, {"-s", nil}]
      assert Option.switches(:my_switch, [:m, :s]) == expected_switches
    end
  end

  describe "switch_alias/1" do
    test "prepends a dash" do
      assert Option.switch_alias(:m) == "-m"
    end

    test "allows strings" do
      assert Option.switch_alias("s") == "-s"
    end
  end

  describe "switch_name/1" do
    test "prepends two dashes" do
      assert Option.switch_name(:option) == "--option"
    end

    test "replaces underscores with dashes" do
      assert Option.switch_name(:my_switch) == "--my-switch"
    end

    test "allows strings" do
      assert Option.switch_name("my_switch") == "--my-switch"
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
