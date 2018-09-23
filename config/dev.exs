use Mix.Config

config :tvmaze, Tvmaze.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "tvmaze",
  password: "",
  hostname: "localhost"

config :tvmaze, ecto_repos: [Tvmaze.Repo]
# @tvee_dev_bot
config :nadia, token: ""
