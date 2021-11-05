defmodule Juvet.Router.Platform do
  defstruct platform: nil, routes: []

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def push(platform, route, options) do
  end
end
