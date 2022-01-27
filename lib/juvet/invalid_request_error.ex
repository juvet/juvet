defmodule Juvet.InvalidRequestError do
  @moduledoc """
  Exception raised when a request is invalid that comes into Juvet.
  """
  defexception message: "Invalid request"

  def exception(message) do
    %__MODULE__{message: message}
  end
end
