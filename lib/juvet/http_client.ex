defmodule Juvet.HTTPClient do
  @moduledoc """
  Behaviour for the HTTP client Juvet uses to call Slack.

  ## Configuration

      config :juvet, :http_client, Juvet.HTTPClient.Req

  Defaults to `Juvet.HTTPClient.Req`. Implement `c:request/5` to plug in another
  client or a test double. Response header names must be lowercase.
  """

  @type method :: :get | :post | :put | :patch | :delete
  @type headers :: [{String.t(), String.t()}]
  @type response :: %{status: non_neg_integer(), headers: headers(), body: binary()}

  @callback request(method(), url :: String.t(), headers(), body :: iodata(), keyword()) ::
              {:ok, response()} | {:error, term()}

  @spec request(method(), String.t(), headers(), iodata(), keyword()) ::
          {:ok, response()} | {:error, term()}
  def request(method, url, headers, body, opts \\ []),
    do: client().request(method, url, headers, body, opts)

  @spec client() :: module()
  def client, do: Application.get_env(:juvet, :http_client, Juvet.HTTPClient.Req)
end
