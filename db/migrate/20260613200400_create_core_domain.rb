class CreateCoreDomain < ActiveRecord::Migration[8.1]
  def change
    # Site-wide configuration (singleton). Mirrors the legacy "Government" concept:
    # a single deployment represents one self-governing community.
    create_table :governments do |t|
      t.string  :name, default: "White House"
      t.string  :tagline
      t.string  :mission
      t.string  :prompt, default: "What do you think the government should do?"
      t.string  :tags_name, default: "Category"
      t.string  :briefing_name, default: "Briefing Room"
      t.string  :currency_name, default: "political capital"
      t.string  :currency_short_name, default: "pc"
      t.string  :homepage, default: "top"
      t.boolean :is_tags, default: true
      t.boolean :is_branches, default: false
      t.string  :language_code, default: "en"
      t.integer :official_user_id        # the "leader" whose endorsements mark official status
      t.integer :priorities_count, default: 0
      t.integer :points_count, default: 0
      t.integer :documents_count, default: 0
      t.integer :users_count, default: 0
      t.integer :endorsements_count, default: 0
      t.timestamps
    end

    create_table :branches do |t|
      t.string  :name
      t.text    :description
      t.integer :users_count, default: 0
      t.integer :endorsements_count, default: 0
      t.timestamps
    end

    create_table :priorities do |t|
      t.integer  :user_id
      t.string   :name, limit: 140
      t.string   :status, default: "published"
      t.integer  :position, default: 0
      t.integer  :score, default: 0
      t.integer  :trending_score, default: 0
      t.integer  :controversial_score, default: 0
      t.boolean  :is_controversial, default: false
      t.integer  :official_status, default: 0   # -2 failed, -1 compromise, 0 unknown, 1 in works, 2 successful
      t.integer  :official_value, default: 0     # -1 opposed, 0 none, 1 endorsed by official
      t.integer  :endorsements_count, default: 0
      t.integer  :up_endorsements_count, default: 0
      t.integer  :down_endorsements_count, default: 0
      t.integer  :points_count, default: 0
      t.integer  :up_points_count, default: 0
      t.integer  :down_points_count, default: 0
      t.integer  :neutral_points_count, default: 0
      t.integer  :documents_count, default: 0
      t.integer  :discussions_count, default: 0
      t.string   :cached_issue_list
      t.string   :short_url, limit: 40
      t.string   :ip_address, limit: 45
      t.datetime :published_at
      t.datetime :deleted_at
      t.datetime :status_changed_at
      t.timestamps
    end
    add_index :priorities, :user_id
    add_index :priorities, :status
    add_index :priorities, :position

    create_table :endorsements do |t|
      t.integer  :user_id
      t.integer  :priority_id
      t.integer  :value, default: 1            # +1 endorse, -1 oppose
      t.integer  :position
      t.integer  :score, default: 0
      t.string   :status, default: "active"    # active, inactive, finished, suspended
      t.string   :ip_address, limit: 45
      t.timestamps
    end
    add_index :endorsements, :user_id
    add_index :endorsements, :priority_id
    add_index :endorsements, [:user_id, :priority_id], unique: true

    create_table :points do |t|
      t.integer  :user_id
      t.integer  :priority_id
      t.integer  :other_priority_id
      t.integer  :value, default: 0            # 1 supports, -1 opposes, 0 neutral
      t.string   :name, limit: 140
      t.text     :content
      t.string   :website
      t.string   :status, default: "published"
      t.integer  :helpful_count, default: 0
      t.integer  :unhelpful_count, default: 0
      t.integer  :discussions_count, default: 0
      t.datetime :published_at
      t.timestamps
    end
    add_index :points, :priority_id
    add_index :points, :user_id
    add_index :points, :status

    create_table :point_qualities do |t|
      t.integer  :user_id
      t.integer  :point_id
      t.boolean  :value, default: true         # true = helpful, false = unhelpful
      t.timestamps
    end
    add_index :point_qualities, [:user_id, :point_id], unique: true

    create_table :documents do |t|
      t.integer  :user_id
      t.integer  :priority_id
      t.integer  :value, default: 0
      t.string   :name, limit: 140
      t.text     :content
      t.string   :status, default: "published"
      t.integer  :helpful_count, default: 0
      t.integer  :unhelpful_count, default: 0
      t.integer  :revisions_count, default: 0
      t.datetime :published_at
      t.timestamps
    end
    add_index :documents, :priority_id
    add_index :documents, :user_id

    create_table :tags do |t|
      t.string   :name, limit: 60
      t.string   :slug, limit: 60
      t.string   :title, limit: 60
      t.string   :description, limit: 200
      t.string   :prompt, limit: 100
      t.integer  :priorities_count, default: 0
      t.integer  :points_count, default: 0
      t.integer  :documents_count, default: 0
      t.integer  :top_priority_id
      t.timestamps
    end
    add_index :tags, :slug, unique: true

    create_table :taggings do |t|
      t.integer  :tag_id
      t.integer  :taggable_id
      t.string   :taggable_type, limit: 50
      t.integer  :tagger_id
      t.timestamps
    end
    add_index :taggings, [:taggable_id, :taggable_type]
    add_index :taggings, :tag_id

    create_table :activities do |t|
      t.integer  :user_id
      t.integer  :other_user_id
      t.string   :type, limit: 80              # STI discriminator
      t.string   :status, default: "active"
      t.integer  :priority_id
      t.integer  :point_id
      t.integer  :document_id
      t.integer  :comment_id
      t.integer  :comments_count, default: 0
      t.boolean  :is_user_only, default: false
      t.datetime :changed_at
      t.timestamps
    end
    add_index :activities, :priority_id
    add_index :activities, :user_id
    add_index :activities, :type
    add_index :activities, :created_at

    create_table :comments do |t|
      t.integer  :activity_id
      t.integer  :user_id
      t.string   :status, default: "published"
      t.text     :content
      t.boolean  :is_endorser, default: false
      t.boolean  :is_opposer, default: false
      t.integer  :flags_count, default: 0
      t.timestamps
    end
    add_index :comments, :activity_id
    add_index :comments, :user_id

    create_table :followings do |t|
      t.integer  :user_id
      t.integer  :other_user_id
      t.integer  :value, default: 1            # 1 follow, -1 ignore
      t.timestamps
    end
    add_index :followings, [:user_id, :other_user_id], unique: true

    create_table :messages do |t|
      t.integer  :sender_id
      t.integer  :recipient_id
      t.string   :title, limit: 140
      t.text     :content
      t.string   :status, default: "sent"
      t.datetime :read_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :messages, :recipient_id
    add_index :messages, :sender_id

    create_table :notifications do |t|
      t.integer  :sender_id
      t.integer  :recipient_id
      t.string   :type, limit: 80
      t.string   :status, default: "unread"
      t.integer  :notifiable_id
      t.string   :notifiable_type
      t.datetime :read_at
      t.timestamps
    end
    add_index :notifications, :recipient_id
    add_index :notifications, [:notifiable_type, :notifiable_id]

    create_table :changes do |t|
      t.integer  :user_id
      t.integer  :priority_id
      t.integer  :new_priority_id
      t.string   :type, limit: 60              # ChangeName, ChangeMerge, ChangeFlip
      t.string   :status, default: "sent"
      t.text     :content
      t.integer  :votes_count, default: 0
      t.integer  :yes_votes, default: 0
      t.integer  :no_votes, default: 0
      t.boolean  :is_flip, default: false
      t.datetime :approved_at
      t.datetime :declined_at
      t.timestamps
    end
    add_index :changes, :priority_id

    create_table :votes do |t|
      t.integer  :change_id
      t.integer  :user_id
      t.integer  :value, default: 1            # 1 yes, -1 no
      t.string   :status, default: "active"
      t.datetime :voted_at
      t.timestamps
    end
    add_index :votes, :change_id
    add_index :votes, [:change_id, :user_id], unique: true

    create_table :pages do |t|
      t.string   :name, limit: 100
      t.string   :short_name, limit: 60
      t.string   :link_name, limit: 60
      t.text     :content
      t.timestamps
    end
    add_index :pages, :short_name, unique: true

    create_table :blurbs do |t|
      t.string   :name, limit: 60
      t.text     :content
      t.timestamps
    end
    add_index :blurbs, :name, unique: true
  end
end
