defmodule Tvmaze.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Tvmaze.Worker.start_link(arg1, arg2, arg3)
      # worker(Tvmaze.Worker, [arg1, arg2, arg3]),

      # worker(__MODULE__, [], function: :run)
      # worker(Bot.Telegram, [])
      worker(Tvmaze.Scheduler, []),
      worker(Tvmaze.Repo, []),
      worker(Bot.Router, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tvmaze.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # def run do
  #   Tvmaze.Repo.start_link
  #   Bot.Router.start_link
  # end
end
