defmodule MyBot do
  use GenServer

  def start_link(state, options \\ []) do
    GenServer.start_link(__MODULE__, state, options)
  end

  def init(state) do
    {:ok, state}
  end
end
