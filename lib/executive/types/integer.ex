defmodule Executive.Types.Integer do
  @moduledoc """
  Integers are whole numbers.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :integer)
      ...> |> Schema.parse(["--my-option", "4"])
      {:ok, [], [my_option: 4]}

  ## Parameters

  This type can be parametrized with a minimum.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:integer, min: 5})
      ...> |> Schema.parse!(["--my-option", "3"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected type integer at least 5, got "3"

  Or a maximum.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:integer, max: -2})
      ...> |> Schema.parse!(["--my-option", "0"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected type integer at most -2, got "0"

  Or both.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:integer, min: -1, max: 1})
      ...> |> Schema.parse!(["--my-option", "2"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected type integer between -1 and 1, got "2"

  When giving both a minimum and maximum, this type can also be parametrized
  with a range.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:integer, 4..7})
      ...> |> Schema.parse!(["--my-option", "3"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected type integer between 4 and 7, got "3"

  If minimum is greater than maximum, type will never match.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:integer, 3..-3})
      ...> |> Schema.parse!(["--my-option", "0"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected type integer between 3 and -3, got "0"

  ## Aliases

  This type is aliased as `:integer`.

  It has some additional aliases that override any params:

  Alias              | Params
  ------------------ | ---------
  `:neg_integer`     | `[max: -1]`
  `:non_neg_integer` | `[min: 0]`
  `:pos_integer`     | `[min: 1]`

  """
  @behaviour Executive.Type

  @type params() :: [max: integer(), min: integer()] | Range.t()

  @impl Executive.Type
  def name(params) do
    case min_max(params) do
      %{min: min, max: max} ->
        ["integer between ", Integer.to_string(min), " and ", Integer.to_string(max)]

      %{min: 0} ->
        "non-negative integer"

      %{min: 1} ->
        "positive integer"

      %{min: min} ->
        ["integer at least ", Integer.to_string(min)]

      %{max: -1} ->
        "negative integer"

      %{max: max} ->
        ["integer at most ", Integer.to_string(max)]

      %{} ->
        "integer"
    end
  end

  @impl Executive.Type
  def parse(params, _flag, raw) do
    with {:ok, refined} <- parse_integer(raw),
         :ok <- check_bounds(params, refined) do
      {:ok, refined}
    end
  end

  @spec parse_integer(String.t()) :: {:ok, integer()} | :error
  defp parse_integer(raw) do
    case Integer.parse(raw) do
      {refined, ""} ->
        {:ok, refined}

      {_integer, _remaining} ->
        :error

      :error ->
        :error
    end
  end

  @spec check_bounds(params(), integer()) :: :ok | :error
  defp check_bounds(params, integer) do
    in_bounds? =
      case min_max(params) do
        %{min: min, max: max} -> integer in min..max//1
        %{min: min} -> integer >= min
        %{max: max} -> integer <= max
        %{} -> true
      end

    if in_bounds?, do: :ok, else: :error
  end

  @impl Executive.Type
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def spec(params) do
    case min_max(params) do
      %{min: min, max: max} -> quote(do: unquote(min)..unquote(max))
      %{min: 0} -> quote(do: non_neg_integer())
      %{min: min} when min > 0 -> quote(do: pos_integer())
      %{max: max} when max < 0 -> quote(do: neg_integer())
      %{} -> quote(do: integer())
    end
  end

  @spec min_max(params()) :: %{optional(:min) => integer(), optional(:max) => integer()}
  defp min_max(params)

  defp min_max(min..max) do
    min_max(min: min, max: max)
  end

  defp min_max(params) when is_list(params) do
    Map.new(params)
  end
end
