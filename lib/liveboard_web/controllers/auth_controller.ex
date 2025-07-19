defmodule LiveboardWeb.AuthController do
  use LiveboardWeb, :controller
  alias Liveboard.Accounts

  def login(conn, _params) do
    render(conn, :login)
  end

  def register(conn, _params) do
    changeset = Accounts.change_user(%Liveboard.Accounts.User{})
    render(conn, :register, changeset: changeset)
  end

  def create_user(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome to LiveBoard!")
        |> redirect(to: ~p"/boards")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :register, changeset: changeset)
    end
  end

  def authenticate(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/boards")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/")
  end
end
