defmodule Juvet.Receivers.SlackRTMReceiver do
  use GenServer

  defmodule State do
    defstruct bot: nil, parameters: %{}
  end

  def start(bot_supervisor, bot, parameters = %{token: _token}) do
    Supervisor.start_child(
      bot_supervisor,
      {__MODULE__, [bot, parameters]}
    )
  end

  # Client API

  def start_link(init_arg = [_bot, _parameters], options \\ []) do
    GenServer.start_link(__MODULE__, init_arg, options)
  end

  # Server Callbacks

  def init([bot, parameters]) do
    send(self(), :connect_slack_rtm)

    {:ok, %State{bot: bot, parameters: parameters}}
  end

  def handle_info(
        :connect_slack_rtm,
        state = %{bot: bot, parameters: parameters}
      ) do
    # TODO: Call either connect or start based on the `via` parameter in state
    # TODO: Handle an error here

    {:ok, _pid} = Juvet.Connection.SlackRTM.connect(bot, parameters)

    {:noreply, state}
  end
end
