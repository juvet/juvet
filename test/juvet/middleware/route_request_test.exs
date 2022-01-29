defmodule Juvet.Middleware.RouteRequestTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.RouteRequest
  alias Juvet.Router.{Request, Route}

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      command("/test", to: "controller#action")
    end
  end

  describe "call/1" do
    setup do
      configuration = [router: MyRouter]
      params = %{"command" => "/test"}
      request = Request.new(%{params: params})
      request = %{request | verified?: true, platform: :slack}

      [context: %{configuration: configuration, request: request}]
    end

    test "adds a route and a path to the context if the route was found", %{
      context: context
    } do
      assert {:ok, ctx} = RouteRequest.call(context)

      assert ctx[:route] == %Route{
               route: "/test",
               type: :command,
               options: [to: "controller#action"]
             }

      assert ctx[:path] == "controller#action"
    end

    test "returns an error if the route was not found", %{
      context: %{request: request} = context
    } do
      request = %{request | params: %{"command" => "/blah"}}
      context = %{context | request: request}

      assert {:error,
              %Juvet.RoutingError{
                message: "No route found for the request.",
                request: request
              }} = RouteRequest.call(context)
    end

    test "returns an error if router is not configured", %{context: context} do
      configuration = []
      context = %{context | configuration: configuration}

      assert {:error,
              %Juvet.ConfigurationError{
                message: "Router missing in Juvet configuration."
              }} = RouteRequest.call(context)
    end

    test "returns an error if router could not be found", %{context: context} do
      configuration = [router: Blah]
      context = %{context | configuration: configuration}

      assert {:error,
              %Juvet.ConfigurationError{
                message: "Router Blah configured in Juvet configuration is not found."
              }} = RouteRequest.call(context)
    end

    test "returns an error if the request was not verified", %{
      context: %{request: request} = context
    } do
      request = %{request | verified?: false}
      context = %{context | request: request}

      assert {:error, %Juvet.RoutingError{message: "Request was not verified."}} =
               RouteRequest.call(context)
    end
  end
end
