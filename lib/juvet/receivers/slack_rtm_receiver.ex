defmodule Juvet.Receivers.SlackRTMReceiver do
  def start(bot, parameters) do
    DynamicSupervisor.start_child(bot, {Juvet.Connection.SlackRTM, parameters})
  end
end
