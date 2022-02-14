#!/usr/bin/env bash
# exit on error
set -o errexit

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Compile assets
npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest

# Build the release and overwrite the existing release directory
MIX_ENV=prod mix release --overwrite

# Events upper right button 'Manual deploy'->rebuild the whole thing
echo "migrating"
echo $DATABASE_URL

# rollback
# MIX_ENV=prod mix ecto.rollback --all

# migrate
MIX_ENV=prod mix ecto.migrate

# run seeds
echo "done migrating, run seeds"
mix run priv/repo/seeds.exs --csv=priv/exports/tokens_prod.csv