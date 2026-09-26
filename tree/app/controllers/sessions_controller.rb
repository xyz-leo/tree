class SessionsController < ApplicationController
  layout "admin"
  allow_unauthenticated_access only: %i[ new create ]

  # Throttle login attempts. This needs its own store: the app's default cache
  # is null in test and unreliable for counting in production, which silently
  # disables the limit. A dedicated in-process MemoryStore always counts, and
  # the app runs as a single Puma process, so one store covers every request.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  rate_limit to: 10, within: 3.minutes, store: RATE_LIMIT_STORE, only: :create,
    with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
