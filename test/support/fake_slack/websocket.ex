defmodule Juvet.FakeSlack.Websocket do
  @behaviour :cowboy_websocket

  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def set_client_pid(pid) do
    Application.put_env(:slack, :test_client_pid, pid)
  end

  def websocket_init(state) do
    send_message_to_client_pid({:websocket_connected, self()})

    {:ok, state}
  end

  def websocket_handle({:text, "ping"}, state) do
    {:reply, {:text, "pong"}, state}
  end

  def websocket_handle({:text, message}, state) do
    send_message_to_client_pid({:message_received, Poison.decode!(message)})

    {:reply, {:text, message}, state}
  end

  def websocket_info(message, state) do
    {:reply, {:text, message}, state}
  end

  def websocket_terminate(_reason, _req, _state), do: :ok

  defp send_message_to_client_pid(message) do
    pid = Application.get_env(:slack, :test_client_pid)

    if pid, do: send(pid, message)
  end
end
