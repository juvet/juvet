defmodule Juvet.Config do
  @moduledoc """
  Provides some domain-specific functions around a Keyword list to extract various configuration
  options from config.

  ## Example

  Each of the following items can be included in your `config/config.exs` file:

  ```
  config :juvet,
    bot: MyBot,
    slack: [
      actions_endpoint: "/slack/actions",
      events_endpoint: "/slack/events"
    ]
  ```
  """

  @defaults [
    bot: MyBot,
    slack: nil
  ]

  @doc """
  Returns the module that defines your bot.
  """
  def bot(config), do: Keyword.get(config, :bot, @defaults[:bot])

  @doc """
  Returns true if the configuration is not valid and false if it is valid.
  """
  def invalid?(config) do
    bot(config) |> to_string() |> String.trim() == ""
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

  defp slack_config(nil), do: nil
  defp slack_config(list), do: Enum.into(list, %{})
  defp slack_config_configured?(nil), do: false
  defp slack_config_configured?(_), do: true
end
