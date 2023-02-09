defmodule Juvet.Middleware.DecodeRequestRawParams do
  @moduledoc """
  Middleware to decode any parameters within a `Juvet.Router.Request` so the parameters
  can be easily pattern matched.
  """

  alias Juvet.Router.RequestParamDecoder

  @spec call(map()) :: {:ok, map()}
  def call(%{request: %{raw_params: _raw_params} = request} = context),
    do: {:ok, Map.replace(context, :request, RequestParamDecoder.decode(request))}

  def call(context), do: {:ok, context}
end
