# NOTE: This will eventually replace the BotFactory (and renamed) once the new
# process architecture is in place

defmodule Juvet.BotShop do
  use GenServer

  @moduledoc """
  A Module for instructing a supervisor on adding and removing bot
  processes.
  """

  # Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  # Server Callbacks

  def init(config) do
    {:ok, %{config: config}}
  end
end
