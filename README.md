![juvet logo](https://github.com/juvet/juvet/blob/master/logo.svg)

> The MVC framework for chat apps built on a platform designed for communication systems.

[![CircleCI](https://circleci.com/gh/juvet/juvet.svg?style=svg)](https://circleci.com/gh/juvet/juvet)

**THIS IS A WORK IN PROGRESS AND NOT READY FOR ANYTHING REAL YET**

## DESCRIPTION

Build chat bot applications for the major chat bot application platforms using familiar model-view-controller architecture patterns that developers have been using for decades.

Juvet is an application framework that includes everything you need to build a chat application for all the major messaging platforms including:

* [Slack RTM](https://api.slack.com/rtm) (currently implemented)
* [Slack Events API](https://api.slack.com/events-api) (coming soon)
* [Slack Incoming Webhook](https://api.slack.com/incoming-webhooks) (coming soon)
* [Amazon Alexa](https://developer.amazon.com/)
* [Facebook Messenger](https://developers.facebook.com/docs/messenger-platform/)
* [Twillio SMS](https://www.twilio.com/docs/sms)
* Custom...

Juvet offers all the features you need to build a scalable and maintainable chat application, including

* API Wrappers
* Message Queuing
* Middleware and Plugins
* Conversation Support
* NLP Support
* more to come...

The [ROADMAP](./ROADMAP.md) describes major upcoming features within each release.

## THIS FRAMEWORK IS SPONSORWARE :open_hands:

This repository supports sustainable open source work via [Sponsorware](https://github.com/sponsorware/docs).

It will be fully open sourced but it is currently only available to people who [sponsor me on GitHub](https://github.com/sponsors/jwright).

I want this framework to be supported for the community with a high-degree of quality for a long time and in order to make that happen at a sustainable pace, I need to have the time and availability to support it appropriately. Sponsorware helps achieve that mission.

Thank you for the support! :heartbeat:

## INSTALLATION

* Add the Juvet dependencies to your `mix.exs` file

```
# mix.exs

def deps do
  [{:juvet, "~> 0.0.1"}]
end
```

* Install the depedencies

```
mix deps.get
```

* Ensure Juvet is started before your application

```
# mix.exs

def application do
  [application: [:juvet]]
end
```

## USAGE

### Configuration

You need to tell Juvet what bot module should be created when a new connection is made. You can do that with the following configuration.

```
# config/config.exs

config :juvet, bot: MyBot
```

### Slack

#### Authorizing with your Slack app

Currently Juvet does not perform any oauth functionality. That will be coming soon so it is up to your application to connect your app to Slack via OAuth. If you are using [ueberauth](https://github.com/ueberauth/ueberauth), then [ueberauth_slack](https://github.com/ueberauth/ueberauth_slack) is a good choice to get your users authorized with Slack.

Once your get the bot access token for your team, you are ready to go.

#### Connecting to your Slack app

Once you have a bot access token for your team, you can connect to Slack via:

```
{:ok, pid} = Juvet.ConnectionFactory.connect(:slack, %{token: "YOUR BOT ACCESS TOKEN"})
```

The above will create two processes for your connected bot. One process (`Juvet.Connection.SlackRTM`) is created to listen to and send messages via the [Slack RTM](https://api.slack.com/rtm) api.

The second process (`Juvet.BotServer`) is created to receive incoming messages from the Slack RTM process and pass them along to your bot.

If you want to perform any custom logic when your bot is connected, you can override the `handle_connect/2` function on your bot.

```
defmodule MyBot do
  use Juvet.Bot

  def handle_connect(platform, state) do
    # Add your custom logic here

    {:ok, state}
  end
end
```

#### Handling events from Slack

You can handle messages from Slack by overriding the `handle_event/3` function on your bot. This function can use pattern matching in order to handle various events from Slack.

```
defmodule MyBot do
  use Juvet.Bot

  def handle_event(platform, %{type: "message"} = message, state) do
    # Add your logic here on how to handle a message event

    {:ok, state}
  end

  def handle_event(platform, %{type: "file_created"} = message, state) do
    # Add your logic here on how to handle a file_created event

    {:ok, state}
  end
end
```

#### Sending messages to Slack

You can send messages back to Slack from your bot by overridding the `send_message/3` function on your bot. The second argument (`state`) should contain an (`id`) key which will be used to send the message to the correct team.

```
defmodule MyBot do
  use Juvet.Bot

  def handle_event(platform, %{type: "message", text: "Hello"} = message, %{id: id, channel: channel} = state) do
    send_message(platform, state, %{type: "message", channel: channel, message: "Right back at cha!"})

    {:ok, state}
  end
end
```

## DOCUMENTATION

### Connecting to a platform

### Receiving messages

### Responding to messages

## TESTING

You can run the tasks with the standard mix command:

```
mix test
```

### Re-recording responses

You can re-record the responses from Slack with the following mix command:

```
mix record token: <slack token here> user: <slack user id here>
```

You can create a Slack token for any of your teams [here](https://api.slack.com/custom-integrations/legacy-tokens)/.

## COMMUNITY

### Contributing

1. Clone the repository `git clone https://github.com/juvet/juvet`
1. Create a feature branch `git checkout -b my-awesome-feature`
1. Codez!
1. Commit your changes (small commits please)
1. Push your new branch `git push origin my-awesome-feature`
1. Create a pull request `hub pull-request -b juvet:master -h juvet:my-awesome-feature`

## Copyright and License

Copyright (c) 2018, Jamie Wright.

Juvet source code is licensed under the [MIT License](LICENSE.md).
