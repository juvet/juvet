defmodule Juvet.FactorySupervisor do
  use DynamicSupervisor

  # Client API

  def start_link(_args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, [])
  end

  def add_bot(pid, module, name) when is_binary(name),
    do: add_bot(pid, module, String.to_atom(name))

  def add_bot(pid, module, name) do
    case DynamicSupervisor.start_child(
           pid,
           {Juvet.BotSupervisor, [module, name]}
         ) do
      {:ok, bot_supervisor} ->
        Juvet.BotSupervisor.get_bot(bot_supervisor, module)

      {:error, {:shutdown, {:failed_to_start_child, _module, child_error}}} ->
        {:error, child_error}

      {:error, error} ->
        {:error, error}
    end
  end

  # Server Callbacks

  def init(:ok) do
    opts = [strategy: :one_for_one]

    DynamicSupervisor.init(opts)
  end
end
