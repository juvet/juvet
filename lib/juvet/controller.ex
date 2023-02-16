defmodule Juvet.Controller do
  @moduledoc """
  Helper functions for a module handling a request from a platform.
  """

  alias Juvet.Router.{Conn, Response}
  alias Juvet.View

  defmacro __using__(opts) do
    view_state_manager = Keyword.get(opts, :view_state_manager, Juvet.ViewStateManager)

    quote do
      import Juvet.Controller

      def view_state, do: unquote(view_state_manager)
    end
  end

  @spec put_view(map(), String.t() | atom()) :: map()
  def put_view(context, view), do: Map.put(context, :juvet_view, view)

  def send_message(context, template, assigns \\ []) do
    # Allow for a default view to be specified in opts or specified as a convention
    # but the name of the module needs to be deciphered inside the quote
    # Phoenix does this with another plug
    case view_module(context) do
      nil ->
        raise ArgumentError, """
        expected to have a view specified in `context`. Use `put_view` to specify the view module before
        calling `send_message`.
        """

      view ->
        View.send_message(view, template, assigns |> Enum.into(%{}) |> Map.merge(context))
    end
  end

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

  @spec update_response(map(), Response.t() | nil) :: map()
  def update_response(context, %Response{} = response),
    do: maybe_update_response(context, response)

  @spec view_module(map()) :: String.t() | atom() | nil
  def view_module(context), do: Map.get(context, :juvet_view)

  defp send_url_response(url, %Response{body: body}), do: send_url_response(url, body)

  defp send_url_response(url, response) when is_map(response),
    do: send_url_response(url, response |> Poison.encode!())

  defp send_url_response(url, response) when is_binary(response) do
    HTTPoison.post!(url, response, [{"Content-Type", "application/json"}])
  end

  defp send_the_response(context) do
    conn = Conn.send_resp(context)
    Map.put(context, :conn, conn)
  end

  defp maybe_update_response(context, %Response{} = response),
    do: Map.put(context, :response, response)
end
