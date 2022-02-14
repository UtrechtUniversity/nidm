defmodule NidmWeb.Router do
  use NidmWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, { NidmWeb.LayoutView, :root }
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Nidm.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NidmWeb do
    pipe_through :browser

    get "/welcome", SessionController, :new
    get "/unknown_user", ExitController, :unknown_user, as: :unknown
    #get "/exit", ExitController, :index

    resources "/session", SessionController, only: [:new, :create, :delete], singleton: true
    resources "/task1", RiskController
    resources "/exit", ExitController do
        get "/prolific", ExitController, :prolific, as: :prolific
    end

    get "/final_instructions", RiskController, :final_instructions

    live "/wait", WaitLive, layout: { NidmWeb.LayoutView, "root_no_header.html" }
    live "/pause", PauseLive, layout: { NidmWeb.LayoutView, "root_no_header.html" }
    live "/task2", GameLive, layout: { NidmWeb.LayoutView, "root_no_header.html" }
  end

  scope "/admin", NidmWeb do
    pipe_through :browser

    get "/export", DownloadController, :export
    get "/", AdminController, :index
    get "/bootstrap_test", AdminController, :bootstrap_test
    live "/dashboard", AdminLive, layout: { NidmWeb.LayoutView, "root_no_header.html" }
  end

  # Other scopes may use custom stacks.
  # scope "/api", NidmWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: NidmWeb.Telemetry
    end
  end
end
