defmodule Juvet.ConfigTest do
  use ExUnit.Case

  setup_all do
    config = Application.get_all_env(:juvet)

    on_exit(fn ->
      reset_config(config)
    end)
  end

  setup do
    reset_config([])

    :ok
  end

  describe "Juvet.Config.bot/0" do
    test "returns the value specified in the config" do
      Application.put_env(:juvet, :bot, HelloWorld)

      assert Juvet.Config.bot() == HelloWorld
    end
  end

  describe "Juvet.Config.endpoint/0" do
    test "returns the value specified in the config" do
      Application.put_env(:juvet, :endpoint, http: [port: 4002])

      assert Juvet.Config.endpoint() == [http: [port: 4002]]
    end
  end

  describe "Juvet.Config.scheme/0" do
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

  defp reset_config(config),
    do: Application.put_all_env([{:juvet, config}])
end
