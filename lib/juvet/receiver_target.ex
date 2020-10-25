defmodule Juvet.ReceiverTarget do
  defmacro __using__(_) do
    quote do
      def generate_receiver(:slack_rtm), do: generate_receiver(:slack_RTM)

      def generate_receiver(type), do: receiver_module(type)

      def receiver_module(type) do
        receiver =
          Macro.camelize("#{type}_receiver")
          |> String.replace("_", "")

        :"Elixir.Juvet.Receivers.#{receiver}"
      end
    end
  end
end
