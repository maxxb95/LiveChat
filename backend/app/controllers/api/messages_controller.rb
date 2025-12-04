module Api
  class MessagesController < ApplicationController
    before_action :set_session_id

    # GET /api/messages
    # Query params:
    #   - page: Page number (default: 1)
    #   - per_page: Items per page (default: 50, max: 100)
    def index
      page = pagination_params[:page].to_i
      per_page = [pagination_params[:per_page].to_i, 100].min
      per_page = 50 if per_page < 1 # Default to 50 if invalid

      page = 1 if page < 1 # Ensure page is at least 1

      total_count = Message.count
      offset = (page - 1) * per_page
      total_pages = (total_count.to_f / per_page).ceil

      @messages = Message.ordered.limit(per_page).offset(offset)

      render json: {
        messages: @messages.map { |m| message_json(m) },
        pagination: {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: total_pages,
          has_next_page: page < total_pages,
          has_prev_page: page > 1
        }
      }
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error("Database error in messages#index: #{e.message}")
      render json: { error: 'Failed to retrieve messages', message: 'Database error occurred' }, status: :internal_server_error
    end

    # POST /api/messages
    def create
      room_id = message_params[:room_id]
      
      if room_id.blank?
        render json: { error: 'room_id is required' }, status: :bad_request
        return
      end

      # Validate that the room exists
      unless ChatRoomTable.exists?(id: room_id)
        render json: { error: 'Invalid room_id' }, status: :bad_request
        return
      end

      @message = Message.new(message_params)
      @message.session_id = @session_id
      @message.ip_address = request.remote_ip

      if @message.save
        broadcast_message(@message)
        render json: message_json(@message), status: :created
      else
        render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Validation error in messages#create: #{e.message}")
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error("Database error in messages#create: #{e.message}")
      render json: { error: 'Failed to save message', message: 'Database error occurred' }, status: :internal_server_error
    end

    # GET /api/messages/:roomId
    def by_room
      room_id = params[:roomId]

      # Check if room exists
      unless ChatRoomTable.exists?(id: room_id)
        render json: { error: 'Room not found' }, status: :not_found
        return
      end

      @messages = Message.where(room_id: room_id).ordered

      render json: {
        messages: @messages.map { |m| message_json(m) }
      }
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error("Database error in messages#by_room: #{e.message}")
      render json: { error: 'Failed to retrieve messages', message: 'Database error occurred' }, status: :internal_server_error
    end

    private

    def pagination_params
      params.permit(:page, :per_page)
    end

    def message_params
      params.require(:message).permit(:content, :room_id)
    rescue ActionController::ParameterMissing => e
      Rails.logger.error("Parameter missing in messages#create: #{e.message}")
      raise
    end

    def set_session_id
      @session_id = request.headers['X-Session-ID'] || SecureRandom.uuid
    rescue StandardError => e
      Rails.logger.error("Error setting session ID: #{e.message}")
      @session_id = SecureRandom.uuid
    end

    def broadcast_message(message)
      message_data = message_json(message)
      channel_name = message.room_id.present? ? "chat_channel_#{message.room_id}" : 'chat_channel'
      ActionCable.server.broadcast(channel_name, message_data)
    rescue StandardError => e
      Rails.logger.error("Failed to broadcast message via ActionCable: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end

    def message_json(message)
      {
        id: message.id,
        content: message.content,
        session_id: message.session_id,
        ip_address: message.ip_address,
        normalized_ip: normalize_ip_safely(message.ip_address),
        room_id: message.room_id,
        created_at: message.created_at,
      }
    rescue StandardError => e
      Rails.logger.error("Error serializing message: #{e.message}")
      # Return message without normalized_ip if normalization fails
      {
        id: message.id,
        content: message.content,
        session_id: message.session_id,
        ip_address: message.ip_address,
        normalized_ip: nil,
        room_id: message.room_id,
        created_at: message.created_at,
      }
    end

    def normalize_ip_safely(ip_address)
      IpNormalizer.normalize(ip_address)
    rescue StandardError => e
      Rails.logger.error("Error normalizing IP address: #{e.message}")
      nil
    end
  end
end

