class AddRoomToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :room_id, :integer
    add_index :messages, :room_id
  end
end