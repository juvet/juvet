defmodule Juvet.Router.SlackRouter do
  @moduledoc """
  Represents a `Juvet.Router` that is used for any routes defined under a Slack `Platform`.
  """

  @behaviour Juvet.Router

  alias Juvet.Router.{Request, RequestIdentifier, Route, SlackRouteHandler}

  @type t :: %__MODULE__{
          platform: Juvet.Router.Platform.t()
        }
  defstruct platform: nil

  @spec new(:slack) :: Juvet.Router.SlackRouter.t()
  @impl Juvet.Router
  def new(platform) do
    %__MODULE__{platform: platform}
  end

  @impl Juvet.Router
  def find_route(router, request, opts \\ [])

  def find_route(router, %{verified?: false} = request, opts),
    do: {:error, {:unverified_route, [router: router, request: request, opts: opts]}}

  def find_route(
        %{platform: %{routes: routes}} = router,
        %{platform: :slack, verified?: true} = request,
        opts
      ) do
    case Enum.find(routes, &(!is_nil(find_slack_route(&1, request, opts)))) do
      nil -> {:error, {:unknown_route, [router: router, request: request, opts: opts]}}
      route -> {:ok, route}
    end
  end

  defp find_slack_route(%Route{type: :action, route: action_id} = route, request, _opts) do
    if action_request?(request, action_id), do: route
  end

  defp find_slack_route(%Route{type: :command, route: command_text} = route, request, _opts) do
    if command_request?(request, command_text), do: route
  end

  defp find_slack_route(%Route{type: :event, route: event} = route, request, _opts) do
    if event_request?(request, event), do: route
  end

  defp find_slack_route(%Route{type: :oauth, route: phase} = route, request, opts) do
    configuration = Keyword.get(opts, :configuration)

    if oauth_request?(request, phase, configuration), do: route
  end

  defp find_slack_route(%Route{type: :option_load, route: action_id} = route, request, _opts) do
    if option_load_request?(request, action_id), do: route
  end

  defp find_slack_route(%Route{type: :url_verification} = route, request, _opts) do
    if url_verification_request?(request), do: route
  end

  defp find_slack_route(%Route{type: :view_closed, route: callback_id} = route, request, _opts) do
    if view_closed_request?(request, callback_id), do: route
  end

  defp find_slack_route(
         %Route{type: :view_submission, route: callback_id} = route,
         request,
         _opts
       ) do
    if view_submission_request?(request, callback_id), do: route
  end

  @impl Juvet.Router
  def get_default_routes do
    {:ok,
     [
       Route.new(:url_verification, nil, to: &SlackRouteHandler.handle_route/1)
     ]}
  end

  @impl Juvet.Router
  def handle_route(context), do: {:ok, context}

  @impl Juvet.Router
  def request_format(%{raw_params: %{"event" => event}}),
    do: request_format_from_event(event)

  @impl Juvet.Router
  def request_format(%{raw_params: %{"payload" => payload}}),
    do: request_format_from_payload(payload)

  @impl Juvet.Router
  def validate(%{platform: :slack} = platform), do: {:ok, platform}

  @impl Juvet.Router
  def validate(_platform), do: {:error, :unknown_platform}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :action} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :command} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :event} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :oauth} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :option_load} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :url_verification} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :view_closed} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(
        _router,
        %Juvet.Router.Route{type: :view_submission} = route,
        _opts
      ),
      do: {:ok, route}

  @impl Juvet.Router
  def validate_route(router, %Juvet.Router.Route{} = route, opts),
    do: {:error, {:unknown_route, [router: router, route: route, opts: opts]}}

  defp action_from_payload(%{"actions" => actions}), do: List.first(actions)
  defp action_from_payload(_payload), do: %{}

  defp action_payload?(%{"type" => "block_actions"} = payload, action_id) do
    action = payload |> action_from_payload

    normalized_value(action["action_id"]) == normalized_value(action_id)
  end

  defp action_payload?(_payload, _action_id), do: false

  defp action_request?(%Request{raw_params: %{"payload" => payload}}, action_id),
    do: payload |> action_payload?(action_id)

  defp action_request?(_request, _action_id), do: false

  defp block_suggestion_payload?(%{"type" => "block_suggestion"} = payload, action_id),
    do: normalized_value(payload["action_id"]) == normalized_value(action_id)

  defp block_suggestion_payload?(_payload, _action_id), do: false

  defp callback_id_from_payload(%{"view" => %{"callback_id" => callback_id}}), do: callback_id
  defp callback_id_from_payload(_payload), do: nil

  defp command_request?(%Request{raw_params: raw_params}, command) do
    normalized_command(raw_params["command"]) == normalized_command(command)
  end

  defp command_without_slash(command), do: String.trim_leading(command, "/")

  defp event_request?(%Request{raw_params: %{"event" => %{"type" => event_type}}}, event) do
    normalized_value(event_type) == normalized_value(event)
  end

  defp event_request?(_payload, _event), do: false

  defp normalized_command(nil), do: nil

  defp normalized_command(command), do: normalized_value(command) |> command_without_slash()

  defp normalized_value(nil), do: nil

  defp normalized_value(value), do: value |> String.trim() |> String.downcase()

  defp oauth_request?(%Request{verified?: true}, _phase, nil), do: false

  defp oauth_request?(%Request{verified?: true} = request, phase, configuration),
    do: RequestIdentifier.oauth_path(request, configuration) == phase

  defp oauth_request?(_request, _phase, _configuration), do: false

  defp option_load_request?(%Request{raw_params: %{"payload" => payload}}, action_id),
    do: payload |> block_suggestion_payload?(action_id)

  defp option_load_request?(_payload, _action_id), do: false

  defp request_format_from_event(%{"type" => "app_home_opened", "view" => _}),
    do: {:ok, :page}

  defp request_format_from_event(_event), do: {:ok, :none}

  defp request_format_from_payload(%{"message" => %{"ts" => _}, "response_url" => _}),
    do: {:ok, :message}

  defp request_format_from_payload(%{"container" => %{"type" => "view"}, "view" => _}),
    do: {:ok, :modal}

  defp request_format_from_payload(_payload), do: {:ok, :none}

  defp url_verification_request?(%{
         raw_params: %{"challenge" => _challenge, "type" => "url_verification"}
       }),
       do: true

  defp url_verification_request?(_payload), do: false

  defp view_closed_payload?(%{"type" => "view_closed"} = payload, callback_id) do
    incoming_callback_id = payload |> callback_id_from_payload

    normalized_value(incoming_callback_id) == normalized_value(callback_id)
  end

  defp view_closed_payload?(_payload, _callback_id), do: false

  defp view_closed_request?(%{raw_params: %{"payload" => payload}}, callback_id),
    do: payload |> view_closed_payload?(callback_id)

  defp view_closed_request?(_request, _callback_id), do: false

  defp view_submission_payload?(%{"type" => "view_submission"} = payload, callback_id) do
    incoming_callback_id = payload |> callback_id_from_payload

    normalized_value(incoming_callback_id) == normalized_value(callback_id)
  end

  defp view_submission_payload?(_payload, _callback_id), do: false

  defp view_submission_request?(%{raw_params: %{"payload" => payload}}, callback_id),
    do: payload |> view_submission_payload?(callback_id)

  defp view_submission_request?(_request, _callback_id), do: false
end
