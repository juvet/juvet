defmodule Juvet.ConfigTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  describe "Juvet.Config.bot/1" do
    test "returns the value specified in the config" do
      assert Juvet.Config.bot(bot: HelloWorld) == HelloWorld
    end
  end

  describe "Juvet.Config.endpoint/1" do
    test "returns the value specified in the config" do
      assert Juvet.Config.endpoint(endpoint: [http: [port: 4002]]) == [
               http: [port: 4002]
             ]
    end
  end

  describe "Juvet.Config.port/1" do
    test "returns the port if the endpoint specifies it" do
      assert Juvet.Config.port(endpoint: [http: [port: 4002]]) == 4002
    end

    test "returns nil if the endpoint is not specified" do
      assert Juvet.Config.port(endpoint: nil) == nil
    end
  end

  describe "Juvet.Config.scheme/1" do
    test "returns http if the endpoint specifies http" do
      assert Juvet.Config.scheme(endpoint: [http: [port: 4002]]) == :http
    end

    test "returns https if the endpoint specifies https as a keyword" do
      assert Juvet.Config.scheme(endpoint: [https: true]) == :https
    end

    test "returns nil if the endpoint is not specified" do
      assert Juvet.Config.scheme(endpoint: nil) == nil
    end

    test "returns nil if the endpoint does not contain scheme" do
      assert Juvet.Config.scheme(endpoint: [foo: :bar]) == nil
    end
  end

  describe "Juvet.Config.slack/0" do
    test "returns a map containing the Slack configuration" do
      assert Juvet.Config.slack(slack: [actions_endpoint_path: ""]) == %{
               actions_endpoint_path: ""
             }
    end

    test "returns nil if Slack is not configured" do
      assert Juvet.Config.slack(slack: nil) == nil
    end
  end

  describe "Juvet.Config.slack_configured?/0" do
    test "returns true if Slack is configured" do
      assert Juvet.Config.slack_configured?(slack: [actions_endpoint_path: ""])
    end

    test "returns false if Slack is not configured" do
      refute Juvet.Config.slack_configured?(slack: nil)
    end
  end

  describe "Juvet.Config.valid?/0" do
    setup do
      {:ok, config: default_config()}
    end

    test "returns true when the configuration is valid", %{config: config} do
      assert Juvet.Config.valid?(config)
    end

    test "returns false when the bot is blank", %{config: config} do
      refute Juvet.Config.valid?(Keyword.merge(config, bot: nil))
    end

    test "returns false when the endpoint is not specified", %{config: config} do
      refute Juvet.Config.valid?(Keyword.merge(config, endpoint: nil))
    end

    test "returns false when the scheme is http but no port is specified", %{
      config: config
    } do
      refute Juvet.Config.valid?(
               Keyword.merge(config, endpoint: [http: [foo: :bar]])
             )
    end
  end
end
