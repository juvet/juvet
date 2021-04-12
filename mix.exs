defmodule Juvet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :juvet,
      version: "0.0.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Juvet",
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases(),
      description: "The messaging platform for chat apps",
      organization: "Juvet",
      source_url: "https://github.com/juvet/juvet",
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :httpoison, :plug_cowboy, :websockex],
      mod: {Juvet, []}
    ]
  end

  defp aliases() do
    [
      test: "test --no-start"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:websockex, "~> 0.4.0"},
      {:exvcr, "~> 0.10", only: [:dev, :test]}
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
        github: "https://github.com/juvet/juvet",
        documentation: "http://hexdocs.pm/juvet/"
      },
      files: ~w(lib LICENSE.md mix.exs README.md)
    }
  end

  defp preferred_cli_env do
    [
      vcr: :test,
      "vcr.delete": :test,
      "vcr.check": :test,
      "vcr.show": :test,
      record: :test
    ]
  end
end
