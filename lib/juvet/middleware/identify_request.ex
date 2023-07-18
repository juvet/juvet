defmodule Juvet.Middleware.IdentifyRequest do
  @moduledoc """
  Middleware to identify where the request came from and apply that
  `platform` to the `request`.
  """

  alias Juvet.Router.RequestIdentifier

  @spec call(map()) :: {:ok, map()} | {:error, any()}
  def call(%{configuration: configuration, request: request} = context) do
    request = %{request | platform: RequestIdentifier.platform(request, configuration)}

    {:ok, %{context | request: request}}
  end

  def call(context), do: {:ok, context}
end
