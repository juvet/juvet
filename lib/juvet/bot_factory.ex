defmodule Juvet.BotFactory do
  @moduledoc """
  The top-level Supervisor for the whole factory floor.
  """

  use Supervisor

  @doc """
  Starts a `Juvet.BotFactory` supervisor linked to the current process.
  """
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @doc """
  Creates a `Juvet.Bot` process with the specified `name` and adds
  the new bot process to the `Juvet.BotSupervisor`.

  * `:name` - Can be an atom or string which will be the name of the process, so it must be unique

  ## Example

  ```
  {:ok, bot} = Juvet.BotFactory.create("MyBot")
  ```
  """
  def create(name) do
    Juvet.Superintendent.create_bot(name)
  end

  @doc """
  Creates a bot process using the configured bot module and specifies the name of the
  process as the name provided.

  This will return a `pid` of the bot if successful, otherwise a `RuntimeError` is raised.

  * `:name` - Can be an atom or string which will be the name of the process, so it must be unique
              bewteen all of the bots under the `Juvet.FactorySupervisor`.

  ## Example

  ```
  pid = Juvet.BotFactory.create!("MyBot")
  ```
  """
  def create!(name) do
    case Juvet.Superintendent.create_bot(name) do
      {:ok, bot} ->
        bot

      {:error, {:already_started, _pid}} ->
        raise RuntimeError, message: "Bot already started."

      {:error, error} ->
        raise RuntimeError, message: "Error starting bot (#{error})."
    end
  end

  @doc """
  Finds a `Juvet.Bot` process with the specified `name`.

  * `:name` - The name of the bot to find

  ## Example

  ```
  {:ok, bot} = Juvet.BotFactory.find("MyBot")
  {:error, reason} = Juvet.BotFactory.find("Some bot that does not exist")
  ```
  """
  def find(name) do
    Juvet.Superintendent.find_bot(name)
  end

  @doc """
  Finds a `Juvet.Bot` process with the specified `name`.

  This will return a `pid` of the bot if successful, otherwise a `RuntimeError` is raised.

  * `:name` - The name of the bot to find

  ## Example

  ```
  pid = Juvet.BotFactory.find!("MyBot")
  ```
  """
  def find!(name) do
    case Juvet.Superintendent.find_bot(name) do
      {:ok, bot} ->
        bot

      {:error, error} ->
        raise RuntimeError, message: error
    end
  end

  # Callbacks

  @doc false
  def init(config) do
    children = [
      {Juvet.Superintendent, config}
    ]

    opts = [strategy: :one_for_all]

    Supervisor.init(children, opts)
  end
end
