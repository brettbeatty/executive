defmodule Executive.Types.Time do
  @moduledoc """
  DateTime parses from an ISO 8601 time.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :time)
      ...> |> Schema.parse(["--my-option", "12:34:56"])
      {:ok, [], [my_option: ~T[12:34:56]]}

  This type is aliased as `:time`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "time"
  end

  @impl Executive.Type
  def parse(_params, raw) do
    case Time.from_iso8601(raw) do
      {:ok, time} ->
        {:ok, time}

      {:error, :invalid_format} ->
        :error

      {:error, :invalid_time} ->
        {:error, "invalid time"}
    end
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      Time.t()
    end
  end
end
