defmodule Juvet.Router.RequestIdentifierTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Request, RequestIdentifier}

  setup do
    [configuration: Juvet.configuration()]
  end

  describe "platform/2" do
    test "returns slack for a Slack request with a header", %{
      configuration: configuration
    } do
      request =
        Request.new(%{
          req_headers: [{"x-slack-signature", "blah"}]
        })

      assert :slack = RequestIdentifier.platform(request, configuration)
    end

    test "returns slack for a slack oauth request", %{configuration: configuration} do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/auth/slack"
        })

      assert :slack = RequestIdentifier.platform(request, configuration)
    end

    test "returns unknown if the oauth request does not match any request in config", %{
      configuration: configuration
    } do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/auth/blah"
        })

      assert :unknown = RequestIdentifier.platform(request, configuration)
    end

    test "returns unknown if the request cannot be identified", %{
      configuration: configuration
    } do
      request = Request.new(%{platform: :slack})

      assert :unknown = RequestIdentifier.platform(request, configuration)
    end
  end

  describe "oauth?/2" do
    test "returns true for a slack oauth request", %{configuration: configuration} do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/auth/slack?code=blah"
        })

      assert RequestIdentifier.oauth?(%{request | platform: :slack}, configuration)
    end

    test "returns false for a slack oauth request with a different request path", %{
      configuration: configuration
    } do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/oauth/slack"
        })

      refute RequestIdentifier.oauth?(%{request | platform: :slack}, configuration)
    end

    test "returns false for an unknown oauth request", %{configuration: configuration} do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/auth/slack"
        })

      refute RequestIdentifier.oauth?(request, configuration)
    end
  end

  describe "oauth_phase/2" do
    test "returns request for a slack oauth request", %{
      configuration: configuration
    } do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/auth/slack?code=blah"
        })

      assert RequestIdentifier.oauth_path(%{request | platform: :slack}, configuration) ==
               "request"
    end

    test "returns callback for a slack oauth callback request", %{
      configuration: configuration
    } do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/auth/slack/callback?code=blah"
        })

      assert RequestIdentifier.oauth_path(%{request | platform: :slack}, configuration) ==
               "callback"
    end

    test "returns nil for a slack oauth request with a different request path", %{
      configuration: configuration
    } do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/oauth/slack/callback"
        })

      refute RequestIdentifier.oauth_path(%{request | platform: :slack}, configuration)
    end

    test "returns nil for an unknown oauth request", %{configuration: configuration} do
      request =
        Request.new(%{
          method: "GET",
          request_path: "/auth/slack"
        })

      refute RequestIdentifier.oauth?(request, configuration)
    end
  end
end
