class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.text :content, null: false
      t.string :username
      t.string :session_id, null: false
      t.string :ip_address
      t.timestamps
    end

    add_index :messages, :session_id
    add_index :messages, :created_at
  end
end


