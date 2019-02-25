
module OmniAuth
  module Strategies

    class CentralAuth < OmniAuth::Strategies::OAuth2

      option :name, :central_auth

      option :client_options, {
        :site => ENV['CENTRAL_AUTH_URL'],
        :authorize_path => "/oauth/authorize"
      }

      uid { raw_info["id"] }

      info do
        {
          :email => raw_info["email"],
          :name => raw_info["name"]
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v1/me').parsed
      end

    end
  end
end
