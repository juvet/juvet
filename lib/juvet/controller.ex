defmodule Juvet.Controller do
  @moduledoc """
  Helper functions for a module handling a request from a platform.
  """

  @view_context_key :juvet_view

  alias Juvet.Router.{Conn, Response}
  alias Juvet.{View, ViewStateManager}

  defmacro __using__(opts) do
    quote do
      unquote(prelude())
      unquote(defs(opts))
    end
  end

  defp prelude do
    quote do
      import unquote(__MODULE__)
    end
  end

  defp defs(opts) do
    view_state_manager = Keyword.get(opts, :view_state_manager, ViewStateManager)

    quote do
      def send_message(context, template, assigns \\ []),
        do: send_message_from(__MODULE__, context, template, assigns)

      def view_state, do: unquote(view_state_manager)
    end
  end

  @spec clear_view(map()) :: map()
  def clear_view(context), do: Map.delete(context, @view_context_key)

  @spec put_view(map(), String.t() | atom()) :: map()
  def put_view(context, view), do: Map.put(context, @view_context_key, view)

  def send_message_from(controller, context, template, assigns \\ []) do
    case view_module(context) do
      nil ->
        # TODO: View.default_view(template, prefix: controller_prefix(controller))
        View.default_view(template)
        |> View.send_message(template, assigns |> Enum.into(%{}) |> Map.merge(context))

      view ->
        View.send_message(view, template, assigns |> Enum.into(%{}) |> Map.merge(context))
    end
    |> maybe_clear_view()
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
  def view_module(context), do: Map.get(context, @view_context_key)

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

  defp maybe_clear_view({:ok, context}) when is_map(context) do
    context_key = @view_context_key

    case context do
      %{^context_key => _key} ->
        {:ok, context |> clear_view()}

      _ ->
        {:ok, context}
    end
  end

  defp maybe_clear_view(response), do: response

  defp maybe_update_response(context, %Response{} = response),
    do: Map.put(context, :response, response)
end
