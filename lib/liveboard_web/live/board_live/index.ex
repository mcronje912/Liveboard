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

    if current_user do
      boards = Boards.list_user_boards(current_user.id)

      {:ok, assign(socket,
        current_user: current_user,
        boards: boards,
        page_title: "Your Boards"
      )}
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Your Boards")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Board")
    |> assign(:board, %Boards.Board{color: "#3B82F6"})
    |> assign(:form, to_form(Boards.change_board(%Boards.Board{color: "#3B82F6"})))
  end

  @impl true
  def handle_event("save", %{"board" => board_params}, socket) do
    board_params = Map.put(board_params, "created_by_id", socket.assigns.current_user.id)

    case Boards.create_board(board_params) do
      {:ok, board} ->
        {:noreply,
         socket
         |> put_flash(:info, "Board created successfully!")
         |> push_navigate(to: ~p"/boards/#{board.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate", %{"board" => board_params}, socket) do
    changeset =
      socket.assigns.board
      |> Boards.change_board(board_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("delete_board", %{"board_id" => board_id}, socket) do
    board = Boards.get_board!(board_id)

    case Boards.delete_board(board) do
      {:ok, _board} ->
        boards = Boards.list_user_boards(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:boards, boards)
         |> put_flash(:info, "Board deleted successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete board")}
    end
  end
end
