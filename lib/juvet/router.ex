defmodule Juvet.Router do
  alias Juvet.Router.{Platform, Route, RouteFinder}

  defmodule RouteError do
    @moduledoc """
    Exception raised when an exception is found within a route..
    """
    defexception status: 404,
                 message: "invalid route",
                 router: nil

    def exception(opts) do
      message = Keyword.fetch!(opts, :message)
      router = Keyword.fetch!(opts, :router)

      %RouteError{
        message: message,
        router: router
      }
    end
  end

  defmacro __using__(_opts) do
    quote do
      unquote(prelude())
    end
  end

  defp prelude do
    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :juvet_platforms, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    platforms = env.module |> Module.get_attribute(:juvet_platforms)

    quote do
      def __platforms__, do: unquote(Macro.escape(platforms))
    end
  end

  defmacro action(action, options \\ []) do
    IO.puts("adding action...")

    quote do
      Route.new(:action, unquote(action), unquote(options))
    end
  end

  defmacro command(command, options \\ []) do
    IO.puts("adding command...")

    quote do
      Route.new(:command, unquote(command), unquote(options))
    end
  end

  defmacro platform(platform, do: block) do
    # I Don't think this is the way to do it all
    # We need to add a context to the current platform and allow the `command`, `action`, etc. to work off of the
    # current platform in the context. I believe this is what scope -> routes do in Phoenix?
    """
    routes =
      case Macro.decompose_call(block) do
        :error -> []
        {_name, routes} -> routes
      end

      add_platform(platform, routes)
    """

    """
    block =
      quote do
        unquote(block)
      end
    """

    quote do
      IO.puts("unquote the block first")
      # routes = [unquote(block)] |> IO.inspect()
      routes = []

      IO.puts("unquoted...")

      case Platform.new(unquote(platform)) |> Platform.validate() do
        {:ok, platform} ->
          platform =
            Enum.reduce(routes, platform, fn route, platform ->
              case Platform.put_route(platform, route) do
                {:ok, platform} ->
                  platform

                {:error, {:unknown_platform, route_info}} ->
                  platform = Keyword.fetch!(route_info, :platform)

                  raise RouteError,
                    message: "Platform `#{platform.platform.platform}` is not valid.",
                    router: __MODULE__
              end
            end)

          @juvet_platforms platform

        {:error, :unknown_platform} ->
          raise RouteError,
            message: "Platform `#{unquote(platform)}` is not valid.",
            router: __MODULE__
      end
    end
  end

  def exists?(mod) do
    Keyword.has_key?(mod.__info__(:functions), :__platforms__)
  rescue
    UndefinedFunctionError -> false
  end

  def find_route(router, request) do
    RouteFinder.find(platforms(router), request)
  end

  def platforms(router) do
    router.__platforms__()
  end

  defp add_platform(platform, routes) do
    IO.inspect(routes, label: "routes")

    quote do
      case Platform.new(unquote(platform)) |> Platform.validate() do
        {:ok, platform} ->
          platform =
            Enum.reduce(unquote(routes), platform, fn route, platform ->
              case Platform.put_route(platform, route) do
                {:ok, platform} ->
                  platform

                {:error, {:unknown_platform, route_info}} ->
                  platform = Keyword.fetch!(route_info, :platform)

                  raise RouteError,
                    message: "Platform `#{platform.platform.platform}` is not valid.",
                    router: __MODULE__
              end
            end)

          @juvet_platforms platform

        {:error, :unknown_platform} ->
          raise RouteError,
            message: "Platform `#{unquote(platform)}` is not valid.",
            router: __MODULE__
      end
    end
  end
end
