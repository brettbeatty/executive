defmodule Executive.ParseError do
  @moduledoc """
  An error with parsing mix task args accoring to an `Executive.Schema`.
  """

  @type t() :: %__MODULE__{switch_errors: [{String.t(), IO.chardata()}]}

  defexception [:switch_errors]

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
