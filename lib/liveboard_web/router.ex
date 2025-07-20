defmodule LiveboardWeb.Router do
  use LiveboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveboardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveboardWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/login", AuthController, :login
    post "/login", AuthController, :authenticate
    get "/register", AuthController, :register
    post "/register", AuthController, :create
    post "/logout", AuthController, :logout

    live "/boards", BoardLive.Index, :index
    live "/boards/new", BoardLive.Index, :new
    live "/boards/:slug", BoardLive.Show, :show
  end

  # REMOVED ALL DEV ROUTES AND DASHBOARD IMPORTS
  # NO MORE PHOENIX DEVELOPMENT STUFF
end
