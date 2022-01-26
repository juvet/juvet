# TODO: Rename to Juvet.SlackRoutes? Rename plus below
defmodule Juvet.SlackEndpointRouter do
  @moduledoc """
  Creates routes necessary for incoming Slack messages from configuration.
  """

  defmacro __using__(opts) do
    config = Keyword.get(opts, :config)

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
              to: Juvet.SlackEventsEndpointRouter
            )

        if commands_endpoint,
          do:
            post(commands_endpoint,
              to: Juvet.SlackCommandsEndpointRouter
            )

        if actions_endpoint,
          do:
            post(actions_endpoint,
              to: Juvet.SlackActionsEndpointRouter
            )
      end
    end
  end
end
