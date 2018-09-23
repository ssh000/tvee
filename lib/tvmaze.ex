defmodule Tvmaze do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Tvmaze.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: Tvmaze.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
