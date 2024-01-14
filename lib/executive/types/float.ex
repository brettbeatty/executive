defmodule Executive.Types.Float do
  @moduledoc """
  Floats are floating-point numbers.

      iex> alias Executive.Schema
      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :float)
      ...> |> Schema.parse(["--my-option", "1.21"])
      {:ok, [], [my_option: 1.21]}

  The decimal point is unneeded.

      iex> alias Executive.Schema
      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :float)
      ...> |> Schema.parse(["--my-option", "0"])
      {:ok, [], [my_option: 0.0]}

  Scientific notation is also supported.

      iex> alias Executive.Schema
      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :float)
      ...> |> Schema.parse(["--my-option", "1.0e20"])
      {:ok, [], [my_option: 1.0e20]}

  This type is aliased as `:float`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "float"
  end

  @impl Executive.Type
  def parse(_params, _flag, raw) do
    case Float.parse(raw) do
      {refined, ""} ->
        {:ok, refined}

      {_integer, _remaining} ->
        :error

      :error ->
        :error
    end
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      float()
    end
  end
end
