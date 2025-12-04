module Api
  class ChatRoomTablesController < ApplicationController
    # GET /api/chat_room_tables
    def index
      @chat_rooms = ChatRoomTable.all
      render json: @chat_rooms.map { |room| chat_room_json(room) }
    end

    # POST /api/chat_room_tables
    def create
      @chat_room = ChatRoomTable.new(chat_room_params)

      if @chat_room.save
        render json: chat_room_json(@chat_room), status: :created
      else
        render json: { errors: @chat_room.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def chat_room_params
      params.require(:chat_room_table).permit(:name)
    end

    def chat_room_json(chat_room)
      {
        id: chat_room.id,
        name: chat_room.name,
        created_at: chat_room.created_at,
        updated_at: chat_room.updated_at
      }
    end
  end
end

