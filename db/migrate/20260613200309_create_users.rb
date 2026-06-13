class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :email_address, null: false
      t.string  :password_digest, null: false
      t.string  :login                              # public username / short_name
      t.string  :first_name
      t.string  :last_name
      t.text    :bio
      t.string  :website
      t.string  :city
      t.string  :state
      t.string  :status, default: "active"
      t.boolean :is_admin, default: false
      t.float   :score, default: 1.0                # weight applied to this user's endorsements
      t.integer :branch_id

      # denormalized counters (kept in sync via callbacks, mirrors the legacy design)
      t.integer :endorsements_count, default: 0
      t.integer :up_endorsements_count, default: 0
      t.integer :down_endorsements_count, default: 0
      t.integer :points_count, default: 0
      t.integer :comments_count, default: 0
      t.integer :followers_count, default: 0
      t.integer :followings_count, default: 0
      t.integer :top_endorsement_id

      t.datetime :loggedin_at

      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :login, unique: true
    add_index :users, :branch_id
  end
end
