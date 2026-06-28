class User::MagicLink < ActiveRecord::AssociatedObject
  generates_token expires_in: 15.minutes, embed: -> { _1.sessions.latest_id }
  has_mailer to: :user, subject: "Sign in to gem.coop"
end
