module Admin
  class DashboardController < BaseController
    def index
      @counts = {
        priorities: Priority.count,
        users: User.count,
        points: Point.count,
        documents: Document.count,
        endorsements: Endorsement.count,
        comments: Comment.count
      }
      @recent_priorities = Priority.newest.limit(10)
      @recent_users = User.newest.limit(10)
    end
  end
end
