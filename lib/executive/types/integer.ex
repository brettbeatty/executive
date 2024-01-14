defmodule Executive.Types.Integer do
  @moduledoc """
  Integers are whole numbers.

      iex> alias Executive.Schema
      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :integer)
      ...> |> Schema.parse(["--my-option", "4"])
      {:ok, [], [my_option: 4]}

  This type is aliased as `:integer`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "integer"
  end

  @impl Executive.Type
  def parse(_params, _flag, raw) do
    case Integer.parse(raw) do
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
      integer()
    end
  end
end
