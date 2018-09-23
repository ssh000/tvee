defmodule Tvmaze.Tasks.DumpEpisodesToday do
  alias Tvmaze.{Episode}
  require Logger

  @timeout 120_000

  def run do
    case HTTPoison.get("http://api.tvmaze.com/schedule?embed=show") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, data} ->
            data
            |> Enum.map(&Task.async(fn -> Episode.create_or_update(Map.put(&1, "show_id", &1["show"]["id"])) end))
            |> Enum.each(&Task.await(&1, @timeout))
          {:error, error} -> Logger.error(error)
        end
      {:ok, %HTTPoison.Response{status_code: 404}} -> Logger.error("TVmaze schedule not found")
      {:error, %HTTPoison.Error{reason: reason}} -> Logger.error(reason)
    end
  end
end
