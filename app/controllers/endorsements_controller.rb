class EndorsementsController < ApplicationController
  before_action :require_login

  # The signed-in user's personal ranked list.
  def index
    @endorsements = current_user.endorsements.active.by_position.includes(:priority)
  end

  # Accepts an ordered array of endorsement ids and re-ranks them.
  def reorder
    ids = Array(params[:endorsement_ids]).map(&:to_i)
    ids.each_with_index do |eid, i|
      e = current_user.endorsements.find_by(id: eid)
      next unless e
      e.update_columns(position: i + 1, score: position_score(e, i + 1))
    end
    current_user.endorsements.active.includes(:priority).map(&:priority).uniq.each(&:recalculate_score!)
    Priority.recalculate_positions!
    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to endorsements_path, notice: "Your priorities were re-ranked." }
    end
  end

  private

  def position_score(endorsement, pos)
    return 0 if pos > Priority::MAX_POSITION
    (current_user.score * endorsement.value * (Priority::MAX_POSITION - pos)).to_i
  end
end
