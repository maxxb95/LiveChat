class MessagesController < ApplicationController
  before_action :set_session_id

  # GET /messages
  def index
    @messages = Message.ordered.limit(100)
    render json: @messages.map { |m| message_json(m) }
  end

  # POST /messages
  def create
    @message = Message.new(message_params)
    @message.session_id = @session_id
    @message.ip_address = request.remote_ip

    if @message.save
      # Broadcast to ActionCable
      ActionCable.server.broadcast('chat_channel', message_json(@message))
      render json: message_json(@message), status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :username)
  end

  def set_session_id
    @session_id = request.headers['X-Session-ID'] || SecureRandom.uuid
  end

  def message_json(message)
    {
      id: message.id,
      content: message.content,
      username: message.username,
      session_id: message.session_id,
      created_at: message.created_at,
      is_mine: message.session_id == @session_id
    }
  end
end

