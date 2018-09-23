defmodule Tvee.Stats do
  alias Tvmaze.{Repo, User}
  import Ecto.Query

  def users_count do
    from(u in User, select: count(u.id))
    |> Repo.one
  end

  def users_count(active) do
    from(u in User, where: u.active == ^active, select: count(u.id))
    |> Repo.one
  end
end
