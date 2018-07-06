defmodule Juvet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :juvet,
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Juvet",
      deps: deps(),
      docs: docs(),
      source_url: "https://github.com/juvet/juvet",
      description: "The message platform framework built in Elixir",
      package: package(),
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application do
    [
      mod: {Juvet, []},
      extra_applications: [:logger, :httpoison, :websockex]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:pubsub, "~> 1.0"},
      {:websockex, "~> 0.4.0"},
      {:cowboy, "~> 1.1", only: :test},
      {:exvcr, "~> 0.10", only: :test},
      {:plug, "~> 1.6", only: :test}
    ]
  end

  defp docs do
    []
  end

  defp package do
    %{
      maintainers: ["Jamie Wright"],
      licenses: ["MIT"],
      links: %{
        Github: "https://github.com/juvet/juvet",
        Documentation: "http://hexdocs.pm/juvet/"
      }
    }
  end

  defp preferred_cli_env do
    [
      vcr: :test,
      "vcr.delete": :test,
      "vcr.check": :test,
      "vcr.show": :test
    ]
  end
end
