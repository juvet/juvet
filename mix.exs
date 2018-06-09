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
      package: package()
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:mock, "~> 0.3.0", only: :test}
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
end
