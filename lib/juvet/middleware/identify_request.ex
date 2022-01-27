defmodule Juvet.Middleware.IdentifyRequest do
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
