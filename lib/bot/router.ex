defmodule Bot.Router do
  use Plug.Router
  require Logger

  plug :match
  plug :dispatch

  post "/bot/telegram" do
    {:ok, data, _conn} = read_body(conn)

    case Poison.decode(data) do
      {:ok, result} -> Bot.Telegram.handle_updates(result)
      {:error, error} -> Logger.error(error)
    end

    conn
    |> send_resp(:ok, "")
  end

  def start_link do
    { :ok, _ } = Plug.Adapters.Cowboy.http(Bot.Router, [])
  end
end
