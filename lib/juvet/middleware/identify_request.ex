defmodule Juvet.Middleware.IdentifyRequest do
  @moduledoc """
  Middleware to identify where the request came from and apply that
  `platform` to the `request`.
  """

  alias Juvet.Router.Request

  def call(%{request: request} = context) do
    case Request.get_header(request, "x-slack-signature") do
      [] ->
        {:ok, context}

      [_] ->
        request = %{request | platform: :slack}
        {:ok, %{context | request: request}}
    end
  end

  def call(context), do: {:ok, context}
end
