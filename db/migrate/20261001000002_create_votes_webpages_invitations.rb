class CreateVotesWebpagesInvitations < ActiveRecord::Migration[8.0]
  # Three tables from the 2009 schema that the port dropped: `votes` and
  # `webpages` existed in the original schema.rb (54 tables) but were lost;
  # `invitations` backs a model whose CREATE TABLE was never committed even in
  # the original repo — columns derived from the model's associations and
  # validations.
  #
  # Idempotent: the first run failed partway (SQLite index names are global
  # and the original 2009 index was literally named "status"), so every step
  # is guarded.
  def change
    unless table_exists?(:votes)
      create_table :votes do |t|
        t.integer  :change_id
        t.integer  :user_id
        t.string   :code
        t.string   :status
        t.datetime :voted_at
        t.integer  :value, default: 1
        t.timestamps
      end
    end
    add_index :votes, :change_id, name: 'votes_change_id_index' unless index_exists?(:votes, :change_id)
    add_index :votes, :code, name: 'votes_code_index' unless index_exists?(:votes, :code)
    add_index :votes, :status, name: 'votes_status_index' unless index_exists?(:votes, :status)
    add_index :votes, :user_id, name: 'votes_user_id_index' unless index_exists?(:votes, :user_id)

    unless table_exists?(:webpages)
      create_table :webpages do |t|
        t.integer  :user_id
        t.string   :status, limit: 20
        t.string   :url
        t.string   :title
        t.string   :description
        t.datetime :crawled_at
        t.string   :content_type
        t.string   :charset
        t.string   :content_encoding
        t.datetime :published_at
        t.string   :cached_issue_list, limit: 150
        t.integer  :feed_id
        t.string   :domain, limit: 100
        t.timestamps
      end
    end
    add_index :webpages, :feed_id, name: 'index_webpages_on_feed_id' unless index_exists?(:webpages, :feed_id)
    add_index :webpages, :status, name: 'index_webpages_on_status' unless index_exists?(:webpages, :status)
    add_index :webpages, :user_id, name: 'webpages_user_id_index' unless index_exists?(:webpages, :user_id)

    unless table_exists?(:invitations)
      create_table :invitations do |t|
        t.integer  :user_id
        t.integer  :sender_id
        t.integer  :partner_id
        t.integer  :to_id
        t.string   :to_email
        t.string   :to_name
        t.string   :from_name
        t.string   :facebook_uid
        t.string   :status
        t.datetime :sent_at
        t.datetime :accepted_at
        t.timestamps
      end
    end
    add_index :invitations, :user_id, name: 'invitations_user_id_index' unless index_exists?(:invitations, :user_id)
    add_index :invitations, :sender_id, name: 'invitations_sender_id_index' unless index_exists?(:invitations, :sender_id)
  end
end
