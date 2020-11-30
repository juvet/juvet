defmodule Juvet.ReceiverTarget do
  @moduledoc """
  Defines the behavior that allows modules to generate receiver modules
  based on a type defined as an Atom.
  """

  defmacro __using__(_) do
    quote do
      @doc """
      Generates a `Juvet.Receivers.SlackRTMReceiver`.
      """
      def generate_receiver(:slack_rtm), do: generate_receiver(:slack_RTM)

      @doc """
      Generates a receiver based on the type defined as an Atom.
      """
      def generate_receiver(type), do: receiver_module(type)

      @doc false
      defp receiver_module(type) do
        receiver =
          Macro.camelize("#{type}_receiver")
          |> String.replace("_", "")

        :"Elixir.Juvet.Receivers.#{receiver}"
      end
    end
  end
end
