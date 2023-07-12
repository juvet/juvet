defmodule Juvet.Router.RequestIdentifierTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Request, RequestIdentifier}

  setup do
    [configuration: Juvet.configuration()]
  end

  test "platform/2 returns slack for a Slack request with a header", %{
    configuration: configuration
  } do
    request =
      Request.new(%{
        req_headers: [{"x-slack-signature", "blah"}]
      })

    assert :slack = RequestIdentifier.platform(request, configuration)
  end

  test "platform/2 returns slack for a slack oauth request", %{configuration: configuration} do
    request =
      Request.new(%{
        method: "GET",
        request_path: "/auth/slack"
      })

    assert :slack = RequestIdentifier.platform(request, configuration)
  end

  test "platform/2 returns unknown if the oauth request does not match any request in config", %{
    configuration: configuration
  } do
    request =
      Request.new(%{
        method: "GET",
        request_path: "/auth/blah"
      })

    assert :unknown = RequestIdentifier.platform(request, configuration)
  end

  test "platform/2 returns unknown if the request cannot be identified", %{
    configuration: configuration
  } do
    request = Request.new(%{platform: :slack})

    assert :unknown = RequestIdentifier.platform(request, configuration)
  end

  test "oauth?/2 returns true for a slack oauth request", %{configuration: configuration} do
    request =
      Request.new(%{
        method: "GET",
        request_path: "/auth/slack?code=blah"
      })

    assert RequestIdentifier.oauth?(%{request | platform: :slack}, configuration)
  end

  test "oauth?/2 returns false for a slack oauth request with a different request path", %{
    configuration: configuration
  } do
    request =
      Request.new(%{
        method: "GET",
        request_path: "/oauth/slack"
      })

    refute RequestIdentifier.oauth?(%{request | platform: :slack}, configuration)
  end

  test "oauth?/2 returns false for an unknown oauth request", %{configuration: configuration} do
    request =
      Request.new(%{
        method: "GET",
        request_path: "/oauth/slack"
      })

    refute RequestIdentifier.oauth?(request, configuration)
  end
end
