defmodule Mix.Tasks.Record do
  @moduledoc """
  Mix task to record Slack API responses into `test/fixtures/vcr_cassettes`.
  """

  use Mix.Task

  alias Juvet.SlackAPI

  @all_methods [
    "chat.postMessage",
    "chat.update",
    "conversations.open",
    "rtm.connect",
    "team.info",
    "users.info"
  ]

  @cassette_dir "test/fixtures/vcr_cassettes"

  @filters [
    {~r/wss:.*=/, "ws:\\/\\/localhost:51345\\/ws"},
    {~r{https://slack.com}, "http://localhost:51345"}
  ]

  @shortdoc "Re-record the Slack API cassettes"
  def run(args) do
    Application.put_env(:juvet, Juvet.HTTPClient.Req, [])
    Application.ensure_all_started(:req)

    params =
      args
      |> Enum.map(fn arg -> String.split(arg, ":") end)
      |> Enum.into(%{}, fn [a, b] -> {String.trim_trailing(a, ":"), b} end)

    {method, params} = Map.pop(params, "method")
    params = params |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    methods = if method, do: [method], else: @all_methods

    Enum.each(methods, fn method_name ->
      record(method_name, "successful", params)
      record(method_name, "invalid_auth", %{token: "blah"})
    end)
  end

  def cassette_directory_name(method_name) do
    method_name |> String.replace(".", "/") |> String.downcase()
  end

  defp record(method_name, outcome, params) do
    {:ok, response} = SlackAPI.make_request(method_name, params)

    path = Path.join([@cassette_dir, cassette_directory_name(method_name), outcome <> ".json"])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, Jason.encode!([%{response: to_cassette(response)}], pretty: true))
  end

  defp to_cassette(%{status: status, headers: headers, body: body}) do
    %{
      status_code: status,
      headers: Map.new(headers),
      body:
        Enum.reduce(@filters, body, fn {pattern, replacement}, acc ->
          Regex.replace(pattern, acc, replacement)
        end)
    }
  end
end
