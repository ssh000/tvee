defmodule Bot.Telegram do
  require Logger
  import Ecto.Query
  alias Nadia.Model
  alias Tvmaze.{User, UsersShows, UsersEpisodes, Show, Repo, Episode}

  def new_episode_notification([], _episode), do: nil
  def new_episode_notification(nil, _episode), do: nil
  def new_episode_notification(user, episode) do
    query = from(ep in Episode, where: ep.tvmaze_id == ^episode["id"], preload: [:show])
    case Repo.one(query) do
      nil -> Logger.info("We dont have this episode #{episode["id"]} for show #{episode["show"]["id"]}")
      episode -> send_message(
        user.telegram_id,
        episode_message(episode),
        parse_mode: "HTML",
        reply_markup: %Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [inline_button("Watched", "watch_episode", episode.id)]
          ]
        }
      )
    end
  end

  def handle_updates(%{"message" => %{"from" => user, "text" => text, "message_id" => _message_id}}) do
    text
    |> case do
        "/start" -> sign_up(user)
        "/start start" -> sign_up(user)
        "/help" -> send_help(user["id"])
        "/list" -> user_shows(user["id"])
        "/updates" -> last_updated_shows(user["id"])
        _ -> tvmaze_search(text, user["id"])
    end
  end
  def handle_updates(%{"edited_message" => _}), do: nil
  def handle_updates(%{"message" => %{ "chat" => _ }}), do: nil
  def handle_updates(%{"callback_query" => %{"data" => data, "from" => user, "id" => id, "message" => %{"message_id" => message_id}}}) do
    case Poison.decode(data) do
      {:ok, %{"shows" => show_id}} ->
        case Repo.get(Show, show_id) do
          nil -> nil
          show ->
            Nadia.edit_message_text(
              user["id"],
              message_id,
              nil,
              show_message(show),
              parse_mode: "HTML",
              reply_markup: show_reply_markup(user["id"], show)
            )
        end
      {:ok, %{"watch_episode" => episode_id}} ->
        case UsersEpisodes.create(user["id"], episode_id) do
          {:ok, _assoc} ->
            Nadia.edit_message_reply_markup(user["id"], message_id, nil, reply_markup: %Model.InlineKeyboardMarkup{inline_keyboard: [[inline_button("Unwatched", "unwatch_episode", episode_id)]]})
            Nadia.answer_callback_query(id, show_alert: false, text: "The episode is marked as the watched one!")
          {:error, changeset} -> Logger.error(changeset.errors)
        end
      {:ok, %{"unwatch_episode" => episode_id}} ->
        case UsersEpisodes.delete(user["id"], episode_id) do
          {:ok, _assoc} ->
            Nadia.edit_message_reply_markup(user["id"], message_id, nil, reply_markup: %Model.InlineKeyboardMarkup{inline_keyboard: [[inline_button("Watched", "watch_episode", episode_id)]]})
            Nadia.answer_callback_query(id, show_alert: false, text: "The episode is marked as the unwatched one!")
          {:error, changeset} -> Logger.error(changeset.errors)
        end
      {:ok, %{"follow_show" => show_id}} ->
        case UsersShows.create(user["id"], show_id) do
          {:ok, _assoc} ->
            Nadia.edit_message_reply_markup(user["id"], message_id, nil, reply_markup: %Model.InlineKeyboardMarkup{inline_keyboard: [[inline_button("Unfollow", "unfollow_show", show_id)]]})
            Nadia.answer_callback_query(id, show_alert: false, text: "The TV show is added to your watch list!")
          {:error, changeset} -> Logger.error(changeset.errors)
        end
      {:ok, %{"unfollow_show" => show_id}} ->
        case UsersShows.delete(user["id"], show_id) do
          {:ok, _assoc} ->
            Nadia.edit_message_reply_markup(user["id"], message_id, nil, reply_markup: %Model.InlineKeyboardMarkup{inline_keyboard: [[inline_button("Follow", "follow_show", show_id)]]})
            Nadia.answer_callback_query(id, show_alert: false, text: "The TV show is removed from your watch list!")
          {:error, changeset} -> Logger.error(changeset.errors)
        end
    end
  end

  def handle_updates(%{"inline_query" => %{"id" => id, "offset" => _offset , "query" => query}}) do
    Show.search(query)
    |> Enum.map(&to_telegram_message(&1))
    |> send_message_to(id)
  end

  def send_message(chat_id, text, options \\ []) do
    result = Nadia.send_message(chat_id, text, options)

    case result do
      {:ok, _message} -> User.update(chat_id, active: true)
      {:error, %Nadia.Model.Error{reason: "Forbidden: bot was blocked by the user"}} -> User.update(chat_id, active: false)
      {:error, %Nadia.Model.Error{reason: "Forbidden: user is deactivated"}} -> User.update(chat_id, active: false)
      {:error, reason} -> Logger.error(reason)
      _ -> nil
    end

    result
  end

  defp sign_up(user) do
    data = for {key, val} <- user, into: %{}, do: {String.to_atom(key), val}
    case User.create_or_update(Map.merge(data, %{telegram_id: data.id, active: true})) do
      {:ok, user} ->
        Logger.info("user is added: #{user.telegram_id}")
        send_help(user.telegram_id)
      {:error, changeset} -> Logger.error(changeset.errors)
    end
  end

  defp to_telegram_message(show) do
    %Model.InlineQueryResult.Article{
      title: show.name,
      thumb_url: show.image["medium"],
      description: show.summary,
      id: show.id,
      input_message_content: %Model.InputMessageContent.Text{
        message_text: show_message(show),
        parse_mode: "HTML"
      }
    }
  end

  defp inline_button(text, action, show_id) do
    %Model.InlineKeyboardButton{
      text: text, # user has show - unfollow, has not - follow
      callback_data: Poison.encode!(%{action => show_id}),
      url: "" #https://github.com/zhyu/nadia/issues/44
    }
  end

  defp send_message_to(shows, id) do
    Nadia.answer_inline_query(id, shows)
  end

  defp tvmaze_search(query, user_id) do
    Logger.info("User Query #{user_id}: #{query}")
    case Show.search(query) do
      [] -> send_message(user_id, "Oops, I can't find any TV shows 😔")
      [show] ->
        case Repo.get(Show, show.id) do
          nil -> nil
          show ->
            send_message(
              user_id,
              show_message(show),
              parse_mode: "HTML",
              reply_markup: show_reply_markup(user_id, show)
            )
        end
      shows ->
        send_message(
          user_id,
          "Please choose a TV show:",
          parse_mode: "HTML",
          reply_markup: %Model.InlineKeyboardMarkup{inline_keyboard:
            Enum.map(shows, fn show ->
              [%Model.InlineKeyboardButton{
                text: "#{show.name} (#{show.status})",
                callback_data: Poison.encode!(%{"shows" => show.id}),
                url: "" #https://github.com/zhyu/nadia/issues/44
              }]
            end)}
        )
    end
  end

  # ★★★★☆
  defp show_reply_markup(user_id, show) do
    show
    |> Repo.preload([users: (from user in User, where: user.telegram_id == ^user_id)])
    |> Map.get(:users)
    |> Enum.at(0)
    |> case do
      nil ->
        %Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [inline_button("Follow", "follow_show", show.id)]
          ]
        }
      _record ->
        %Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [inline_button("Unfollow", "unfollow_show", show.id)]
          ]
        }
    end
  end

  defp next_episode(show) do
    case Show.next_episode(show) do
      nil -> nil
      episode ->
        """
        Next Episode: <i>#{episode_signature(episode)} (#{episode.airdate} #{episode.airtime})</i>
        """
    end
  end

  defp show_message(show) do
    """
    <b>#{show.name}</b>

    #{next_episode(show)}
    #{show.summary}
    <a href="#{show.image["medium"]}">&#160;</a>
    """
  end

  defp episode_signature(nil), do: "S01E01"
  defp episode_signature(episode) do
    "S#{format_number(episode.season)}E#{format_number(episode.number)}"
  end

  defp episode_message(episode) do
    """
    ##{parameterize(episode.show.name)}
    <b>#{episode.show.name} 🎉</b>#{episode_signature(episode)}

    #{episode.name}
    #{episode.summary}
    <a href="#{episode.image["medium"]}">&#160;</a>
    """
  end

  defp user_shows(user_id) do
    case Repo.get_by(User, telegram_id: user_id) do
      nil -> nil
      user ->
        case Show.list(user) do
          [] -> "Try to add at least one show! (hint: use /help)"
          shows ->
            send_message(
              user_id,
              "Your shows:",
              parse_mode: "HTML",
              reply_markup: %Model.InlineKeyboardMarkup{inline_keyboard:
                Enum.map(shows, fn show ->
                  [%Model.InlineKeyboardButton{
                    text: "#{show.name} (#{episode_signature(Episode.last_watched(show.id, user))})",
                    callback_data: Poison.encode!(%{"shows" => show.id}),
                    url: "" #https://github.com/zhyu/nadia/issues/44
                  }]
                end)}
            )
        end
    end
  end

  defp last_updated_shows(user_id) do
    case Show.updates do
      [] -> "There is no updates today!"
      shows ->
        send_message(
          user_id,
          "Updates:",
          parse_mode: "HTML",
          reply_markup: %Model.InlineKeyboardMarkup{inline_keyboard:
            Enum.map(shows, fn show ->
              [%Model.InlineKeyboardButton{
                text: "#{show.name} (#{show.status})",
                callback_data: Poison.encode!(%{"shows" => show.id}),
                url: "" #https://github.com/zhyu/nadia/issues/44
              }]
            end)}
        )
    end
  end

  defp send_help(user_id) do
    send_message(
      user_id,
      """
      1. To add a show to the watch list type in the show's title and hit the <i>follow</i> button.

      2. You can share search results in any of your chats typing in @tvee_bot in your chat.

      <b>Hey </b>@tvee_bot<b> needs your help! Please take a few seconds to rate me:</b> <a href="https://telegram.me/storebot?start=tvee_bot">https://telegram.me/storebot?start=tvee_bot</a> 🌟
      """,
      parse_mode: "HTML",
      disable_web_page_preview: true,
      reply_markup: %{hide_keyboard: true}
      # reply_markup: %Model.ReplyKeyboardMarkup{
      #   keyboard: [[%Model.InlineKeyboardButton{text: "/search", url: ""}, %Model.InlineKeyboardButton{text: "/help", url: ""}]]
      # }
    )
  end

  defp parameterize(title) do
    title
    |> String.split
    |> Enum.join
    |> String.replace(~r/\W/, "")
    |> String.downcase
  end

  defp format_number(number) do
    number
    |> Integer.to_string
    |> String.rjust(2, ?0)
  end
end
