defmodule Juvet.Config do
  @moduledoc """
  Provides a small wrapper around a Keyword list to extract various configuration
  options from config.

  Each of the following items can be included in your `config/config.exs` file:

  config :juvet,
    bot: MyBot,
    endpoint: [
      http: [port: {system: "PORT"}]
    ],
    slack: [
      actions_endpoint_path: "/slack/actions",
      events_endpoint_path: "/slack/events"
    ]
  """

  @defaults [
    bot: MyBot,
    endpoint: [http: [port: String.to_integer(System.get_env("PORT", "4000"))]],
    slack: nil
  ]

  def bot(config), do: Keyword.get(config, :bot, @defaults[:bot])

  def endpoint(config), do: Keyword.get(config, :endpoint, @defaults[:endpoint])

  def invalid?(config) do
    bot(config) |> to_string() |> String.trim() == "" ||
      endpoint(config) == nil ||
      (scheme(config) == :http && port(config) == nil)
  end

  def port(config) do
    port_config(endpoint(config))
  end

  def scheme(config) do
    scheme_config(Keyword.keys(endpoint(config) || Keyword.new()))
  end

  def slack(config),
    do: slack_config(Keyword.get(config, :slack, @defaults[:slack]))

  def slack_configured?(config), do: slack_config_configured?(slack(config))

  def valid?(config), do: !__MODULE__.invalid?(config)

  defp port_config(http: [port: port]), do: port
  defp port_config(_), do: nil
  defp scheme_config([:https]), do: :https
  defp scheme_config([:http]), do: :http
  defp scheme_config(_), do: nil
  defp slack_config(nil), do: nil
  defp slack_config(list), do: Enum.into(list, %{})
  defp slack_config_configured?(nil), do: false
  defp slack_config_configured?(_), do: true
end
