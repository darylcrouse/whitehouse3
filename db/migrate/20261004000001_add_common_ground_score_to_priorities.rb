class AddCommonGroundScoreToPriorities < ActiveRecord::Migration[8.0]
  # WH3 concept: the agenda's headline metric. "A priority's score is its
  # support in the group that likes it least, on a 0 to 100 scale."
  #
  # We approximate "opinion groups" with the app's existing cross-viewpoint
  # signal: branch membership when branches are in use, otherwise the user's
  # own endorsing/opposing pattern is not a group marker, so we fall back to
  # endorser-vs-opposer vantage per priority. The score is computed by
  # PriorityRanker (see common_ground_score_for) and cached here.
  def change
    add_column :priorities, :common_ground_score, :integer, default: 0, null: false
    add_index :priorities, :common_ground_score
  end
end
