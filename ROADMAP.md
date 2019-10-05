Juvet Roadmap
=============

This documents outlines the current plan for the implementation of larger features within the [Juvet](juvet/juvet) project.

These are planned features that will get Juvet to a place where the library is useful for building production chatbots.

## 0.0.1

The goal of this release is to allow developers to get up and running easily with bot development in Elixir. This will allow them to handle requests and respond to those requests by defining handlers.

* **Finish Slack API Wrapper** - Obviously Juvet needs to talk to the Slack API and an Elixir wrapper is needed so all the ceremony is taken care of. Some of the API is already wrapped and so this just continues the work.
    * _TODO:_ Need to figure out if this will be a seperate repo. I like the idea of a seperate repo so that changes in the API will not require changes in the full Juvet repo. I also like the idea of making our API wrapper the default but perhaps a user may want to use a different Slack API wrapper.
* **Adjust the bot processes** - The first pass at the OTP architecture is flawed. We have two supoervisors, one for the connection to Slack and one that represents the bot, which could have multiple connections. These are both on their own nodes. It would be better to just have one Supervisor for the bots with various nodes connected for each type of connection, with a supervisor for the connections.
    * [This issue](https://github.com/juvet/juvet/issues/22) will track this feature.
* **Slack State** - Each bot will have it's own state that contains the conversation history, the current team, user, etc. This state probably needs to be smarter than a Map as, based on it's connection(s), will need to retrieve the information based on the platform.
    * [This issue](https://github.com/juvet/juvet/issues/21) will track this feature.
* **Handle Slack Events** - We need a basic web server to consume event payloads from the [Slack Events API](https://api.slack.com/events-api) so the users can just mount this in their existing applications.
* **Handle Slack Commands** - Like Slack Events, we need a basic web server to consume command payloads from the [Slack Slash Commands API](https://api.slack.com/slash-commands) so the users can just mount this in their existing applications.
* **Handle Slack Interactivity** - Like Slack Events, we need a basic web server to consume interactivity payloads from the [Slack Dialog API](https://api.slack.com/dialogs) and the [Slack Actions API](https://api.slack.com/actions) so the users can just mount this in their existing applications.

## 0.0.2

The goal of this release is to flush out an initial MVC architecture so that responding to bot events can be as easy as respond to web requests.

* **Model-View-Controller architecture** - Developing for bots should be just as easy as handling requests from the web. This has not been done with any bot framework that I know about. This will allow developers to specify routes which will run through a configurable middleware chain and eventually create a controller and action that the developer can then use to handle the bot request and respond with a view.

## 0.0.3

* **Intent processing** - Develop a plugable intent processor (wit.ai, etc) so that developers can respond to intents rather than pattern match on message patterns.

## 0.0.4

* **Integrate Slack OAuth** - Instead of requiring developers to implement another method of retriving oauth credentials from Slack, integrate with [ueberauth](https://github.com/ueberauth/ueberauth).

## 0.0.5

* **Conversational design** - Architect an easy way for developers to integrate conversational mapsso developers can handle conversational flows easily.

## 0.0.6

* **Facebook Messenger integration** - Add the second chatbot platform integration, which will be for Facebook Messenger.

## 1.x.x

* **Juvet Bridge** - Architect a way for a hosted version of Juvet to send events to another application so anyone can write the business logic for a bot in their own programming language. Juvet will send events over a bridge that another application can subscribe to.
