defmodule Juvet.Middleware.IdentifyRequest do
  @moduledoc """
  Middleware to identify where the request came from and apply that
  `platform` to the `request`.
  """

  alias Juvet.Router.Request

  @spec call(map()) :: {:ok, map()} | {:error, any()}
  def call(%{request: request} = context) do
    request = Request.put_platform(request)

    {:ok, %{context | request: request}}
  end

  def call(context), do: {:ok, context}
end
