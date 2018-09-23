defmodule Tvmaze.Repo.Migrations.AddAdditionalFieldsToShows do
  use Ecto.Migration

  def change do
    alter table(:shows) do
      add :premiered, :string
      add :official_site, :string
      add :tvmaze_weight, :integer, default: 0
    end
  end
end
