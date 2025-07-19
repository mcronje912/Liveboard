defmodule LiveboardWeb.Router do
  use LiveboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveboardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LiveboardWeb.Plugs.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", LiveboardWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/login", AuthController, :login
    get "/register", AuthController, :register
    post "/auth/login", AuthController, :authenticate
    post "/auth/register", AuthController, :create_user
    get "/logout", AuthController, :logout
  end

  # LiveView routes (authentication handled in LiveView mount)
  scope "/", LiveboardWeb do
    pipe_through :browser

    live "/boards", BoardLive.Index, :index
    live "/boards/new", BoardLive.Index, :new
    live "/boards/:slug", BoardLive.Show, :show
  end

  if Application.compile_env(:liveboard, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LiveboardWeb.Telemetry
    end
  end
end
