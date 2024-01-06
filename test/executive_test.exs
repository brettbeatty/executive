defmodule ExecutiveTest do
  use ExUnit.Case, async: true
  doctest Executive

  test "greets the world" do
    assert Executive.hello() == :world
  end
end
