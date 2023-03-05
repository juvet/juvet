defmodule Juvet.Router do
  alias Juvet.Router
  alias Juvet.Router.{Middleware, Route, RouteFinder}

  defmacro __using__(_opts) do
    quote do
      unquote(prelude())
    end
  end

  defp prelude do
    quote do
      import unquote(__MODULE__)

      Router.State.init(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    middlewares = env.module |> Router.State.get_middlewares()
    platforms = env.module |> Router.State.get_platforms()

    quote do
      def __platforms__, do: unquote(Macro.escape(platforms))
      def __middlewares__, do: unquote(Macro.escape(middlewares))
    end
  end

  defmacro action(action, options \\ []) do
    quote do
      Router.State.put_route_on_top!(
        __MODULE__,
        Route.new(:action, unquote(action), unquote(options))
      )
    end
  end

  defmacro command(command, options \\ []) do
    quote do
      Router.State.put_route_on_top!(
        __MODULE__,
        Route.new(:command, unquote(command), unquote(options))
      )
    end
  end

  defmacro event(event, options \\ []) do
    quote do
      Router.State.put_route_on_top!(
        __MODULE__,
        Route.new(:event, unquote(event), unquote(options))
      )
    end
  end

  defmacro include(module, options \\ []) do
    quote do
      Router.State.put_middleware!(
        __MODULE__,
        Middleware.new(unquote(module), unquote(options))
      )
    end
  end

  defmacro option_load(action_id, options \\ []) do
    quote do
      Router.State.put_route_on_top!(
        __MODULE__,
        Route.new(:option_load, unquote(action_id), unquote(options))
      )
    end
  end

  defmacro middleware(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro platform(platform, do: block) do
    quote do
      platform = Router.State.put_platform!(__MODULE__, unquote(platform))
      Router.State.put_default_routes_on_top!(__MODULE__, platform)

      unquote(block)
    end
  end

  defmacro view_closed(callback_id, options \\ []) do
    quote do
      Router.State.put_route_on_top!(
        __MODULE__,
        Route.new(:view_closed, unquote(callback_id), unquote(options))
      )
    end
  end

  defmacro view_submission(callback_id, options \\ []) do
    quote do
      Router.State.put_route_on_top!(
        __MODULE__,
        Route.new(:view_submission, unquote(callback_id), unquote(options))
      )
    end
  end

  def exists?(mod) do
    Keyword.has_key?(mod.__info__(:functions), :__platforms__)
  rescue
    UndefinedFunctionError -> false
  end

  def find_middleware(middlewares, opts \\ [])

  def find_middleware(middlewares, partial: true) do
    middlewares
    |> Enum.filter(fn %{partial: partial} -> partial != false end)
    |> case do
      [_ | _] = partial_middleware -> {:ok, partial_middleware}
      [] -> {:error, :no_middleware}
    end
  end

  def find_middleware(middlewares, _opts) do
    case middlewares do
      [_ | _] = middlwares -> {:ok, middlwares}
      [] -> {:error, :no_middleware}
    end
  end

  def find_route(router, request) do
    RouteFinder.find(platforms(router), request)
  end

  def middlewares(router) do
    case Code.ensure_compiled(router) do
      {:module, _} -> router.__middlewares__()
      {:error, _} -> []
    end
  end

  def platforms(router) do
    router.__platforms__()
  end

  # Behaviour
  @callback new(atom()) :: struct()

  @callback find_route(%{platform: Juvet.Router.Platform.t()}, Juvet.Router.Request.t()) ::
              {:ok, Juvet.Router.Route.t()} | {:error, term()}

  @callback get_default_routes() :: {:ok, [Juvet.Router.Route.t()]} | {:error, term()}

  @callback handle_route(%{platform: Juvet.Router.Platform.t()}) ::
              {:ok, Juvet.Router.Route.t()} | {:error, term()}

  @callback validate(Juvet.Router.Platform.t()) ::
              {:ok, Juvet.Router.Platform.t()} | {:error, term()}

  @callback validate_route(%{platform: Juvet.Router.Platform.t()}, Juvet.Router.Route.t(), map()) ::
              {:ok, Juvet.Router.Route.t()} | {:error, term()}
end
