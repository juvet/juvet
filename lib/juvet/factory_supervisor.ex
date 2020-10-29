defmodule Juvet.FactorySupervisor do
  use DynamicSupervisor

  # Client API

  def start_link(_args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, [])
  end

  def add_bot(pid, module, name) when is_binary(name),
    do: add_bot(pid, module, String.to_atom(name))

  def add_bot(pid, module, name) do
    DynamicSupervisor.start_child(
      pid,
      bot_spec(module, %{}, name: name)
    )
  end

  # Server Callbacks

  def init(:ok) do
    opts = [strategy: :one_for_one]

    DynamicSupervisor.init(opts)
  end

  defp bot_spec(bot, parameters, options) do
    %{
      id: bot,
      start: {bot, :start_link, [parameters, options]}
    }
  end
end
