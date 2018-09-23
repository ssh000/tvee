defmodule Tvmaze.Tasks.FetchSchedule do
  require Logger
  alias Tvmaze.{Show, Repo}
  import Ecto.Query

  defp maybe_send_notification(episode) do
    query = from(s in Show, where: s.tvmaze_id == ^episode["show"]["id"], preload: [:users])
    case Repo.one(query) do
      %Tvmaze.Show{users: users} ->
        users
        |> Enum.map(&(Bot.Telegram.new_episode_notification(&1, episode)))
      nil -> nil
    end
  end

  def run do
    case HTTPoison.get("http://api.tvmaze.com/schedule?embed=show") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, data} ->
            data
            |> Enum.map(&spawn(fn ->
              maybe_send_notification(&1)
            end))
          {:error, error} -> Logger.error(error)
        end
      {:ok, %HTTPoison.Response{status_code: 404}} -> Logger.error("TVmaze schedule not found")
      {:error, %HTTPoison.Error{reason: reason}} -> Logger.error(reason)
    end
  end
end
