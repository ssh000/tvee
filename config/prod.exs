use Mix.Config

config :tvmaze, Tvmaze.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "tvmaze",
  password: "",
  hostname: "localhost",
  pool_size: 32,
  timeout: :infinity,
  ownership_timeout: 120_000,
  pool_timeout: 120_000

config :tvmaze, ecto_repos: [Tvmaze.Repo]
config :nadia, token: ""

config :logger,
  backends: [{LoggerFileBackend, :info_log},
             {LoggerFileBackend, :error_log}]

config :logger, :info_log,
  path: "logs/info.log",
  level: :info

config :logger, :error_log,
  path: "logs/error.log",
  level: :error

config :tvmaze, Tvmaze.Scheduler,
  jobs: [
    # {"0 18 * * *", {Tvmaze.Tasks.DumpEpisodesFuture, :run, []}},
    {"0 19 * * *", {Tvmaze.Tasks.FetchSchedule, :run, []}},
    {"0 22 * * *", {Tvmaze.Tasks.DumpShows, :run, []}},
    {"0 3 * * *", {Tvmaze.Tasks.DumpEpisodes, :run, []}},
  ]
