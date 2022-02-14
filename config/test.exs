use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :nidm, Nidm.Repo,
  username: "casperkaandorp",
  password: "",
  database: "nidm_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10 # SET THIS! I think you get too view workers

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :nidm, NidmWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# This is for testing purposes (DatabaseQueue has some code
# which doesn't work in tests)
config :nidm,  
  test: true

