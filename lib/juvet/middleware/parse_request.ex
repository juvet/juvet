defmodule Juvet.Middleware.ParseRequest do
  def call(%{conn: conn} = context) do
    {:ok, Map.put_new(context, :request, generate_request(conn))}
  end

  def call(context), do: {:ok, context}

  defp generate_request(conn), do: Juvet.Router.Request.new(conn)
end
