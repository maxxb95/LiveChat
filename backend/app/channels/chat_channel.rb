class ChatChannel < ApplicationCable::Channel
  def subscribed
    @room_id = params[:room_id]
    channel_name = channel_name_for_room(@room_id)
    stream_from channel_name
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
      channel_name_for_room(@room_id),
      {
        type: 'typing',
        normalized_ip: normalized_ip,
        is_typing: data['is_typing'] || false
      }
    )
  end
  
  private

  def channel_name_for_room(room_id)
    if room_id.present?
      "chat_channel_#{room_id}"
    else
      'chat_channel'
    end
  end

  def broadcast_typing_stopped
    normalized_ip = connection.normalized_ip
    
    # Don't broadcast if normalized_ip is not available
    return if normalized_ip.blank?
    
    ActionCable.server.broadcast(
      channel_name_for_room(@room_id),
      {
        type: 'typing',
        normalized_ip: normalized_ip,
        is_typing: false
      }
    )
  end
end



