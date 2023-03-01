defmodule Juvet.Config do
  @moduledoc """
  Provides some domain-specific functions around a Keyword list to extract various configuration
  options from config.

  ## Example

  Each of the following items can be included in your `config/config.exs` file:

  ```
  config :juvet,
    bot: MyBot,
    router: MyRouter,
    slack: [
      actions_endpoint: "/slack/actions",
      commands_endpoint: "/slack/commands",
      events_endpoint: "/slack/events",
      options_load_endpoint: "/slack/options"
    ]
  ```
  """

  @defaults [
    bot: MyBot,
    router: nil,
    slack: nil
  ]

  @doc """
  Returns the module that defines your bot.
  """
  @spec bot(Keyword.t()) :: module() | nil
  def bot(config), do: Keyword.get(config, :bot, @defaults[:bot])

  @doc """
  Returns true if the configuration is not valid and false if it is valid.
  """
  @spec invalid?(Keyword.t()) :: boolean()
  def invalid?(config) do
    bot(config) |> to_string() |> String.trim() == ""
  end

  @doc """
  Returns the module that defines your router.
  """
  @spec router(Keyword.t()) :: module() | nil
  def router(config), do: Keyword.get(config, :router, @defaults[:router])

  @doc """
  Returns all of the configuration for the Slack service.
  """
  @spec slack(Keyword.t()) :: any()
  def slack(config),
    do: slack_config(Keyword.get(config, :slack, @defaults[:slack]))

  @doc """
  Returns true if the configuration contains configuration for Slack.
  """
  @spec slack_configured?(Keyword.t()) :: boolean()
  def slack_configured?(config), do: slack_config_configured?(slack(config))

  @doc """
  Returns true if the configuration is valid and false if it is not valid.
  """
  @spec valid?(Keyword.t()) :: boolean()
  def valid?(config), do: !__MODULE__.invalid?(config)

  defp slack_config(nil), do: nil
  defp slack_config(list), do: Enum.into(list, %{})
  defp slack_config_configured?(nil), do: false
  defp slack_config_configured?(_), do: true
end
