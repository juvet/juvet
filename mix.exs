defmodule Juvet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :juvet,
      version: "0.0.1",
      elixir: "~> 1.6",
      name: "Juvet",
      deps: deps(),
      docs: docs(),
      source_url: "https://github.com/juvet/juvet",
      description: "The message platform framework built in Elixir",
      package: package(),
      preferred_cli_env: preferred_cli_env()
    ]
  end

  defp deps do
    [
      {:exvcr, "~> 0.10", only: :test},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"}
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
