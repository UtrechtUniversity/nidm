# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Nidm.Repo.insert!(%Nidm.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{ parsed, _args, _invalid } = OptionParser.parse(
    System.argv,
    strict: [csv: :string, ]
)
parsed = Enum.into(parsed, %{})

# # # export a bunch of user accounts
# # url = "https://nidm.onrender.com/welcome"
# url = "http://localhost:4000/welcome"
# Nidm.Tools.export_user_accounts(200, url)

# reset the database
Nidm.Tools.reset_db

# # create networks
# Nidm.Tools.generate_network("network_1", :clustered, :random, 0.15, :db)
# Nidm.Tools.generate_network("network_2", :unclustered, :assortative, 0.15, :db)

Nidm.Tools.generate_network("network_1", :clustered,   :random,          0.15, :db)
Nidm.Tools.generate_network("network_2", :unclustered, :assortative,     0.15, :db)
Nidm.Tools.generate_network("network_3", :clustered,   :assortative,     0.15, :db)


# Nidm.Tools.generate_network("network_1", :test, :random, 0.15, :db)
# Nidm.Tools.generate_network("network_2", :test, :assortative, 0.15, :db)

# create admin
Nidm.Tools.generate_admin_account

# import the users into the database
filename = Map.get(parsed, :csv, "tokens.csv")
# path = "#{Application.get_env(:nidm, :export_path)}/#{filename}"
Nidm.Tools.import_user_tokens(filename, :db)

# generate risk questions
Nidm.Tools.generate_risk_questions(:db)

#
# mix run priv/repo/seeds.exs --csv=priv/exports/tokens_prod.csv
# _build/prod/rel/nidm/bin/nidm stop
# _build/prod/rel/nidm/bin/nidm start

# _build/prod/rel/recruiter/bin/recruiter remote
