defmodule EyeSeeYou.Repo do
  use Ecto.Repo,
    otp_app: :eye_see_you,
    adapter: Ecto.Adapters.Postgres
end
