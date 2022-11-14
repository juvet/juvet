defmodule Juvet.Controller do
  @moduledoc """
  Helper functions for a module handling a request from a platform.
  """

  alias Juvet.Router.{Conn, Response}

  defmacro __using__(_opts) do
    quote do
      @spec send_response(map() | String.t(), Response.t() | String.t() | map() | nil) :: map()
      def send_response(context, response \\ nil)

      def send_response(context, response) when is_binary(context),
        do: send_url_response(context, response)

      def send_response(context, %Response{} = response) when is_map(context) do
        context = context |> maybe_update_response(response)

        send_the_response(context)
      end

      def send_response(context, nil) when is_map(context), do: send_the_response(context)

      def send_response(context, response) when is_map(response),
        do: send_response(context, Response.new(body: response))

      def send_response(context, nil) when is_map(context), do: send_the_response(context)

      defp send_url_response(url, %Response{body: body}), do: send_url_response(url, body)

      defp send_url_response(url, response) when is_map(response),
        do: send_url_response(url, response |> Poison.encode!())

      defp send_url_response(url, response) when is_binary(response) do
        HTTPoison.post!(url, response, [{"Content-Type", "application/json"}])
      end

      @spec update_response(map(), Response.t() | nil) :: map()
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
