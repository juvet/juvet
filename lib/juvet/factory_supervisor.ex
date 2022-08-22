defmodule Juvet.FactorySupervisor do
  @moduledoc """
  The Supervisor for a collection of `Juvet.BotSupervisor` processes.
  """

  use DynamicSupervisor

  # Client API

  @doc """
  Starts a `Juvet.FactorySupervisor` supervisor linked to the current process.
  """
  def start_link(_args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Creates a `Juvet.Bot` process with the specified `module` and binary or atom
  based `name` underneath the `pid` `FactorySupervisor` process.

  ## Example

  ```
  {:ok, bot} = Juvet.FactorySupervisor.add_bot(factory_supervisor, MyBot, "MyBot")
  {:ok, bot} = Juvet.FactorySupervisor.add_bot(factory_supervisor, MyBot, :my_bot)
  ```
  """
  @spec add_bot(pid(), module(), String.t()) :: {:ok, pid()} | {:error, any()}
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

  @doc false
  @impl true
  def init(:ok) do
    opts = [strategy: :one_for_one]

    DynamicSupervisor.init(opts)
  end
end
