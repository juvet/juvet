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

  defmacro command(command, options \\ []) do
    quote do
      Route.new(:command, unquote(command), unquote(options))
    end
  end

  defmacro platform(platform, do: block) do
    add_platform(platform, block)
  end

  def exists?(mod) do
    try do
      Keyword.has_key?(mod.__info__(:functions), :__platforms__)
    rescue
      UndefinedFunctionError -> false
    end
  end

  def find_route(router, request) do
    RouteFinder.find(platforms(router), request)
  end

  def platforms(router) do
    router.__platforms__()
  end

  defp add_platform(platform, block) do
    quote do
      platform = Platform.new(unquote(platform))

      route = unquote(block)

      platform =
        case Platform.put_route(platform, route) do
          {:ok, platform} ->
            platform

          {:error, {:unknown_platform, route_info}} ->
            platform = Keyword.fetch!(route_info, :platform)

            raise RouteError,
              message: "Platform `#{platform.platform.platform}` is not valid.",
              router: __MODULE__
        end

      @juvet_platforms platform
    end
  end
end
