Juvet
=====

The message platform for chat apps built on a platform designed for communication systems.

**THIS IS A WORK IN PROGRESS AND NOT READY FOR ANYTHING REAL YET**

## DESCRIPTION

Juvet is an application framework that includes everything you need to build a chat application for all the major messaging platforms including

* Slack
* Amazon Alexa
* Facebook Messenger
* Twillio
* more to come...

Juvet offers all the features you need to build a scalable and maintainable chat application, including

* API Wrappers
* Message Queuing
* Middleware and Plugins
* Conversation Support
* NLP Support
* more to come...

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

* Start the server

```
mix Juvet.Server.start_link
```

## USAGE

### Slack

#### Connecting to your Slack app

#### Authorizing with your Slack app

#### Receiving messages from Slack

#### Sending messages to Slack

## DOCUMENTATION

### Connecting to a platform

### Receiving messages

### Responding to messages

## COMMUNITY

### Contributing

1. Clone the repository `git clone https://github.com/juvet/juvet`
1. Create a feature branch `git checkout -b my-awesome-feature`
1. Codez!
1. Commit your changes (small commits please)
1. Push your new branch `git push origin my-awesome-feature`
1. Create a pull request `hub pull-request -b juvet:master -h juvet:my-awesome-feature`
