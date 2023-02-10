defmodule Juvet.Middleware.NormalizeRequestParams do
  @moduledoc """
  Middleware to populate common parameters within a `Juvet.Router.Request` so the parameters
  can be used across controllers with a common shape.
  """

  alias Juvet.Router.RequestParamNormalizer

  @spec call(map()) :: {:ok, map()}
  def call(%{request: %{raw_params: _raw_params} = request} = context),
    do: {:ok, Map.replace(context, :request, RequestParamNormalizer.normalize(request))}

  def call(context), do: {:ok, context}
end
