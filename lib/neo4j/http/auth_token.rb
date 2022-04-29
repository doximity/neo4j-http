# frozen_string_literal: true

module Neo4j
  module Http
    class AuthToken
      def self.token(username, password)
        new(username, password).token
      end

      def initialize(username, password)
        @username = username
        @password = password
      end

      # See: https://neo4j.com/docs/developer-manual/current/http-api/authentication/#http-api-authenticate-to-access-the-server
      def token
        return "" if @username.blank? || @password.blank?

        Base64.encode64("#{@username}:#{@password}")
      end
    end
  end
end
