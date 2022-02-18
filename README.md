# NIDM

A Elixir/Phoenix web application to investigate the social networking behavior of people during times of an epidemic. The application handles multiple networks concurrently.

## Table of Contents
* [General info](#general-info)
* [Technologies](#technologies)
* [Setup](#setup)
    * [Local Deployment](#local-deployment)
    * [Deployment on Render](#deployment-on-render)
* [Application Description](#application-description)

## General Info

The NIDM (Networking during Infectious Diseases Model) experiment is designed as a round-based interactive game to investigate the social networking behavior of people during times of an epidemic. The researcher hypothesized that the urge to avoid an infection depends on someone’s subjective tradeoff between the value of that someone’s social relations and the severity of a potential infection. To test this, we assign each of 60 human subjects per experimental session to a node in a clustered or a random network. In the clustered network, node assignment is based on the participant's risk profile which is assessed before the game starts.

The task of the human subjects is to maximize personal monetary reward, which depends on: the number of relations a node has (100 points for 6 relations and fewer points for fewer or more relations), how many of these relations share a relation among each other ("my friends being friends with each other" – 20 points for either 0 in the "low clustering" condition or 5 in the "high clustering" condition), and whether the subject’s node is infected (-14 points). The available actions are: nominating another node to create a new relation, accepting the nomination of another node to create a new relation, and breaking an existing relation to another node. In the first round of the game, a single node is infected with an infectious disease, while all other 59 nodes are susceptible to the disease. An infected node is infectious for 4 rounds, and may spread the disease with a 15% probability to each of its related susceptible nodes during each of the 4 rounds. After being infected for 4 rounds, a node recovers and cannot get infected again.

The subjects were recruited on the [Prolific](https://www.prolific.co/) platform.

## Technologies

* Phoenix Framework version: >= 1.5.7
* Elixir version: >= 1.11.3
* PostgreSQL version: >= 13
* Node version: 14.17.6

## Setup

The application was installed on [Render.com](https://render.com/), but can be executed on your local computer as well. Make sure your deployment machine has been equipped with the required software. It depends on your deployment environment how to start the application. *Please read the local deployment description to learn how to set up the application for receiving real participants*.

### Local Deployment

Change the working directory to the root directory of the application. In this repository, the database has been setup with a user 'casperkaandorp' (no password), and a database 'nidm' (see `/config/dev.exs`). Run `mix ecto.create` to create the database if necessary and run `mix ecto.migrate` to create all tables. You can start the server in interactive mode with `iex -S mix phx.server`.

All participants need a user account. That account will be created if participants approach the application with a valid user token. These tokens can be created if the server has been started in interactive mode by calling the following function:
```
> Nidm.Tools.export_user_accounts(<N particpants>, "<url>", "<token-filename>.csv")
```
With `<N particpants>` the wanted number of user accounts, `<url>` the url of the landing page of the application (`http://localhost:4000/welcome`), and `<token-filename>.csv` the name of the csv export file where all tokens are collected. The exported file can be found in the `/priv/exports/` folder.

If necessary, one can reset the server with the generated user accounts as follows:
* stop the server if it's running
* run `mix run priv/repo/seeds.exs --csv=priv/exports/<token-filename>.csv` to import all tokens
* run `iex -S mix phx.server` to restart the server

Running the `seeds.exs` will also create a pre-specified number of networks. The specification is added within that file.

People without a correct token, or not  could not enter the application. That entails having the tokens imported into the database before a trial. Creating the tokens on a local computer, assigning them to subjects and importing them in the production environment is easier than handling the tokens on the production server.

### Deployment on Render

[Render.com](https://render.com/) allows quick deployment of Phoenix applications. Make sure that Render has permission to search in your GitHub account. On Render's dashboard create a new web service. Select the GitHub repository for the NIDM application. Every time you push local commits to GitHub, Render will (re)deploy the new version of the application on its server.

On Render also create a new Database. After creation copy its internal Connection String (ICS). Click back to the web service, and add under the 'Environment' tab an environment variable `DATABASE_URL` and assign it the copied (ICS). Also add a `POOL_SIZE` variable for the database (we have set it to 25) and add the variable `SECRET_KEY_BASE` and assign it to the output of `mix phx.gen.secret` (executed in the working directory of any Phoenix app).

Next, add a shell script `build.sh` in the root directory of the application (see `./build.sh`) and add the necessary compile and migration commands. On Render go to the 'Setting' tab fill out `./build.sh` in the Build Command field.

After these steps, as written before, after pushing your local commits to GitHub, Render picks up the changes and redeploys the code to its server automatically.

To setup the app for a trial, you can generate a token csv file (see previous section), go to the `Shell` tab and run:
```
$ mix run priv/repo/seeds.exs --csv=priv/exports/<token-filename>.csv
```
After this step, the app will harbour a pre-defined number of networks (hard-coded in the `seeds.exs` file) and is ready to welcome people with a valid token.

## Application Description

A big difference in comparison with a normal Phoenix application is the role of the database. The database plays a redundancy role: it is obviously used for permanent storage. But the data-flow in the game is primarily handled in ets tables. Every data event is stored first in the ets tables, and a copy of the data mutation (creation/change) is put into a queue which is periodically and asynchronously  dumped into the PostgreSQL database: permanent storage is _not_ blocking any operation. The API for the ets tables can be found in `lib/nidm/gen_servers/cache.ex` and the queue towards the PostgreSQL database is handled in `lib/nidm/gen_servers/database_queue.ex`. Although it might seem unnecessary, this mechanism has been added because of the high volume of data that is generated in the app. Subjects generate a lot of data in play and it is important that the sequence is maintained. In other apps we have seen problems with this. Trying a PostgreSQL-only version might back-fire and that would have had financial consequences. In other words: better safe than sorry.

A quick note on this seemingly cumbersome procedure with the access tokens: since the application was open for the public we wanted the app to be only available for invited guests. With predefining tokens we could have solved this problem. But we ran into trouble on Prolific: it was not possible to distribute the tokens to the registered participants. Therefor we have substituted the access token with a Prolific identifier (prolific_pid). The application in this repo can do both: it accepts urls with self-generated tokens and/or pre-registered prolific ids. 

For the trials we have used the prolific ids. People had to register at Prolific to participate. After registration we added their prolific ids to the generated token file and imported that file before a trial on the production server. A valid url looks like this:
```
http://https://nidm.onrender.com/welcome?prolific_pid=542bdb6dfdf99b324ea37c3a
```
Valid urls trigger the session controller which, after verification subjects were led to the risk assessment controller in which they are presented a small number of questions that will calculate a personal risk profile, denoted by an simple numerical score. After the assessment people are added to a waiting queue (`lib/nidm/gen_servers/gate.ex`) and redirected to the wait-live-controller. On the wait page they can see how many people have entered the system. When there are enough subjects to occupy a network (60 in total), the group gets positions in a network, a network monitor is started (`lib/nidm/gen_servers/network_monitor.ex`) to supervise the game and one node gets infected. From then on, subjects will play the game in the game-live-controller. After the game has reached its end state, people are redirected to the exit controller in which they receive their completion code that enabled them to get paid on Prolific. 


