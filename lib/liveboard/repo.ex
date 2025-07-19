defmodule Liveboard.Repo do
  use Ecto.Repo,
    otp_app: :liveboard,
    adapter: Ecto.Adapters.Postgres
end
