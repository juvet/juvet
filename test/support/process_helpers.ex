defmodule Juvet.ProcessHelpers do
  @moduledoc """
  Test helpers to aid in testing processes
  """

  import ExUnit.Callbacks, only: [start_supervised!: 1]

  def setup_with_supervised_application!(_context) do
    start_supervised_application!()
    :ok
  end

  def start_supervised_application! do
    start_supervised!(%{
      id: Juvet,
      start: {Juvet, :start, [:normal, []]}
    })
  end
end
