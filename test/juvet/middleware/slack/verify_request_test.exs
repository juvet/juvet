defmodule Juvet.Middleware.Slack.VerifyRequestTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  alias Juvet.Middleware.Slack.VerifyRequest
  alias Juvet.Router.Request

  describe "call/1" do
    setup do
      params = %{"token" => "TOKEN", "team_id" => "T12345"}
      body = params |> URI.encode_query()

      signing_secret = generate_slack_signing_secret()
      config = [slack: [oauth_request_endpoint: "/auth/slack", signing_secret: signing_secret]]

      timestamp = generate_slack_timestamp()
      signature = generate_slack_signature(params, signing_secret, timestamp)

      request =
        Request.new(%{
          private: %{juvet: %{raw_body: body}},
          req_headers: [
            {"x-slack-request-timestamp", timestamp},
            {"x-slack-signature", signature}
          ]
        })

      [
        context: %{
          configuration: config,
          request: %{request | platform: :slack}
        },
        signature: signature,
        timestamp: timestamp
      ]
    end

    test "returns the context for a valid request", %{context: context} do
      assert {:ok, ctx} = VerifyRequest.call(context)
      assert ctx[:request].verified?
    end

    test "returns the context for a valid request when verifying is turned off",
         %{context: %{configuration: configuration} = context} do
      config = Keyword.merge(configuration, slack: [verify_requests: false])

      assert {:ok, ctx} =
               VerifyRequest.call(%{
                 context
                 | configuration: config
               })

      assert ctx[:request].verified?
    end

    test "returns the context for a valid oauth request", %{
      context: %{request: request} = context
    } do
      request = %{request | method: "GET", path: "/auth/slack?scopes=chat:write", headers: []}

      assert {:ok, ctx} = VerifyRequest.call(%{context | request: request})
      assert ctx[:request].verified?
    end

    test "returns an error if the Slack timestamp header is not available", %{
      context: %{request: request} = context,
      signature: signature
    } do
      request = %{request | headers: [{"x-slack-signature", signature}]}

      message = "Request missing x-slack-request-timestamp header and could not be verified"

      assert {:error, %Juvet.InvalidRequestError{message: ^message}} =
               VerifyRequest.call(%{
                 context
                 | request: request
               })
    end

    test "returns an error if there is no raw body set", %{
      context: %{request: request} = context
    } do
      request = %{request | private: nil}

      assert {:error,
              %Juvet.InvalidRequestError{
                message:
                  "Request body was empty and could not be verified. Ensure you are caching the request body in a body reader plug."
              }} =
               VerifyRequest.call(%{
                 context
                 | request: request
               })
    end

    test "returns an error if the timestamp is older than five minutes", %{
      context: %{request: request} = context,
      signature: signature
    } do
      timestamp =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-6 * 60)
        |> Juvet.GregorianDateTime.to_seconds()
        |> to_string

      request = %{
        request
        | headers: [
            {"x-slack-request-timestamp", timestamp},
            {"x-slack-signature", signature}
          ]
      }

      assert {:error,
              %Juvet.InvalidRequestError{
                message: "Stale Slack request."
              }} =
               VerifyRequest.call(%{
                 context
                 | request: request
               })
    end

    test "returns an error if the signing signature is not configured", %{
      context: %{configuration: configuration} = context
    } do
      config = Keyword.merge(configuration, slack: [])

      assert {:error,
              %Juvet.ConfigurationError{
                message: "Slack signing secret missing in Juvet configuration."
              }} =
               VerifyRequest.call(%{
                 context
                 | configuration: config
               })
    end

    test "returns an error if the Slack signature does not match", %{
      context: %{request: request} = context,
      timestamp: timestamp
    } do
      request = %{
        request
        | headers: [
            {"x-slack-request-timestamp", timestamp},
            {"x-slack-signature", "blah"}
          ]
      }

      assert {:error,
              %Juvet.InvalidRequestError{
                message: "Invalid Slack request. Signature mismatch."
              }} =
               VerifyRequest.call(%{
                 context
                 | request: request
               })
    end

    test "returns an error for an oauth request that is not configured", %{
      context: %{configuration: configuration, request: request} = context
    } do
      config = Keyword.merge(configuration, slack: [])

      request = %{request | method: "GET", path: "/auth/slack?scopes=chat:write", headers: []}

      assert {:error, _error} =
               VerifyRequest.call(%{context | configuration: config, request: request})
    end

    test "returns an error for an oauth request that does not match the configured endpoint", %{
      context: %{request: request} = context
    } do
      request = %{request | method: "GET", path: "/oauth/slack?scopes=chat:write", headers: []}

      assert {:error, _error} = VerifyRequest.call(%{context | request: request})
    end
  end
end
