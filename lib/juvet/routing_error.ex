defmodule Juvet.RoutingError do
  @moduledoc """
  Exception raised when there is an issue with routing a request.
  """
  defexception message: "Invalid route", request: nil

  def exception(message, request) do
    %__MODULE__{message: message, request: request}
  end
end
