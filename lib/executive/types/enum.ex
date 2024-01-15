defmodule Executive.Types.Enum do
  @moduledoc """
  Enums are great for parsing one of a finite set of atoms.

  This type is parametrized and takes a list of allowed values. When a switch's
  value is in the list of allowed values, an atom is returned.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:enum, [:heads, :tails]})
      ...> |> Schema.parse(["--my-option", "tails"])
      {:ok, [], [my_option: :tails]}

  If the switch's value is not in the list of allowed values, an error is returned.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:enum, [:heads, :tails]})
      ...> |> Schema.parse!(["--my-option", "something else"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected one of (heads, tails), got "something else"

  This type is aliased as `:enum`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(allowed_values) do
    ["enum (", splice(allowed_values), ?)]
  end

  @spec splice([atom()]) :: [String.t()]
  defp splice(allowed_values) do
    allowed_values
    |> Enum.map(&Atom.to_string/1)
    |> Enum.intersperse(", ")
  end

  @impl Executive.Type
  def parse(allowed_values, _flag, raw) when is_binary(raw) do
    with :error <- find(allowed_values, raw) do
      {:error, ["Expected one of (", splice(allowed_values), "), got ", inspect(raw)]}
    end
  end

  @spec find([atom()], String.t()) :: {:ok, atom()} | :error
  defp find(allowed_values, value)

  defp find([allowed_value | allowed_values], value) do
    if Atom.to_string(allowed_value) == value do
      {:ok, allowed_value}
    else
      find(allowed_values, value)
    end
  end

  defp find([], _value) do
    :error
  end

  @impl Executive.Type
  def spec(allowed_values)
  def spec([last]), do: last
  def spec([head | tail]), do: {:|, [], [head, spec(tail)]}
  def spec([]), do: quote(do: none())
end
