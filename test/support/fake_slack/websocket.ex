defmodule Juvet.FakeSlack.Websocket do
  @behaviour :cowboy_websocket_handler

  # 5 second timeout
  @activity_timeout 5000

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def set_client_pid(pid) do
    Application.put_env(:slack, :test_client_pid, pid)
  end

  def websocket_init(_type, req, _opts) do
    state = %{}

    send_message_to_client_pid({:websocket_connected, self()})

    {:ok, req, state, @activity_timeout}
  end

  def websocket_handle({:text, "ping"}, req, state) do
    {:reply, {:text, "pong"}, req, state}
  end

  def websocket_handle({:text, message}, req, state) do
    send_message_to_client_pid({:message_received, Poison.decode!(message)})

    {:ok, req, state}
  end

  def websocket_info(message, req, state) do
    {:reply, {:text, message}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  defp send_message_to_client_pid(message) do
    pid = Application.get_env(:slack, :test_client_pid)

    if pid, do: send(pid, message)
  end
end
