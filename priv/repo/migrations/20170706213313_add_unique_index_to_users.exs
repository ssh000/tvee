defmodule Tvmaze.Repo.Migrations.AddUniqueIndexToUsers do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:telegram_id])
  end
end
