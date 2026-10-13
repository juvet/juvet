defmodule Juvet.SlackAPI do
  @moduledoc """
  Helper methods to help process the response from Slack.
  """

  alias Juvet.{HTTPClient, JSON}

  @doc """
  Returns an error tuple if the body contains an `ok: false` node, else
  returns an ok tuple and the body.
  """
  @spec handle_response({:ok, map()} | {:error, term()}) :: {:ok, map()} | {:error, term()}
  def handle_response({:ok, %{ok: false} = body}) do
    {:error, body}
  end

  def handle_response({:ok, %{ok: true} = body}) do
    {:ok, body}
  end

  def handle_response({:error, _reason} = error), do: error

  # Default seconds to wait when Slack returns a 429 without a parseable
  # `Retry-After` header (Slack always sends one, but be defensive).
  @default_retry_after 30

  @doc """
  Decodes a JSON response and converts it into a Map.

  A Slack rate-limited response (HTTP 429) is surfaced as an `ok: false` body
  with `error: "ratelimited"` and a `retry_after` value (seconds) read from the
  `Retry-After` header, so callers can back off for the duration Slack asks for.
  """
  @spec parse_response({:ok, HTTPClient.response()} | {:error, term()}) ::
          {:ok, map()} | {:error, term()}
  def parse_response({:ok, %{status: 429, headers: headers}}) do
    {:ok, %{ok: false, error: "ratelimited", retry_after: retry_after(headers)}}
  end

  def parse_response({:ok, %{body: body}}), do: JSON.decode(body, keys: :atoms)
  def parse_response({:error, _reason} = error), do: error

  @doc """
  Parses and handles the response from the Slack API.
  """
  @spec render_response({:ok, HTTPClient.response()} | {:error, term()}) ::
          {:ok, map()} | {:error, term()}
  def render_response(tuple), do: parse_response(tuple) |> handle_response

  @doc """
  Returns the url for what url the API should use a the base url along
  with the current endpoint.
  """
  @spec process_url(String.t()) :: String.t()
  def process_url(endpoint) do
    url = Application.get_env(:slack, :url, "https://slack.com")
    "#{url}/api/#{endpoint}"
  end

  @spec process_request_body(map()) :: String.t()
  def process_request_body(body), do: body |> URI.encode_query()

  @doc """
  Make the request to the endpoint and returns that response.
  """
  @spec make_request(String.t(), map()) :: {:ok, HTTPClient.response()} | {:error, term()}
  def make_request(endpoint, params) do
    {access_token, params} = extract_access_token(params)

    HTTPClient.request(
      :post,
      process_url(endpoint),
      headers(access_token),
      process_request_body(params)
    )
  end

  @doc false
  defp retry_after(headers) do
    headers
    |> Enum.find_value(fn {key, value} ->
      if String.downcase(key) == "retry-after", do: value
    end)
    |> parse_retry_after()
  end

  @doc false
  defp parse_retry_after(nil), do: @default_retry_after

  defp parse_retry_after(value) do
    case Integer.parse(value) do
      {seconds, _rest} when seconds > 0 -> seconds
      _ -> @default_retry_after
    end
  end

  @doc false
  defp append_authorization_header(headers, nil), do: headers

  @doc false
  defp append_authorization_header(headers, access_token),
    do: headers ++ [{"authorization", "Bearer #{access_token}"}]

  @doc false
  defp extract_access_token(params) do
    Map.pop(params, :token)
  end

  @doc false
  defp headers(access_token) do
    [
      {"accept", "application/json; charset=utf-8"},
      {"content-type", "application/x-www-form-urlencoded"}
    ]
    |> append_authorization_header(access_token)
  end
end
