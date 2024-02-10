defmodule Executive.Types.String do
  @moduledoc """
  Strings are sequences of characters.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :string)
      ...> |> Schema.parse(["--my-option", "some value"])
      {:ok, [], [my_option: "some value"]}

  This type is aliased as `:string`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "string"
  end

  @impl Executive.Type
  def parse(_params, raw) do
    {:ok, raw}
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      String.t()
    end
  end
end
