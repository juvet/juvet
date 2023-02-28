defmodule Juvet.Router do
  alias Juvet.Router
  alias Juvet.Router.{Route, RouteFinder}

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

  defmacro option_load(action_id, options \\ []) do
    quote do
      Router.State.put_route_on_top!(
        __MODULE__,
        Route.new(:option_load, unquote(action_id), unquote(options))
      )
    end
  end

  defmacro platform(platform, do: block) do
    quote do
      Router.State.put_platform!(__MODULE__, unquote(platform))
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

  def find_route(router, request) do
    RouteFinder.find(platforms(router), request)
  end

  def middlewares(router) do
    router.__middlewares__()
  end

  def platforms(router) do
    router.__platforms__()
  end

  # Behaviour
  @callback new(atom()) :: struct()

  @callback find_route(%{platform: Juvet.Router.Platform.t()}, Juvet.Router.Request.t()) ::
              {:ok, Juvet.Router.Route.t()} | {:error, term()}

  @callback validate(Juvet.Router.Platform.t()) ::
              {:ok, Juvet.Router.Platform.t()} | {:error, term()}

  @callback validate_route(%{platform: Juvet.Router.Platform.t()}, Juvet.Router.Route.t(), map()) ::
              {:ok, Juvet.Router.Route.t()} | {:error, term()}
end
