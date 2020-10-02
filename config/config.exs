use Mix.Config

config :juvet,
  bot: nil,
  endpoint: [
    http: [port: String.to_integer(System.get_env("PORT"))]
  ],
  slack: [
    events_endpoint: "/slack/events"
  ]

import_config "#{Mix.env()}.exs"
