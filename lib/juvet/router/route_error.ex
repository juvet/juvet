defmodule Juvet.Router.RouteError do
  @moduledoc """
  Exception raised when an exception is found within a route..
  """
  defexception status: 404,
               message: "invalid route",
               router: nil

  def exception(opts) do
    message = Keyword.fetch!(opts, :message)
    router = Keyword.fetch!(opts, :router)

    %__MODULE__{
      message: message,
      router: router
    }
  end
end
