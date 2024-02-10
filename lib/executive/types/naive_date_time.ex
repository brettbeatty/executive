defmodule Executive.Types.NaiveDateTime do
  @moduledoc """
  NaiveDateTime parses from an ISO 8601 datetime, omitting offset.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :naive_datetime)
      ...> |> Schema.parse(["--my-option", "2024-01-01T00:00:00"])
      {:ok, [], [my_option: ~N[2024-01-01 00:00:00]]}

  This type is aliased as `:naive_datetime`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "naive datetime"
  end

  @impl Executive.Type
  def parse(_params, raw) do
    case NaiveDateTime.from_iso8601(raw) do
      {:ok, datetime} ->
        {:ok, datetime}

      {:error, :invalid_format} ->
        :error

      {:error, :invalid_date} ->
        {:error, "invalid date"}

      {:error, :invalid_time} ->
        {:error, "invalid time"}

      {:error, error} when is_atom(error) ->
        :error
    end
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      NaiveDateTime.t()
    end
  end
end
