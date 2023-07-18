import Config

config :juvet,
  slack: [
    actions_endpoint: "/slack/actions",
    commands_endpoint: "/slack/commands",
    events_endpoint: "/slack/events",
    oauth_callback_endpoint: "/auth/slack/callback",
    oauth_request_endpoint: "/auth/slack",
    options_load_endpoint: "/slack/options"
  ]

import_config "#{Mix.env()}.exs"
