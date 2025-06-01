module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Extract token from connection params or headers
      token = request.params[:token] || extract_token_from_headers

      if token && (decoded_token = User.decode_token(token))
        user = User.find(decoded_token[0]["user_id"])

        # Update user's last seen
        user.update_column(:last_seen_at, Time.current)

        user
      else
        reject_unauthorized_connection
      end
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      reject_unauthorized_connection
    end

    def extract_token_from_headers
      # Extract from Authorization header for web socket connections
      auth_header = request.headers["Authorization"]
      auth_header&.split(" ")&.last
    end
  end
end
