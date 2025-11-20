module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # For now, we allow all connections
    # In the future, you can add authentication here
    identified_by :session_id

    def connect
      # Try to get session_id from query params (WebSocket) or headers (HTTP)
      self.session_id = request.params[:session_id] || 
                        request.headers['X-Session-ID'] || 
                        SecureRandom.uuid
    end
  end
end

