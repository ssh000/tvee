defmodule Tvmaze.Tasks.DumpShows do
  alias Tvmaze.{Show}
  require Logger

  @timeout 120_000

  def run(page \\ 0) do
    case HTTPoison.get("http://api.tvmaze.com/shows?page=#{page}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, data} ->
            data
            # |> Enum.map(&Show.create_or_update(&1))
            |> Enum.map(&Task.async(fn -> Show.create_or_update(&1) end))
            |> Enum.each(&Task.await(&1, @timeout))
          {:error, error} -> Logger.error(error)
        end
        run(page + 1)
      {:ok, %HTTPoison.Response{status_code: 404}} -> Logger.info("Dump: Ended on page #{page}")
    end
  end
end
