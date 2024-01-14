defmodule Executive.ParseError do
  @moduledoc """
  An error with parsing mix task args accoring to an `Executive.Schema`.
  """

  @type t() :: %__MODULE__{switch_errors: [{String.t(), IO.chardata()}]}

  defexception [:switch_errors]

  @spec check_empty(t()) :: :ok | {:error, t()}
  def check_empty(error)
  def check_empty(%__MODULE__{switch_errors: []}), do: :ok
  def check_empty(error), do: {:error, Map.update!(error, :switch_errors, &Enum.reverse/1)}

  @spec new() :: t()
  def new do
    exception([])
  end

  @spec put_switch_error(t(), String.t(), IO.chardata()) :: t()
  def put_switch_error(error, switch, message) do
    Map.update!(error, :switch_errors, &[{switch, message} | &1])
  end

  @impl Exception
  def exception(switch_errors) do
    %__MODULE__{switch_errors: switch_errors}
  end

  @impl Exception
  def message(error) do
    %__MODULE__{switch_errors: switch_errors} = error

    header =
      case length(switch_errors) do
        1 ->
          "1 error found!"

        error_count ->
          [Integer.to_string(error_count), " errors found!"]
      end

    body = for {switch, error} <- switch_errors, do: [?\n, switch, " : ", error]
    List.to_string([header | body])
  end
end
