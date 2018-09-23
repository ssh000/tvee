defmodule Tvmaze.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :telegram_id, :integer
      add :first_name, :string
      add :last_name, :string
      add :language_code, :string
      add :username, :string

      timestamps()
    end
  end
end
