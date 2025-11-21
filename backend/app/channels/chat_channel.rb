class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'chat_channel'
  end

  def unsubscribed
    # Broadcast that this user stopped typing when they disconnect
    broadcast_typing_stopped
  end

  def typing(data)
    # Broadcast typing status to other users, with normalized_ip to identify the "typer"
    normalized_ip = connection.normalized_ip
    
    # Don't broadcast if normalized_ip is not available
    return if normalized_ip.blank?
    
    ActionCable.server.broadcast(
      'chat_channel',
      {
        type: 'typing',
        normalized_ip: normalized_ip,
        is_typing: data['is_typing'] || false
      }
    )
  end
  
  private

  def broadcast_typing_stopped
    normalized_ip = connection.normalized_ip
    
    # Don't broadcast if normalized_ip is not available
    return if normalized_ip.blank?
    
    ActionCable.server.broadcast(
      'chat_channel',
      {
        type: 'typing',
        normalized_ip: normalized_ip,
        is_typing: false
      }
    )
  end
end



