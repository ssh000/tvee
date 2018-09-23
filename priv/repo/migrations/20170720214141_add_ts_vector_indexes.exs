defmodule Tvmaze.Repo.Migrations.AddTsVectorIndexes do
  use Ecto.Migration

  def up do
    execute "CREATE INDEX shows_name_index ON shows USING gin(to_tsvector('english', name));"
  end

  def down do
    execute "DROP INDEX shows_name_index;"
  end
end
