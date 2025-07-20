defmodule LiveboardWeb.Presence do
  @moduledoc """
  Provides presence tracking for users on boards.
  """
  use Phoenix.Presence,
    otp_app: :liveboard,
    pubsub_server: Liveboard.PubSub

  alias Liveboard.Accounts.User

  def track_user(board_id, user_id, user_data \\ %{}) do
    track(self(), "board:#{board_id}", user_id, user_data)
  end

  def list_board_users(board_id) do
    list("board:#{board_id}")
  end

  def update_user(board_id, user_id, user_data) do
    update(self(), "board:#{board_id}", user_id, user_data)
  end

  def get_user_count(board_id) do
    board_id
    |> list_board_users()
    |> map_size()
  end

  def format_users(presences) do
    for {_user_id, %{metas: [meta | _]}} <- presences do
      meta
    end
  end
end
