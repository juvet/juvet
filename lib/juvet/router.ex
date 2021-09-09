defmodule Juvet.Router do
  alias Juvet.Router.Platform

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
    IO.puts("******************")
    IO.puts("ADDING A COMMAND")
    IO.inspect(command)
    IO.puts("******************")

    quote do
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
      @juvet_platforms Platform.new(unquote(platform))
      # @juvet_platforms {unquote(platform), unquote(block)}
    end
  end
end
