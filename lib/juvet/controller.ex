defmodule Juvet.Controller do
  @moduledoc """
  Helper functions for a module handling a request from a platform.
  """

  @view_context_key :juvet_view

  alias Juvet.Router.{Conn, Request, Response, RouterFactory}
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
      def request_format(%{request: request}), do: request_format_from(request)

      def send_message(context, template, assigns \\ []),
        do: send_message_from(__MODULE__, context, template, assigns)

      def send_messages(context, templates, assigns \\ []),
        do: send_messages_from(__MODULE__, context, templates, assigns)

      def view_state, do: unquote(view_state_manager)
    end
  end

  def controller_prefix(controller, opts \\ []) do
    suffix = Keyword.get(opts, :suffix)

    controller
    |> to_string()
    |> String.replace_leading("Elixir.", "")
    |> String.replace_trailing("Controller", "")
    |> maybe_append_suffix(suffix)
  end

  @spec clear_view(map()) :: map()
  def clear_view(context), do: Map.delete(context, @view_context_key)

  def default_view_module(controller, template) do
    view_prefix =
      controller
      |> controller_prefix(suffix: ".")
      |> String.replace(".Controllers.", ".Views.")

    View.default_view(template, prefix: view_prefix)
  end

  @spec put_view(map(), String.t() | atom()) :: map()
  def put_view(context, view), do: Map.put(context, @view_context_key, view)

  def request_format_from(%Request{platform: platform} = request) do
    case RouterFactory.router(platform).request_format(request) do
      {:ok, format} -> format
      {:error, error} -> error
    end
  end

  def send_message_from(controller, context, template, assigns \\ []),
    do: send_message_from(controller, context, template, assigns, [])

  # Support: send_messages(context, [:template1, {:template2, :view2}])
  # Support: send_messages(context, [{:view1 %{} = assigns_only_for_view1}, :view2], %{} = assigns_for_all_messages)
  def send_messages_from(controller, context, templates, assigns \\ []) do
    Enum.reduce(templates, {:ok, %{}}, fn template, result ->
      send_message_from(controller, context, template, assigns, clear_view: false)
      |> merge_send_message_result(result)
    end)
    |> maybe_clear_view(true)
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

  defp maybe_append_suffix(prefix, nil), do: prefix
  defp maybe_append_suffix("", _suffix), do: ""
  defp maybe_append_suffix(prefix, suffix), do: prefix <> suffix

  defp maybe_clear_view({:ok, context}, true) when is_map(context) do
    context_key = @view_context_key

    case context do
      %{^context_key => _key} ->
        {:ok, context |> clear_view()}

      _ ->
        {:ok, context}
    end
  end

  defp maybe_clear_view(response, _clear), do: response

  defp maybe_update_response(context, %Response{} = response),
    do: Map.put(context, :response, response)

  defp merge_send_message_result({:ok, result}, {:ok, acc}),
    do: {:ok, Map.merge(acc, result)}

  defp merge_send_message_result({:ok, result}, {:error, error, acc}),
    do: {:error, error, Map.merge(acc, result)}

  defp merge_send_message_result({:error, error}, {:ok, acc}),
    do: {:error, error, acc}

  defp merge_send_message_result({:error, error}, {:error, _error, acc}),
    do: {:error, error, acc}

  defp send_message_from(controller, context, template, assigns, opts) do
    clear_view = Keyword.get(opts, :clear_view, true)

    case view_module(context) do
      nil ->
        controller
        |> default_view_module(template)
        |> View.send_message(template, assigns |> Enum.into(%{}) |> Map.merge(context))

      view ->
        View.send_message(view, template, assigns |> Enum.into(%{}) |> Map.merge(context))
    end
    |> maybe_clear_view(clear_view)
  end

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
end
