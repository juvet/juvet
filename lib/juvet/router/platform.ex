defmodule Juvet.Router.Platform do
  defstruct platform: nil

  def new(platform) do
    %__MODULE__{platform: platform}
  end
end
