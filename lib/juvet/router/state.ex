defmodule Juvet.Router.State do
  @moduledoc false

  alias Juvet.Router.{Middleware, Platform, RouteError}

  @middlewares :juvet_middlewares
  @platforms :juvet_platforms

  @spec init(module()) :: :ok
  def init(module) do
    put_middlewares(module, Middleware.system())
    put_platforms(module, [])
  end

  @spec get_middlewares(module()) :: list(Juvet.Router.Middleware.t())
  def get_middlewares(module) do
    Module.get_attribute(module, @middlewares)
  end

  @spec get_platforms(module()) :: list(Juvet.Router.Platform.t())
  def get_platforms(module) do
    Module.get_attribute(module, @platforms)
  end

  @spec pop_platform(module()) :: Juvet.Router.Platform.t()
  def pop_platform(module) do
    {platform, platforms} = List.pop_at(get_platforms(module), 0)

    put_platforms(module, platforms)

    platform
  end

  @spec put_middleware!(module(), Juvet.Router.Middleware.t()) :: :ok
  def put_middleware!(module, middleware) do
    middlewares = get_middlewares(module)

    middlewares = Middleware.put_middleware(middlewares, middleware)

    put_middlewares(module, middlewares)
  end

  @spec put_platform!(module(), atom()) :: Juvet.Router.Platform.t()
  def put_platform!(module, platform) when is_atom(platform) do
    case Platform.new(platform) |> Platform.validate() do
      {:ok, platform} ->
        put_platform(module, platform)

      {:error, :unknown_platform} ->
        raise RouteError,
          message: "Platform `#{platform}` is not valid.",
          router: module
    end
  end

  @spec put_platform(module(), Juvet.Router.Platform.t()) :: Juvet.Router.Platform.t()
  def put_platform(module, platform) do
    platforms = get_platforms(module)

    platforms =
      case get_platform(platforms, platform.platform) do
        nil -> [platform | platforms]
        existing_platform -> replace_platform(platforms, existing_platform, platform)
      end

    put_platforms(module, platforms)

    platform
  end

  @spec put_default_routes_on_top!(module(), Juvet.Router.Platform.t()) ::
          Juvet.Router.Platform.t() | nil
  def put_default_routes_on_top!(module, platform) do
    case Platform.put_default_routes(platform) do
      {:ok, platform} ->
        put_platform(module, platform)
    end
  end

  @spec put_route_on_top!(module(), Juvet.Router.Route.t()) :: Juvet.Router.Route.t() | nil
  def put_route_on_top!(module, route) do
    platform = pop_platform(module)

    case Platform.put_route(platform, route) do
      {:ok, platform} ->
        put_platform(module, platform)

      {:error, {:unknown_platform, route_info}} ->
        put_platform(module, platform)

        platform = Keyword.fetch!(route_info, :platform)

        raise RouteError,
          message: "Platform `#{platform.platform.platform}` is not valid.",
          router: module

      {:error, {:unknown_route, route_info}} ->
        put_platform(module, platform)

        router = Keyword.fetch!(route_info, :router)
        route = Keyword.fetch!(route_info, :route)

        raise RouteError,
          message:
            "Route `#{route.route}` (#{route.type}) for `#{router.platform.platform}` not found.",
          router: module
    end

    route
  end

  defp get_platform(platforms, platform),
    do:
      Enum.find(platforms, fn %{platform: existing_platform} ->
        to_string(platform) == to_string(existing_platform)
      end)

  defp put_middlewares(module, middlewares),
    do: Module.put_attribute(module, @middlewares, middlewares)

  defp put_platforms(module, platforms), do: Module.put_attribute(module, @platforms, platforms)

  defp replace_platform(platforms, existing_platform, new_platform) do
    platforms
    |> Enum.reduce([], fn platform, new_platforms ->
      selected =
        if platform.platform == existing_platform.platform, do: new_platform, else: platform

      [selected | new_platforms]
    end)
  end
end
