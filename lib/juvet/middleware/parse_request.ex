defmodule Juvet.Middleware.ParseRequest do
  @moduledoc """
  Middleware to convert a `Plug.Conn` to a `Juvet.Router.Request` so it
  can be used within the middleware chain.
  """

  alias Juvet.Router.Request

  def call(%{conn: conn} = context) do
    {:ok, Map.put_new(context, :request, generate_request(conn))}
  end

  def call(context), do: {:ok, context}

  defp generate_request(conn), do: Request.new(conn)
end
