use Mix.Config

config :juvet,
  endpoint: [
    http: [port: String.to_integer(System.get_env("PORT"))]
  ],
  slack: [
    events_endpoint: "/slack/events"
  ]

import_config "#{Mix.env()}.exs"
