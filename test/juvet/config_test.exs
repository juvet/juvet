defmodule Juvet.ConfigTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  setup_all :setup_reset_config_on_exit

  describe "Juvet.Config.bot/0" do
    setup :setup_reset_config

    test "returns the value specified in the config" do
      Application.put_env(:juvet, :bot, HelloWorld)

      assert Juvet.Config.bot() == HelloWorld
    end
  end

  describe "Juvet.Config.endpoint/0" do
    setup :setup_reset_config

    test "returns the value specified in the config" do
      Application.put_env(:juvet, :endpoint, http: [port: 4002])

      assert Juvet.Config.endpoint() == [http: [port: 4002]]
    end
  end

  describe "Juvet.Config.port/0" do
    setup :setup_reset_config

    test "returns the port if the endpoint specifies it" do
      Application.put_env(:juvet, :endpoint, http: [port: 4002])

      assert Juvet.Config.port() == 4002
    end

    test "returns nil if the endpoint is not specified" do
      Application.put_env(:juvet, :endpoint, nil)

      assert Juvet.Config.port() == nil
    end
  end

  describe "Juvet.Config.scheme/0" do
    setup :setup_reset_config

    test "returns http if the endpoint specifies http" do
      Application.put_env(:juvet, :endpoint, http: [port: 4002])

      assert Juvet.Config.scheme() == :http
    end

    test "returns https if the endpoint specifies https as a keyword" do
      Application.put_env(:juvet, :endpoint, https: true)

      assert Juvet.Config.scheme() == :https
    end

    test "returns nil if the endpoint is not specified" do
      Application.put_env(:juvet, :endpoint, nil)

      assert Juvet.Config.scheme() == nil
    end

    test "returns nil if the endpoint does not contain scheme" do
      Application.put_env(:juvet, :endpoint, foo: :bar)

      assert Juvet.Config.scheme() == nil
    end
  end

  describe "Juvet.Config.slack/0" do
    setup :setup_reset_config

    test "returns a map containing the Slack configuration" do
      Application.put_env(:juvet, :slack, actions_endpoint_path: "")

      assert Juvet.Config.slack() == %{actions_endpoint_path: ""}
    end

    test "returns nil if Slack is not configured" do
      Application.put_env(:juvet, :slack, nil)

      assert Juvet.Config.slack() == nil
    end
  end

  describe "Juvet.Config.slack_configured?/0" do
    setup :setup_reset_config

    test "returns true if Slack is configured" do
      Application.put_env(:juvet, :slack, actions_endpoint_path: "")

      assert Juvet.Config.slack_configured?()
    end

    test "returns false if Slack is not configured" do
      Application.put_env(:juvet, :slack, nil)

      refute Juvet.Config.slack_configured?()
    end
  end

  describe "Juvet.Config.valid?/0" do
    setup :setup_reset_config

    test "returns true when the configuration is valid" do
      Application.put_env(:juvet, :bot, MyBot)
      Application.put_env(:juvet, :endpoint, http: [port: 4002])

      assert Juvet.Config.valid?()
    end

    test "returns false when the bot is blank" do
      Application.put_env(:juvet, :bot, nil)
      Application.put_env(:juvet, :endpoint, http: [port: 4002])

      refute Juvet.Config.valid?()
    end

    test "returns false when the endpoint is not specified" do
      Application.put_env(:juvet, :bot, MyBot)
      Application.put_env(:juvet, :endpoint, nil)

      refute Juvet.Config.valid?()
    end

    test "returns false when the scheme is http but no port is specified" do
      Application.put_env(:juvet, :bot, MyBot)
      Application.put_env(:juvet, :endpoint, http: [foo: :bar])

      refute Juvet.Config.valid?()
    end
  end
end
