# lita-heroku

TODO: Add a description of the plugin.

## Installation

Add lita-heroku to your Lita instance's Gemfile:

``` ruby
gem "lita-heroku"
```

Create an oauth token and set it in config:

``` bash
heroku plugins:install https://github.com/heroku/heroku-oauth
heroku authorizations:create -d "Lita Bot"
echo "HEROKU_OAUTH_TOKEN=YOUR_TOKEN" >> .env
```

In your lita config:

``` ruby
config.handlers.heroku.oauth_token = ENV.fetch("HEROKU_OAUTH_TOKEN")
```

## Configuration

TODO: Describe any configuration attributes the plugin exposes.

## Usage

TODO: Describe the plugin's features and how to use them.
