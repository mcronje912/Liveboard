defmodule LiveboardWeb.BoardLive.Index do
  use LiveboardWeb, :live_view
  alias Liveboard.{Accounts, Boards}

  @impl true
  def mount(_params, session, socket) do
    # Get current user from session
    current_user = 
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user!(user_id)
      end

    # Redirect if not authenticated
    if current_user do
      boards = Boards.list_user_boards(current_user.id)
      
      {:ok, assign(socket, current_user: current_user, boards: boards)}
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Boards")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Board")
    |> assign(:board, %Liveboard.Boards.Board{})
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    board = Boards.get_board!(id)
    {:ok, _} = Boards.delete_board(board)

    {:noreply, assign(socket, :boards, Boards.list_user_boards(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_event("create_board", %{"name" => name}, socket) do
    case Boards.create_board(%{
      name: name,
      created_by_id: socket.assigns.current_user.id
    }) do
      {:ok, _board} ->
        boards = Boards.list_user_boards(socket.assigns.current_user.id)
        {:noreply, 
         socket
         |> assign(:boards, boards)
         |> put_flash(:info, "Board created successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create board")}
    end
  end
end
