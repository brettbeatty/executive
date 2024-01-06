defmodule Executive.TypeTest do
  use ExUnit.Case, async: true
  alias Executive.Type

  defmodule MockType do
    @behaviour Type

    @impl Type
    def name(ref) do
      receive(ref, "mock type")
    end

    @impl Type
    def parse(raw, ref) do
      send(self(), {ref, received: raw})
      receive(ref, {:ok, :refined_value})
    end

    @impl Type
    def raw_type(ref) do
      receive(ref, :string)
    end

    @impl Type
    def spec(ref) do
      receive(ref, quote(do: atom()))
    end

    defp receive(ref, _default) when is_reference(ref) do
      receive do
        {^ref, return: value} ->
          value
      after
        0 ->
          raise "must send value for parametrized mock type"
      end
    end

    defp receive([], default) do
      default
    end
  end

  describe "name/1" do
    test "custom type" do
      assert Type.name(MockType) == "mock type"
    end

    test "parametrized mock type" do
      ref = make_ref()
      name = [?a, " different ", "mock type"]
      send(self(), {ref, return: name})

      assert Type.name({MockType, ref}) == name
    end

    test "alias :boolean" do
      assert Type.name(:boolean) == "boolean"
    end

    test "alias :count" do
      assert Type.name(:count) == "count"
    end

    test "alias :float" do
      assert Type.name(:float) == "float"
    end

    test "alias :integer" do
      assert Type.name(:integer) == "integer"
    end

    test "alias :string" do
      assert Type.name(:string) == "string"
    end
  end

  describe "parse/2" do
    test "custom type" do
      raw = "some string"

      assert Type.parse(raw, MockType) == {:ok, :refined_value}
      assert_received {[], received: ^raw}
    end

    test "parametrized custom type" do
      ref = make_ref()
      raw = "another string"
      refined = make_ref()
      send(self(), {ref, return: {:ok, refined}})

      assert Type.parse(raw, {MockType, ref}) == {:ok, refined}
      assert_received {^ref, received: ^raw}
    end

    test "alias :boolean" do
      assert Type.parse(true, :boolean) == {:ok, true}
    end

    test "alias :count" do
      assert Type.parse(1, :count) == {:ok, 1}
    end

    test "alias :float" do
      assert Type.parse(0.75, :float) == {:ok, 0.75}
    end

    test "alias :integer" do
      assert Type.parse(0, :integer) == {:ok, 0}
    end

    test "alias :string" do
      assert Type.parse("my string", :string) == {:ok, "my string"}
    end
  end

  describe "raw_type/1" do
    test "custom type" do
      assert Type.raw_type(MockType) == :string
    end

    test "parametrized custom type" do
      ref = make_ref()
      send(self(), {ref, return: :float})

      assert Type.raw_type({MockType, ref}) == :float
    end

    test "alias :boolean" do
      assert Type.raw_type(:boolean) == :boolean
    end

    test "alias :count" do
      assert Type.raw_type(:count) == :count
    end

    test "alias :float" do
      assert Type.raw_type(:float) == :float
    end

    test "alias :integer" do
      assert Type.raw_type(:integer) == :integer
    end

    test "alias :string" do
      assert Type.raw_type(:string) == :string
    end
  end

  describe "spec/1" do
    test "custom type" do
      assert Type.spec(MockType) == quote(do: atom())
    end

    test "parametrized custom type" do
      ref = make_ref()
      spec = quote(do: :stop | :go)
      send(self(), {ref, return: spec})

      assert Type.spec({MockType, ref}) == spec
    end

    test "alias :boolean" do
      assert Type.spec(:boolean) == quote(do: boolean())
    end

    test "alias :count" do
      assert Type.spec(:count) == quote(do: pos_integer())
    end

    test "alias :float" do
      assert Type.spec(:float) == quote(do: float())
    end

    test "alias :integer" do
      assert Type.spec(:integer) == quote(do: integer())
    end

    test "alias :string" do
      assert Type.spec(:string) == quote(do: String.t())
    end
  end
end
