require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  # Notification and its STI subclasses used to live in one file. Zeitwerk
  # binds one autoload per file, so a dev reload unloaded Notification but left
  # the subclasses holding the previous class object, and the next load raised
  #   TypeError: superclass mismatch for class NotificationChangeVote
  # which broke InboxController#notifications with a 500. One file per constant
  # is what makes the reload safe, so this test guards the structure: merging
  # them back reintroduces the bug.
  EXPECTED_SUBCLASSES = %w[
    NotificationChangeVote NotificationChangeProposed NotificationComment
    NotificationCommentFlagged NotificationContactJoined NotificationFollower
    NotificationInvitationAccepted NotificationMessage
    NotificationPriorityFlagged NotificationProfileBulletin
    NotificationPointRevision NotificationDocumentRevision
    NotificationPriorityFinished NotificationWarning1 NotificationWarning2
    NotificationWarning3
  ].freeze

  test "each notification subclass has its own autoloadable file" do
    EXPECTED_SUBCLASSES.each do |name|
      path = Rails.root.join("app", "models", "#{name.underscore}.rb")
      assert File.exist?(path), "#{name} must live in #{path.basename} for Zeitwerk to reload it"

      klass = name.constantize
      assert_equal "Notification", klass.superclass.name,
                   "#{name} must still inherit from Notification"
    end
  end

  test "subclasses are not redefined inside notification.rb" do
    body = File.read(Rails.root.join("app", "models", "notification.rb"))
    offenders = EXPECTED_SUBCLASSES.select { |name| body.include?("class #{name} < Notification") }
    assert_empty offenders, "these subclasses are back in notification.rb: #{offenders.join(', ')}"
  end
end
