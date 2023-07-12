defmodule Juvet.Middleware.Slack.VerifyRequest do
  @moduledoc """
  Middleware that verifies a `Juvet.Router.Request` is coming from Slack
  by verifying it's header with a signing secret.
  """

  alias Juvet.{ConfigurationError, GregorianDateTime, InvalidRequestError}
  alias Juvet.Router.{Conn, Request, RequestIdentifier}

  @spec call(map()) :: {:ok, map()} | {:error, any()}
  def call(
        %{
          configuration: [slack: [verify_requests: false]],
          request: %{platform: :slack}
        } = context
      ),
      do: request_verified!(context)

  def call(%{request: %{platform: :slack, verified?: false}} = context),
    do: verify_request(context)

  def call(context), do: {:ok, context}

  defp verify_request(%{configuration: configuration, request: request} = context) do
    if RequestIdentifier.oauth?(request, configuration),
      do: request_verified!(context),
      else: verify_request_via_header(context)
  end

  defp verify_request_via_header(%{configuration: configuration, request: request} = context) do
    with {:ok, slack_timestamp} <-
           get_request_header(request, "x-slack-request-timestamp"),
         {:ok, slack_signature} <-
           get_request_header(request, "x-slack-signature"),
         {:ok, timestamp} <- validate_timestamp(slack_timestamp),
         {:ok, raw_body} <- get_request_raw_body(request),
         {:ok, signing_secret} <- get_signing_secret(configuration) do
      create_signature(timestamp, raw_body, signing_secret)
      |> compare_signature(slack_signature, context)
    else
      {:error, "x-slack-request-timestamp" = header} ->
        {:error, %InvalidRequestError{message: missing_header_message(header)}}

      {:error, "x-slack-signature" = header} ->
        {:error, %InvalidRequestError{message: missing_header_message(header)}}

      {:error, :stale_timestamp} ->
        {:error, %InvalidRequestError{message: "Stale Slack request."}}

      {:error, :missing_raw_body} ->
        {:error,
         %InvalidRequestError{
           message:
             "Request body was empty and could not be verified. Ensure you are caching the request body in a body reader plug."
         }}

      {:error, :missing_signing_secret} ->
        {:error,
         %ConfigurationError{
           message: "Slack signing secret missing in Juvet configuration."
         }}
    end
  end

  defp create_signature(timestamp, raw_body, signing_secret) do
    Juvet.SlackSigningSecret.generate(raw_body, signing_secret, timestamp)
  end

  defp compare_signature(signature, slack_signature, context) do
    compare_signature(
      Plug.Crypto.secure_compare(signature, slack_signature),
      context
    )
  end

  defp compare_signature(false, _context),
    do:
      {:error,
       %Juvet.InvalidRequestError{
         message: "Invalid Slack request. Signature mismatch."
       }}

  defp compare_signature(true, context), do: request_verified!(context)

  defp get_request_raw_body(request) do
    case get_in(request.private, [Conn.private_key(), :raw_body]) do
      nil -> {:error, :missing_raw_body}
      raw_body -> {:ok, raw_body}
    end
  end

  defp get_request_header(request, header) do
    case Request.get_header(request, header) do
      [value | _] -> {:ok, value}
      [] -> {:error, header}
    end
  end

  defp get_signing_secret(config) do
    case Juvet.Config.slack(config) do
      %{signing_secret: signing_secret} -> {:ok, signing_secret}
      _ -> {:error, :missing_signing_secret}
    end
  end

  defp request_verified!(%{request: request} = context) do
    request = %{request | verified?: true}
    {:ok, %{context | request: request}}
  end

  defp missing_header_message(header),
    do: "Request missing #{header} header and could not be verified"

  defp validate_timestamp(slack_timestamp) do
    timestamp = String.to_integer(slack_timestamp)
    local_timestamp = GregorianDateTime.to_seconds()

    if abs(local_timestamp - timestamp) < 300,
      do: {:ok, timestamp},
      else: {:error, :stale_timestamp}
  end
end
