defmodule Juvet.ConfigurationHelpers do
  @moduledoc """
  Test helpers to aid in testing that involves modifying the configuration
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  def default_config do
    [
      bot: MyBot,
      endpoint: [http: [port: 8080]],
      slack: [events_endpoint: "/slack/events"]
    ]
  end

  def setup_reset_config_on_exit(_context) do
    config = Application.get_all_env(:juvet)

    on_exit(fn ->
      reset_config(config)
    end)
  end

  def setup_reset_config(_context) do
    reset_config([])

    :ok
  end

  def reset_config(config), do: Application.put_all_env([{:juvet, config}])
end
