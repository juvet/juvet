defmodule Juvet.CassetteHelpers do
  @moduledoc """
  Replays recorded Slack responses from `test/fixtures/vcr_cassettes` through
  `Req.Test` (for `Juvet.HTTPClient`) and `Tesla.Mock` (for OAuth2).
  """

  @cassette_dir "test/fixtures/vcr_cassettes"

  defmacro use_cassette(name, do: block) do
    quote do
      Juvet.CassetteHelpers.stub_cassette(unquote(name))
      unquote(block)
    end
  end

  def stub_cassette(name) do
    %{"status_code" => status, "headers" => headers, "body" => body} = load(name)
    headers = Enum.map(headers, fn {key, value} -> {String.downcase(key), value} end)

    Req.Test.stub(Juvet.HTTPClient, fn conn ->
      conn
      |> Plug.Conn.merge_resp_headers(headers)
      |> Plug.Conn.send_resp(status, body)
    end)

    Tesla.Mock.mock(fn _env -> %Tesla.Env{status: status, headers: headers, body: body} end)
  end

  defp load(name) do
    path = Path.join(@cassette_dir, String.downcase(name) <> ".json")
    [%{"response" => response}] = path |> File.read!() |> Jason.decode!()
    response
  end
end
