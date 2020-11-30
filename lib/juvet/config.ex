defmodule Juvet.Config do
  @moduledoc """
  Provides some domain-specific functions around a Keyword list to extract various configuration
  options from config.

  ## Example

  Each of the following items can be included in your `config/config.exs` file:

  ```
  config :juvet,
    bot: MyBot,
    endpoint: [
      http: [port: {system: "PORT"}]
    ],
    slack: [
      actions_endpoint: "/slack/actions",
      events_endpoint: "/slack/events"
    ]
  ```
  """

  @defaults [
    bot: MyBot,
    endpoint: [http: [port: String.to_integer(System.get_env("PORT", "4000"))]],
    slack: nil
  ]

  @doc """
  Returns the module that defines your bot.
  """
  def bot(config), do: Keyword.get(config, :bot, @defaults[:bot])

  @doc """
  Returns all of the configuration for the endpoint.
  """
  def endpoint(config), do: Keyword.get(config, :endpoint, @defaults[:endpoint])

  @doc """
  Returns true if the configuration is not valid and false if it is valid.
  """
  def invalid?(config) do
    bot(config) |> to_string() |> String.trim() == "" ||
      endpoint(config) == nil ||
      (scheme(config) == :http && port(config) == nil)
  end

  @doc """
  Returns the port that is defined within the `endpoint/1` configuration.
  """
  def port(config) do
    port_config(endpoint(config))
  end

  @doc """
  Returns the scheme (http or https) that is defined within the `endpoint/1` configuration.
  """
  def scheme(config) do
    scheme_config(Keyword.keys(endpoint(config) || Keyword.new()))
  end

  @doc """
  Returns all of the configuration for the Slack service.
  """
  def slack(config),
    do: slack_config(Keyword.get(config, :slack, @defaults[:slack]))

  @doc """
  Returns true if the configuration contains configuration for Slack.
  """
  def slack_configured?(config), do: slack_config_configured?(slack(config))

  @doc """
  Returns true if the configuration is valid and false if it is not valid.
  """
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
