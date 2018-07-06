defmodule Juvet do
  use Application

  def start(_types, _args) do
    children = [
      Supervisor.Spec.supervisor(PubSub, []),
      Supervisor.Spec.supervisor(Juvet.BotFactorySupervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
