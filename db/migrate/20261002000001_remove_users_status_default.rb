class RemoveUsersStatusDefault < ActiveRecord::Migration[8.0]
  # The 2009 MySQL schema had no default on users.status, so Rails-2 records
  # were created with a NULL status and aasm's initial state (:pending, with
  # its do_pending hook) applied. The SQLite port added DEFAULT 'passive' —
  # and since modern Rails materializes column defaults at instantiation,
  # aasm saw a non-nil "current state" and never applied the initial state.
  # Result: every new signup landed in :passive, could not log in
  # (User.authenticate only accepts active/pending) and never received the
  # welcome/activation email. Removing the default restores aasm semantics.
  def change
    change_column_default :users, :status, from: "passive", to: nil
  end
end
