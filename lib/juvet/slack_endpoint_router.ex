defmodule Juvet.SlackEndpointRouter do
  @moduledoc """
  Creates routes necessary for incoming Slack messages from configuration.
  """

  defmacro __using__(opts) do
    config = Keyword.get(opts, :config)

    # TODO: This is garbage. Would rather allow for any module to be
    # defined and act as an endpoint router for the endpoint. Not
    # quite sure how to do that yet,

    quote bind_quoted: [config: config] do
      if Juvet.Config.slack_configured?(config) do
        defaults = %{
          actions_endpoint: nil,
          commands_endpoint: nil,
          events_endpoint: nil
        }

        %{
          actions_endpoint: actions_endpoint,
          commands_endpoint: commands_endpoint,
          events_endpoint: events_endpoint
        } = Map.merge(defaults, Juvet.Config.slack(config))

        if events_endpoint,
          do:
            post(events_endpoint,
              to: Juvet.SlackEventsEndpointRouter,
              init_opts: config
            )

        if commands_endpoint,
          do:
            post(commands_endpoint,
              to: Juvet.SlackActionsEndpointRouter,
              init_opts: config
            )

        if actions_endpoint,
          do:
            post(actions_endpoint,
              to: Juvet.SlackActionsEndpointRouter,
              init_opts: config
            )
      end
    end
  end
end
