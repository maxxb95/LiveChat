class Message < ApplicationRecord
  validates :content, presence: true, length: { maximum: 10000 }
  validates :session_id, presence: true

  belongs_to :chat_room_table, foreign_key: :room_id, optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :ordered, -> { order(created_at: :asc) }
end


