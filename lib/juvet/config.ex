defmodule Juvet.Config do
  @moduledoc """
  Provides a small wrapper around `Application.get_env(:juvet)`, providing an
  accessor to configuration values.

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

  def bot, do: get_application_env(:bot, MyBot)

  def endpoint,
    do:
      get_application_env(:endpoint,
        http: [port: String.to_integer(System.get_env("PORT", "4000"))]
      )

  def port do
    port(endpoint() || Keyword.new())
  end

  def scheme do
    scheme(Keyword.keys(endpoint() || Keyword.new()))
  end

  def slack, do: slack(get_application_env(:slack))

  def slack_configured?, do: slack_configured?(slack())

  defp get_application_env(key, default \\ nil) do
    Application.get_env(:juvet, key, default)
  end

  defp port(http: [port: port]), do: port
  defp port(_), do: nil
  defp scheme([:https]), do: :https
  defp scheme([:http]), do: :http
  defp scheme(_), do: nil
  defp slack(nil), do: nil
  defp slack(list), do: Enum.into(list, %{})
  defp slack_configured?(nil), do: false
  defp slack_configured?(_), do: true
end
