defmodule Juvet do
  @moduledoc """
  Juvet is an application framework to facilitate the building of conversational-based user interfaces.

  Juvet helps developers consume messages from and produce responses for popular chat-based providers.

  Juvet currently supports [Slack](https://slack.com) with support for more providers coming soon!

  ## Features

  * A *lot* more to come...

  ## Usage

  In order to use Juvet, you need to add the Juvet application to your `mix.exs` file

  ```
  # mix.exs

  def application do
    [mod: {MyApp, []}], applications [:juvet]]
  end
  ```

  You must configure Juvet for the services that you want to support:

  ```
  # config/confix.exs

  config :juvet,
    bot: MyBot,
    slack: [
      actions_endpoint: "/slack/actions",
      commands_endpoint: "/slack/commands",
      events_endpoint: "/slack/events"
    ]
  ```

  All of the logic to handle your bot interactions can be defined in your bot with callbacks:

  ```
  # lib/project/ny_bot.ex

  defmodule MyBot do
    use Juvet.Bot

    # callbacks ...

    def handle_message(:slack, message) do
      # process and handle the message
      {:reply, %{...}}
    end
  end
  ```

  ## Juvet Processes

  Once Juvet starts up it's application successfully, several processes are started:

  ```asciidoc
  +---------------+    +--------------+--+  +----------------+
  |               |    |              |     |                |
  |     Juvet     |----|  BotFactory  |-----| Superintendent |
  | (application) |    |              |     |                |
  |               |    +--------------+--+  +----------------+
  +---------------+                      |  +-------------------+
                                         |  |                   |
                                         +--| FactorySupervisor |
                                            |                   |
                                            +-------------------+
                                             |                 |
                                             |                 |
                                      +---------------+ +---------------+
                                      |               | |               |
                                      | BotSupervisor | | BotSupervisor |
                                      |               | |               |
                                      +---------------+ +---------------+
                                               |                |
                                               |                |
                                            +-----+          +-----+
                                            | Bot |          | Bot |
                                            +-----+          +-----+

  ```

  * **Juvet** - Application that starts the `Juvet.BotFactory` supervisor
  * **BotFactory** - Supervisor that starts the `Juvet.Superintendent` process
  * **Superintdendent** - The brains of the operation. Process checks the validity of the configuration and if it is configured correctly, it starts the `Juvet.FactorySupervisor` process
  * **FactorySupervisor** - Supervisor for the whole factory
  * **BotSupervisor** - Supervisor over one or many bot processes
  * **Bot** - Receives messages from the chat providers. It is responsible for processing messages and generating responses
  """

  use Application

  @doc false
  def start(_types, _args) do
    Juvet.BotFactory.start_link(configuration())
  end

  @doc """
  Returns the configuration configured for Juvet within the `Application`
  """
  @spec configuration :: Keyword.t()
  def configuration do
    Application.get_all_env(:juvet)
  end

  @doc """
  Creates a bot process using the configured bot module and specifies the name of the
  process as the name provided.

  * `:name` - Can be an atom or string which will be the name of the process, so it must be unique
              bewteen all of the bots under the `Juvet.FactorySupervisor`.

  ## Example

  ```
  {:ok, pid} = Juvet.create_bot("MyBot")
  ```
  """
  @spec create_bot(String.t()) :: {:ok, pid()} | {:error, any()}
  def create_bot(name) do
    Juvet.BotFactory.create(name)
  end

  @doc """
  Creates a bot process using the configured bot module and specifies the name of the
  process as the name provided.

  This will return a `pid` of the bot if successful, otherwise a `RuntimeError` is raised.

  * `:name` - Can be an atom or string which will be the name of the process, so it must be unique
              bewteen all of the bots under the `Juvet.FactorySupervisor`.

  ## Example

  ```
  pid = Juvet.create_bot!("MyBot")
  ```
  """
  @spec create_bot!(String.t()) :: pid()
  def create_bot!(name) do
    Juvet.BotFactory.create!(name)
  end

  @doc """
  Documents that the bot is connected to the platform so it can receive messages from the
  specified `platform` with the specified `parameters`.

  * `:bot` - The `pid` of the bot to connect to.
  * `:platform` - The platform to connect the bot with.

    The currently supported platforms are:
    * `:slack_rtm` - Connects a Slack RTM websocket connection to the specific bot receives messages across
                     Slack's RTM API.

  * `:parameters` - A `Map` of any parameters the platform needs to start up

  ## Example

  ```
  {:ok, bot} = Juvet.create_bot("MyBot")
  Juvet.connect_bot(bot, :slack_rtm, %{team_id: "T12345", token: "MY_TOKEN"})
  ```
  """
  @spec connect_bot(pid(), atom(), map()) :: :ok
  def connect_bot(bot, platform, parameters) do
    Juvet.Superintendent.connect_bot(bot, platform, parameters)
  end

  @doc """
  Finds or creates a `Juvet.Bot` process with the specified `name`.

  * `:name` - The name of the bot to find or create

  ## Example

  ```
  {:ok, bot} = Juvet.find_or_create_bot("MyBot")
  ```
  """
  @spec find_or_create_bot(String.t()) :: {:ok, pid()} | {:error, any()}
  def find_or_create_bot(name) do
    Juvet.BotFactory.find_or_create(name)
  end

  @doc """
  Finds or creates a `Juvet.Bot` process with the specified `name`.

  This will return a `pid` of the bot if successful, otherwise a `RuntimeError` is raised.

  * `:name` - The name of the bot to find or create

  ## Example

  ```
  pid = Juvet.find_or_create_bot!("MyBot")
  ```
  """
  @spec find_or_create_bot!(String.t()) :: pid()
  def find_or_create_bot!(name) do
    Juvet.BotFactory.find_or_create!(name)
  end

  @doc """
  Routes a call to a path through middleware and returns a `RunContext` result

  * `:path` - A `String` that represents a path with the pattern of `controller#action` (e.g. `"users#edit"`)
  * `:context` - A `Map` of values that should be passed to the middleware

  ## Example

  ```
  Juvet.route("home#index", %{team: team, user: user})
  ```
  """
  @spec route(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def route(path, context \\ %{}) do
    Juvet.Runner.route(path, context)
  end

  @doc """
  A shortcut function that creates a bot process (using `create_bot!/1`) and documents (using `connect_bot`)
  that the bot is connected to the specified platform.

  ## Example

  ```
  bot = Juvet.start_bot!("MyBot", :slack, %{token: "MY_TOKEN"})
  ```
  """
  @spec start_bot!(String.t(), atom(), map()) :: pid()
  def start_bot!(name, platform, parameters) do
    bot = __MODULE__.create_bot!(name)
    __MODULE__.connect_bot(bot, platform, parameters)
    bot
  end
end
