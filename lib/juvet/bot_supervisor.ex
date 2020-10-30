defmodule Juvet.BotSupervisor do
  use Supervisor

  # Client API

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [])
  end

  def get_bot(pid, module) do
    bot =
      Supervisor.which_children(pid)
      |> Enum.find(fn child -> Kernel.elem(child, 0) == module end)
      |> Kernel.elem(1)

    {:ok, bot}
  end

  # Server Callbacks

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
