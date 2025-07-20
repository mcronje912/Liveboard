defmodule Liveboard.Broadcasting do
  @moduledoc """
  Handles real-time broadcasting for LiveBoard collaboration features.
  """

  alias Phoenix.PubSub

  @pubsub Liveboard.PubSub

  # Board-level broadcasts
  def broadcast_board_update(board_id, event, payload) do
    PubSub.broadcast(@pubsub, board_topic(board_id), {event, payload})
  end

  # Task-specific broadcasts
  def broadcast_task_created(board_id, task) do
    broadcast_board_update(board_id, :task_created, %{task: task})
  end

  def broadcast_task_updated(board_id, task) do
    broadcast_board_update(board_id, :task_updated, %{task: task})
  end

  def broadcast_task_moved(board_id, task, old_column_id, new_column_id) do
    broadcast_board_update(board_id, :task_moved, %{
      task: task,
      old_column_id: old_column_id,
      new_column_id: new_column_id
    })
  end

  def broadcast_task_deleted(board_id, task_id) do
    broadcast_board_update(board_id, :task_deleted, %{task_id: task_id})
  end

  # Activity broadcasts
  def broadcast_activity(board_id, activity) do
    broadcast_board_update(board_id, :new_activity, %{activity: activity})
  end

  # User presence broadcasts
  def broadcast_user_joined(board_id, user) do
    broadcast_board_update(board_id, :user_joined, %{user: user})
  end

  def broadcast_user_left(board_id, user) do
    broadcast_board_update(board_id, :user_left, %{user: user})
  end

  # Topic helpers
  def board_topic(board_id), do: "board:#{board_id}"
  def user_topic(user_id), do: "user:#{user_id}"

  # Subscribe to board updates
  def subscribe_to_board(board_id) do
    PubSub.subscribe(@pubsub, board_topic(board_id))
  end

  def unsubscribe_from_board(board_id) do
    PubSub.unsubscribe(@pubsub, board_topic(board_id))
  end
end
