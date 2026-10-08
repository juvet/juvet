defmodule Juvet.HTTPClient.Req do
  @moduledoc """
  The default `Juvet.HTTPClient`, backed by `Req`.

  Req's automatic retries and body decoding are turned off so Juvet can surface
  Slack's rate limits and decode with the configured JSON library. Extra Req
  options can be set in config, which is how tests attach `Req.Test`:

      config :juvet, Juvet.HTTPClient.Req, plug: {Req.Test, Juvet.HTTPClient}
  """

  @behaviour Juvet.HTTPClient

  @impl true
  def request(method, url, headers, body, opts) do
    [method: method, url: url, headers: headers, body: body, retry: false, decode_body: false]
    |> Keyword.merge(Application.get_env(:juvet, __MODULE__, []))
    |> Keyword.merge(opts)
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: status, headers: headers, body: body}} ->
        {:ok, %{status: status, headers: flatten_headers(headers), body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp flatten_headers(headers) do
    for {name, values} <- headers, value <- List.wrap(values), do: {name, value}
  end
end
