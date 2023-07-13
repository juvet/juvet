defmodule Juvet.Middleware.BuildDefaultResponseTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.BuildDefaultResponse
  alias Juvet.Router.{Request, Route}

  describe "call/1" do
    setup do
      request = Request.new(%{})
      route = Route.new(:command, "command")

      [context: %{configuration: Juvet.configuration(), request: request, route: route}]
    end

    test "adds the default response to the request in the context", %{context: context} do
      assert {:ok, %{response: response}} = BuildDefaultResponse.call(context)
      assert response.status == 200
      assert response.body == ""
    end

    test "does not add the default response unless there is a request" do
      assert {:ok, context} = BuildDefaultResponse.call(%{})
      refute Map.get(context, :response)
    end

    test "sets it to a redirect if the request is an oauth Slack in the request phase", %{
      context: %{request: request, route: route} = context
    } do
      request = %{request | platform: :slack, method: "GET", path: "/auth/slack"}
      route = %{route | type: :oauth, route: :request}

      assert {:ok, %{response: response}} =
               BuildDefaultResponse.call(%{context | request: request, route: route})

      assert response.status == 302

      assert response.body =~
               ~r{https://slack.com/oauth/v2/authorize\?app_id=.*client_id=.*&client_secret=.*redirect_uri=.*+}
    end

    test "does not add the default response if the request is an oauth Slack in the callback phase",
         %{
           context: %{request: request, route: route} = context
         } do
      request = %{request | platform: :slack, method: "GET", path: "/auth/slack/callback"}
      route = %{route | type: :oauth, route: :callback}

      assert {:ok, context} =
               BuildDefaultResponse.call(%{context | request: request, route: route})

      refute Map.get(context, :response)
    end
  end
end
