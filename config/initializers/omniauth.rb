require 'omniauth/strategies/central_auth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :central_auth, ENV["CENTRAL_AUTH_CLIENT_ID"], ENV["CENTRAL_AUTH_SECRET"]
end
