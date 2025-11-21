module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # For now, we allow all connections
    # In the future, you can add authentication here
    identified_by :session_id
    attr_accessor :normalized_ip

    def connect
      # Get session_id from headers if provided, otherwise generate one
      self.session_id = request.headers['X-Session-ID'] || SecureRandom.uuid
      # Store normalized IP for use in channels
      self.normalized_ip = IpNormalizer.normalize(request.remote_ip)
    end
  end
end

