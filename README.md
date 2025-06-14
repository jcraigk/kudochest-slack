![KudoChest Logo](https://github.com/jcraigk/kudochest/blob/main/app/webpacker/images/logos/app-144.png)

**KudoChest** is a team engagement tool for **Slack**. It allows users within a workspace to give each other points that accrue over time. A point represents a token of appreciation or recognition for a job well done. Users can view their profile, browse history, and access leaderboards on the web or within the chat client. App settings and moderation tools are provided via web UI.

This is a **Ruby on Rails** application backed by **Postgres** and **Redis**. It integrates tightly with Slack, keeping teams and users synced server-side. This enables web-based user profiles and other UX enhancements not possible in standard bots.

This is a continuation of [KudoChest for Slack and Discord](https://github.com/jcraigk/kudochest), which is deprecated.

See the **[Wiki](https://github.com/jcraigk/kudochest-slack/wiki)** for more information.


# Intro Video

Watch the video below to get a feel for the basic features of the app.

[![Intro to KudoChest Video](https://img.youtube.com/vi/JHcYOSONdRg/0.jpg)](https://www.youtube.com/watch?v=JHcYOSONdRg)


# Installation

To install KudoChest into your organization's Slack workspace, you must host the Rails components on a web server you control and configure the Slack App via the [Slack API website](https://api.slack.com/).

See the [Installation Instructions](https://github.com/jcraigk/kudochest-slack/wiki/Installation) for more detail.


# Development

For local development, start by reading the [Installation Instructions](https://github.com/jcraigk/kudochest-slack/wiki/Installation), paying special attention to the [Environment Variables](https://github.com/jcraigk/kudochest-slack/wiki/Installation#environment-variables) section. Note that you will only need certain portions of what is described there, depending on your specific area of development.

## Setup

For Slack and OAuth callbacks, a tunneling service such as [ngrok](https://ngrok.com/) is recommended to expose your local server publicly.

You'll want to setup a dedicated workspace and App in Slack specifically for KudoChest development. Do not use your organization's production workspace or App to develop against.

If you're working on response images and running Sidekiq in Docker, you'll need to configure a local storage location in `docker-compose.yml` to map to `/storage` in the `sidekiq` container.


## Run the App Components

You may run all components in Docker with logging exposed using the command `make up` and then connect to the app container and create the database.

Alternatively you can run services (PostgreSQL and Redis) in Docker while running the Rails processes natively. This often eases debugging and development.

For running the Rails stack you'll need the following:
* [Ruby](https://www.ruby-lang.org/en/)
* [NodeJS](https://nodejs.org/en/)
* [Yarn](https://www.npmjs.com/package/yarn)

I recommend [mise](https://mise.jdx.dev/) for language version management.

Install dependencies:

```bash
# Install Ruby dependencies
bundle install

# Initialize database
make services
bundle exec rails db:create
bundle exec rails db:reset

# Install javascript dependencies
yarn install
```

Start the server and worker:

```
# Start web server (terminal 1)
bundle exec rails s

# Start Sidekiq (terminal 2)
bundle exec sidekiq
```

Alternatively, you can use `make dev` to run both processes in the same terminal.


## Testing

To run specs in Docker:

```
make spec
```

To run specs natively:

```
make services
bundle exec rspec
```

To generate seed data for manual testing, first install your local instance of KudoChest into a development workspace and then run

```
bundle exec rails seeds:all
```


# Contributors

All contributions are welcome via Issues and Pull Requests. If you notice something wrong in the Wiki, please feel free to fix it!

* Code by [Justin Craig-Kuhn](https://github.com/jcraigk/)
* Logo and background mural by Evan Mahnke (Discord `8-bit adventurer#3751` / `gallanthomeslice at yahoo`)
* Animated GIFs and icons by Milton Monroe (Discord `carmelcamel#5829` / `milton dot p dot monroe at gmail`)


# Copyright

This software is released under an [MIT-LICENSE](https://github.com/jcraigk/kudochest/blob/main/MIT-LICENSE).

