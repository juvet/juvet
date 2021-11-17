defmodule Juvet.Router.PlatformFactory do
  def new(platform) do
    try do
      String.to_existing_atom(
        "Elixir.Juvet.Router.#{Macro.camelize(to_string(platform))}Platform"
      )
    rescue
      _ in ArgumentError -> new(:unknown)
    end
  end
end
