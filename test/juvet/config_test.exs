defmodule Juvet.ConfigTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  describe "bot/1" do
    test "returns the value specified in the config" do
      assert Juvet.Config.bot(bot: HelloWorld) == HelloWorld
    end
  end

  describe "oauth_paths" do
    test "returns a map of the configured oauth paths for each platform" do
      assert Juvet.Config.oauth_paths(
               slack: [
                 actions_endpoint_path: "/slack/actions",
                 oauth_callback_endpoint: "/auth/slack/callback",
                 oauth_request_endpoint: "/auth/slack"
               ]
             ) == %{
               slack: [
                 [type: :callback, path: "/auth/slack/callback"],
                 [type: :request, path: "/auth/slack"]
               ]
             }
    end

    test "returns an empty map if no oauth paths are configured" do
      assert Juvet.Config.oauth_paths(slack: nil) == %{}
    end
  end

  describe "router/1" do
    test "returns the value specified in the config" do
      assert Juvet.Config.router(router: MyRouter) == MyRouter
    end
  end

  describe "slack/1" do
    test "returns a map containing the Slack configuration" do
      assert Juvet.Config.slack(slack: [actions_endpoint_path: ""]) == %{
               actions_endpoint_path: ""
             }
    end

    test "returns nil if Slack is not configured" do
      assert Juvet.Config.slack(slack: nil) == nil
    end
  end

  describe "slack_configured?/1" do
    test "returns true if Slack is configured" do
      assert Juvet.Config.slack_configured?(slack: [actions_endpoint_path: ""])
    end

    test "returns false if Slack is not configured" do
      refute Juvet.Config.slack_configured?(slack: nil)
    end
  end

  describe "valid?/1" do
    setup do
      {:ok, config: default_config()}
    end

    test "returns true when the configuration is valid", %{config: config} do
      assert Juvet.Config.valid?(config)
    end

    test "returns false when the bot is blank", %{config: config} do
      refute Juvet.Config.valid?(Keyword.merge(config, bot: nil))
    end
  end
end
