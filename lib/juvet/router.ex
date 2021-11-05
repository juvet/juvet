defmodule Juvet.Router do
  alias Juvet.Router.{Platform, Route}

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

  def platforms(router) do
    router.__platforms__()
  end

  defp add_platform(platform, block) do
    quote do
      platform = Platform.new(unquote(platform))

      # TODO
      route = unquote(block)
      # Platform.put_route(platform, route)

      @juvet_platforms platform
    end
  end
end
