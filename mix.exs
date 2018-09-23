defmodule Tvmaze.Mixfile do
  use Mix.Project

  def project do
    [app: :tvmaze,
     version: "0.0.2",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:quantum, :timex, :logger, :ecto, :postgrex, :httpoison, :nadia, :cowboy, :plug, :edeliver],
     mod: {Tvmaze.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:postgrex, "~> 0.13.3"},
      {:ecto, "~> 2.1.4"},
      {:poison, "~> 3.1.0"},
      {:httpoison, "~> 0.11.2"},
      {:nadia, "~> 0.4.2"},
      {:cowboy, "~> 1.1.2"},
      {:plug, "~> 1.0.6"},
      {:html_sanitize_ex, "~> 1.3.0"},
      {:logger_file_backend, "~> 0.0.10"},
      {:quantum, "~> 2.1.0"},
      {:edeliver, "~> 1.4.2"},
      {:distillery, "~> 1.4.0"},
      {:timex, "~> 3.1.17"},
      {:poolboy, "~> 1.5.1"}
    ]
  end
end
