class ChatRoomTable < ApplicationRecord
  validates :name, presence: true

  has_many :messages, foreign_key: :room_id, dependent: :destroy
end

