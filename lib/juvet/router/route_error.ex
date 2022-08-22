defmodule Juvet.Router.RouteError do
  @moduledoc """
  Exception raised when an exception is found within a route..
  """
  @type t :: %__MODULE__{
          status: integer(),
          message: String.t(),
          router: struct()
        }
  defexception status: 404,
               message: "invalid route",
               router: nil

  @spec exception(keyword()) :: Juvet.Router.RouteError.t()
  def exception(opts) do
    message = Keyword.fetch!(opts, :message)
    router = Keyword.fetch!(opts, :router)

    %__MODULE__{
      message: message,
      router: router
    }
  end
end
