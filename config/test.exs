import Config

config :plug, :validate_header_keys_during_test, false

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes",
  custom_cassette_library_dir: "test/fixtures/custom_cassettes",
  filter_sensitive_data: [
    [pattern: "<PASSWORD>.+</PASSWORD>", placeholder: "PASSWORD_PLACEHOLDER"],
    [pattern: "token=([^&#]*)", placeholder: "token=***"],
    [pattern: "wss:.*=", placeholder: "ws:\\/\\/localhost:51345\\/ws"],
    [pattern: "https://slack.com", placeholder: "http://localhost:51345"]
  ],
  filter_request_headers: [
    "Authorization",
    "X-Slack-Req-Id",
    "X-Via",
    "X-Amz-Cf-Id"
  ]

config :juvet,
  bot: MyBot

config :oauth2, adapter: Tesla.Adapter.Hackney
