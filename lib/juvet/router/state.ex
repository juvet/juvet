defmodule Juvet.Router.State do
  @moduledoc false

  alias Juvet.Router.{Platform, RouteError}

  @platforms :juvet_platforms

  @spec init(module()) :: :ok
  def init(module), do: put_platforms(module, [])

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

  @spec put_platform!(module(), Juvet.Router.Platform.t()) :: :ok
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

  @spec put_platform(module(), Juvet.Router.Platform.t()) :: :ok
  def put_platform(module, platform) do
    platforms = get_platforms(module)

    platforms = [platform | platforms]

    put_platforms(module, platforms)
  end

  @spec put_route_on_top!(module(), Juvet.Router.Router.t()) :: Juvet.Router.Route.t()
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

        platform = Keyword.fetch!(route_info, :platform)
        route = Keyword.fetch!(route_info, :route)

        raise RouteError,
          message:
            "Route `#{route.route}` (#{route.type}) for `#{platform.platform.platform}` not found.",
          router: module
    end

    route
  end

  defp put_platforms(module, platforms), do: Module.put_attribute(module, @platforms, platforms)
end
