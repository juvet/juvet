defmodule Juvet.Controller do
  @moduledoc """
  Helper functions for a module handling a request from a platform.
  """

  defmacro __using__(_opts) do
    quote do
      def send_response(context), do: Juvet.Router.Conn.send_resp(context)
    end
  end
end
