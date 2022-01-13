defmodule Juvet.ConfigurationError do
  @moduledoc """
  Exception raised when there is an issue with the Juvet configuration.
  """
  defexception message: "Configuration for Juvet is invalid"

  def exception(message) do
    %__MODULE__{message: message}
  end
end
