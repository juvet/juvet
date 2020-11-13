defmodule Juvet.EndpointRouter do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  @config Application.get_all_env(:juvet)

  if Juvet.Config.slack_configured?(@config) do
    defaults = %{actions_endpoint: nil, events_endpoint: nil}

    %{actions_endpoint: actions_endpoint, events_endpoint: events_endpoint} =
      Map.merge(defaults, Juvet.Config.slack(@config))

    if events_endpoint,
      do:
        post(events_endpoint,
          to: Juvet.SlackEventsEndpointRouter,
          init_opts: @config
        )

    if actions_endpoint,
      do:
        post(actions_endpoint,
          to: Juvet.SlackActionsEndpointRouter,
          init_opts: @config
        )
  end

  # TODO: Make this response configurable like in Phoenix
  match(_, do: send_resp(conn, 404, "Oh no! This route is not handled in Juvet"))
end
