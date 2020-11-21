defmodule Juvet.BotSupervisor do
  @moduledoc """
  The Supervisor for a `Juvet.Bot` process as well as any supporting processes
  like receivers.
  """

  use Supervisor

  # Client API

  @doc """
  Starts a `Juvet.BotSupervisor` supervisor linked to the current process.

  ## Options

  * `args` - Keyword list with the module and name for the bot process.
  """
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [])
  end

  @doc """
  Returns the bot `pid` for the bot with the specified `module`.

  ## Example

  ```
  {:ok, bot} = Juvet.BotSupervisor.get_bot(supervisor, MyBot)
  ```
  """
  def get_bot(pid, module) do
    bot =
      Supervisor.which_children(pid)
      |> Enum.find(fn child -> Kernel.elem(child, 0) == module end)
      |> Kernel.elem(1)

    {:ok, bot}
  end

  # Server Callbacks

  @doc false
  def init([module, name]) do
    opts = [strategy: :one_for_one]

    Supervisor.init(
      [bot_spec(module, %{bot_supervisor: self()}, name: name)],
      opts
    )
  end

  defp bot_spec(bot, parameters, options) do
    %{
      id: bot,
      start: {bot, :start_link, [parameters, options]}
    }
  end
end
