defmodule LiveboardWeb.PageController do
  use LiveboardWeb, :controller

  def home(conn, _params) do
    # If user is logged in, redirect to boards
    if conn.assigns.current_user do
      redirect(conn, to: ~p"/boards")
    else
      # Show landing page
      render(conn, :home, layout: false)
    end
  end
end
