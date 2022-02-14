# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :nidm,
  ecto_repos: [Nidm.Repo],
  export_path: "priv/exports",
  queues: 1, # :single gate will gather people in a single queue
  recovery_period: 4,
  pause_duration: 5_000 # duration of pauses in ms

# configure uuid's / UUID's
# I am pretty sure the name: and column: arguments
# aren't necessary
config :nidm, Nidm.Repo,
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id]

# Configures the endpoint
config :nidm, NidmWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vl81S2OFh3vTRR9k/Ag/d+FvRMGUYpKgamg62ZqHiWBBeob8CXnERxpMcwPowV9U",
  render_errors: [view: NidmWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Nidm.PubSub,
  live_view: [signing_salt: "FpiJ9ocr"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
