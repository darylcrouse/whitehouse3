class CreateUsersTable < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :login, limit: 40
      t.string :email, limit: 100
      t.string :crypted_password, limit: 40
      t.string :salt, limit: 40
      t.string :first_name, limit: 100
      t.string :last_name, limit: 100
      t.datetime :activated_at
      t.string :activation_code, limit: 60
      t.string :remember_token, limit: 60
      t.datetime :remember_token_expires_at
      t.integer :picture_id
      t.string :status, limit: 30, default: "passive"
      t.integer :partner_id
      t.datetime :deleted_at
      t.string :ip_address, limit: 16
      t.datetime :loggedin_at
      t.string :zip, limit: 10
      t.date :birth_date
      t.string :twitter_login, limit: 15
      t.string :website, limit: 150
      t.boolean :is_mergeable, default: true
      t.integer :referral_id
      t.boolean :is_subscribed, default: true
      t.string :user_agent, limit: 200
      t.string :referrer, limit: 200
      t.boolean :is_comments_subscribed, default: true
      t.boolean :is_votes_subscribed, default: true
      t.boolean :is_newsletter_subscribed, default: true
      t.boolean :is_tagger, default: false
      t.integer :endorsements_count, default: 0
      t.integer :up_endorsements_count, default: 0
      t.integer :down_endorsements_count, default: 0
      t.integer :up_issues_count, default: 0
      t.integer :down_issues_count, default: 0
      t.integer :comments_count, default: 0
      t.float :score, default: 0.1
      t.boolean :is_point_changes_subscribed, default: true
      t.boolean :is_messages_subscribed, default: true
      t.integer :capitals_count, default: 0
      t.integer :twitter_count, default: 0
      t.integer :followers_count, default: 0
      t.integer :followings_count, default: 0
      t.integer :ignorers_count, default: 0
      t.integer :ignorings_count, default: 0
      t.integer :position_24hr, default: 0
      t.integer :position_7days, default: 0
      t.integer :position_30days, default: 0
      t.integer :position_24hr_change, default: 0
      t.integer :position_7days_change, default: 0
      t.integer :position_30days_change, default: 0
      t.integer :position, default: 0
      t.boolean :is_followers_subscribed, default: true
      t.integer :partner_referral_id
      t.integer :ads_count, default: 0
      t.integer :changes_count, default: 0
      t.string :google_token, limit: 30
      t.integer :top_endorsement_id
      t.boolean :is_finished_subscribed, default: true
      t.integer :contacts_count, default: 0
      t.integer :contacts_members_count, default: 0
      t.integer :contacts_invited_count, default: 0
      t.integer :contacts_not_invited_count, default: 0
      t.datetime :google_crawled_at
      t.integer :facebook_uid
      t.string :city, limit: 80
      t.string :state, limit: 50
      t.integer :documents_count, default: 0
      t.integer :document_revisions_count, default: 0
      t.integer :points_count, default: 0
      t.float :index_24hr_change, default: 0.0
      t.float :index_7days_change, default: 0.0
      t.float :index_30days_change, default: 0.0
      t.integer :received_notifications_count, default: 0
      t.integer :unread_notifications_count, default: 0
      t.string :rss_code, limit: 40
      t.integer :point_revisions_count, default: 0
      t.integer :qualities_count, default: 0
      t.integer :constituents_count, default: 0
      t.string :address, limit: 100
      t.integer :warnings_count, default: 0
      t.datetime :probation_at
      t.datetime :suspended_at
      t.integer :referrals_count, default: 0
      t.boolean :is_admin, default: false
      t.integer :branch_id
      t.integer :branch_position, default: 0
      t.integer :branch_position_24hr, default: 0
      t.integer :branch_position_7days, default: 0
      t.integer :branch_position_30days, default: 0
      t.integer :branch_position_24hr_change, default: 0
      t.integer :branch_position_7days_change, default: 0
      t.integer :branch_position_30days_change, default: 0
      t.integer :twitter_id
      t.string :twitter_token, limit: 64
      t.string :twitter_secret, limit: 64
      t.datetime :twitter_crawled_at
      t.boolean :is_admin_subscribed, default: true
      t.boolean :is_branch_chosen, default: false
      t.boolean :is_importing_contacts, default: false
      t.integer :imported_contacts_count, default: 0

      t.timestamps
    end

    add_index :users, :facebook_uid
    add_index :users, :rss_code
    add_index :users, :status
    add_index :users, :twitter_id
  end
end
