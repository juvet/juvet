defmodule Juvet.Queue.InMemoryQueue do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__}])
  end

  # Server
  def init(args) do
    {:ok, args}
  end
end
