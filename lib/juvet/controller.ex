defmodule Juvet.Controller do
  @moduledoc """
  Helper functions for a module handling a request from a platform.
  """

  alias Juvet.Router.{Conn, Response}

  defmacro __using__(_opts) do
    quote do
      def send_response(context, response \\ nil)

      def send_response(context, nil), do: send_the_response(context)

      def send_response(context, %Response{} = response) do
        context = context |> maybe_update_response(response)

        send_the_response(context)
      end

      def update_response(context, %Response{} = response),
        do: maybe_update_response(context, response)

      defp send_the_response(context) do
        conn = Conn.send_resp(context)
        Map.put(context, :conn, conn)
      end

      defp maybe_update_response(context, nil), do: context

      defp maybe_update_response(context, %Response{} = response),
        do: Map.put(context, :response, response)
    end
  end
end
