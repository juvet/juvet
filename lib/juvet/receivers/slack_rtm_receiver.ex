defmodule Juvet.Receivers.SlackRTMReceiver do
  use GenServer

  def start(bot_supervisor, parameters = %{token: _token}) do
    Supervisor.start_child(
      bot_supervisor,
      {__MODULE__, parameters}
    )
  end

  # Client API

  def start_link(parameters, options \\ []) do
    GenServer.start_link(__MODULE__, parameters, options)
  end

  # Server Callbacks

  def init(parameters) do
    send(self(), :connect_slack_rtm)

    {:ok, parameters}
  end

  def handle_info(:connect_slack_rtm, state) do
    # TODO: Call either connect or start based on the `via` parameter in state
    # TODO: Handle an error here

    {:ok, _pid} = Juvet.Connection.SlackRTM.connect(state)

    {:noreply, state}
  end
end
