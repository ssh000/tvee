defmodule Tvmaze.Repo.Migrations.CreateUsersShows do
  use Ecto.Migration

  def change do
    create table(:users_shows) do
      add :user_id, references(:users, type: :uuid), primary_key: true
      add :show_id, references(:shows, type: :uuid), primary_key: true

      timestamps()
    end

    create index(:users_shows, [:user_id, :show_id], unique: true)
  end
end
