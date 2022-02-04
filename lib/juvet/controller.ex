defmodule Juvet.Controller do
  @moduledoc """
  Helper functions for a module handling a request from a platform.
  """

  alias Juvet.Router.Conn

  defmacro __using__(_opts) do
    quote do
      def send_response(context, response \\ nil) do
        context = context |> maybe_update_response(response)

        conn = Conn.send_resp(context)
        Map.put(context, :conn, conn)
      end

      defp maybe_update_response(context, nil), do: context
      defp maybe_update_response(context, response), do: Map.put(context, :response, response)
    end
  end
end
