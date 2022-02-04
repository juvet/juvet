defmodule Juvet.Midddleware.BuildDefaultResponse do
  @moduledoc """
  Middleware to create a default `Juvet.Router.Response` for the request that is
  contained within the context.
  """

  alias Juvet.Router.Response

  def call(%{request: _request} = context),
    do: {:ok, Map.put_new(context, :response, default_response())}

  def call(context), do: {:ok, context}

  defp default_response, do: Response.new(status: 200)
end
