defmodule Juvet.SlackRoutes do
  @moduledoc """
  Creates routes necessary for incoming Slack messages from configuration.
  """

  defmacro __using__(_opts) do
    quote do
      config = Juvet.configuration()

      if Juvet.Config.slack_configured?(config) do
        defaults = %{
          actions_endpoint: nil,
          commands_endpoint: nil,
          events_endpoint: nil,
          oauth_callback_endpoint: nil,
          oauth_request_endpoint: nil,
          options_load_endpoint: nil
        }

        %{
          actions_endpoint: actions_endpoint,
          commands_endpoint: commands_endpoint,
          events_endpoint: events_endpoint,
          oauth_callback_endpoint: oauth_callback_endpoint,
          oauth_request_endpoint: oauth_request_endpoint,
          options_load_endpoint: options_load_endpoint
        } = Map.merge(defaults, Juvet.Config.slack(config))

        if events_endpoint,
          do: post(events_endpoint, to: Juvet.SlackRoute)

        if commands_endpoint,
          do: post(commands_endpoint, to: Juvet.SlackRoute)

        if actions_endpoint,
          do: post(actions_endpoint, to: Juvet.SlackRoute)

        if oauth_callback_endpoint,
          do: get(oauth_callback_endpoint, to: Juvet.SlackRoute)

        if oauth_request_endpoint,
          do: get(oauth_request_endpoint, to: Juvet.SlackRoute)

        if options_load_endpoint,
          do: post(options_load_endpoint, to: Juvet.SlackRoute)
      end
    end
  end
end
