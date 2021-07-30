defmodule Juvet.Router do
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

  defmacro platform(platform, do: block) do
    add_platform(platform, block)
  end

  def platforms(router) do
    router.__platforms__()
  end

  defp add_platform(platform, block) do
    quote do
      # TODO: I believe this is running the block right now. Do we want that?
      # Platform.new(unquote(platform), unquote(block))?
      @juvet_platforms {unquote(platform), unquote(block)}
    end
  end
end
