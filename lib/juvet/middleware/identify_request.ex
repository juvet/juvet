defmodule Juvet.Middleware.IdentifyRequest do
  def call(
        %{request: %{headers: [{"x-slack-signature", _} | _]} = request} =
          context
      ) do
    request = %{request | platform: :slack}

    {:ok, %{context | request: request}}
  end

  def call(context), do: {:ok, context}
end
