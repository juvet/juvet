defmodule Juvet.Config do
  @moduledoc """
  Provides a small wrapper around `Application.get_env(:juvet)`, providing an
  accessor to configuration values.

  Each of the following items can be included in your `config/config.exs` file:

  config :juvet,
    bot: MyBot,
    endpoint: [
      http: [port: 80]
    ],
    slack: [
      actions_endpoint_path: "/slack/actions",
      events_endpoint_path: "/slack/events"
    ]
  """

  def bot, do: get_application_env(:bot, MyBot)
  def endpoint, do: get_application_env(:endpoint, http: [port: 80])

  def scheme do
    scheme(Keyword.keys(endpoint() || Keyword.new()))
  end

  defp get_application_env(key, default \\ nil) do
    Application.get_env(:juvet, key, default)
  end

  defp scheme([:https]), do: :https
  defp scheme([:http]), do: :http
  defp scheme([_]), do: nil
  defp scheme([]), do: nil
end
