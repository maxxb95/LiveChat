class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'chat_channel'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak(data)
    # This method can be called from the client if needed
    # For now, we're using REST API to create messages
    ActionCable.server.broadcast('chat_channel', data)
  end
end



