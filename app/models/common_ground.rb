# WH3 common-ground score.
#
# "A priority's score is its support in the group that likes it least, on a
# 0 to 100 scale. One side alone can't push it up." (WH3 transparency page)
#
# Opinion groups — never by party, only by how members actually vote:
#
#   * When the government uses branches (the app's own constituency system,
#     whose whole point is "no one constituency dominates the agenda"), each
#     branch is a group.
#   * Otherwise members are split into two blocs by their voting pattern: the
#     two members who disagree most — measured across the priorities they both
#     voted on — become the poles, and everyone else joins the pole they agree
#     with more. Ties go to the lower-id pole, so the split is deterministic.
#
# Score per priority:
#
#   support(group) = endorsements / (endorsements + oppositions) within that
#   group, counted over ACTIVE endorsements only. A group whose only votes are
#   oppositions contributes 0. The score is the MINIMUM across groups that
#   voted on the priority, scaled 0-100 — and at least two groups must have
#   voted: one group alone cannot produce a score.
#
# Recomputed by PriorityRanker on its normal cycle, by db/seeds.rb, and
# on demand via `CommonGround.recompute!`.
class CommonGround
  MIN_GROUPS = 2

  class << self
    # Recomputes and persists priorities.common_ground_score for every
    # published priority. Returns { priority_id => score } for scored rows.
    def recompute!
      voting_groups = opinion_groups.reject { |_key, ids| ids.empty? }
      scores = voting_groups.size >= MIN_GROUPS ? compute_scores(voting_groups) : {}

      Priority.where(status: 'published').find_each do |p|
        s = scores[p.id].to_i
        p.update_column(:common_ground_score, s) if p.common_ground_score.to_i != s
      end
      scores
    end

    # Returns { group_key => [user_id, ...] } — see class comment.
    def opinion_groups
      gov = Government.current || Government.first
      return {} unless gov

      if gov.is_branches? && Branch.count > 0
        Branch.all.each_with_object({}) { |b, h| h["branch_#{b.id}"] = b.user_ids }
      else
        voting_pattern_groups
      end
    end

    # Two blocs, split by voting agreement (exact value match on priorities
    # both members voted on). Deterministic: sorted ids, lowest-agreement
    # pair wins ties, remaining members join the nearer pole (ties -> 'a').
    #
    # Guards: the government's official user is never part of opinion groups
    # (their stance is tracked separately via priorities.obama_value), and a
    # pole must clear MIN_SHARED_VOTES shared priorities — a one-off voter
    # must not define the split.
    MIN_POLE_VOTES = 3
    MIN_SHARED_VOTES = 3

    def voting_pattern_groups
      official_id = (Government.current || Government.first)&.official_user_id

      votes = Hash.new { |h, k| h[k] = {} }
      Endorsement.active.pluck(:user_id, :priority_id, :value).each do |uid, pid, val|
        next if uid == official_id
        votes[uid][pid] = val.to_i
      end

      # Pole candidates need enough votes to have a stable pattern; everyone
      # with any vote still joins a bloc below so all votes count.
      pole_ids = votes.keys.select { |uid| votes[uid].size >= MIN_POLE_VOTES }.sort
      return { 'a' => [], 'b' => [] } if pole_ids.size < 2

      best_pair = nil
      best_score = nil
      best_shared = nil
      pole_ids.combination(2) do |x, y|
        shared = votes[x].keys & votes[y].keys
        next if shared.size < MIN_SHARED_VOTES
        agree = shared.count { |pid| votes[x][pid] == votes[y][pid] }
        score = agree.to_f / shared.size
        if best_score.nil? || score < best_score ||
           (score == best_score && shared.size > best_shared)
          best_score = score
          best_shared = shared.size
          best_pair = [x, y]
        end
      end
      return { 'a' => [], 'b' => [] } unless best_pair

      pole_a, pole_b = best_pair
      groups = { 'a' => [pole_a], 'b' => [pole_b] }
      (votes.keys - best_pair).each do |uid|
        a = agreement(votes, uid, pole_a)
        b = agreement(votes, uid, pole_b)
        if a > b
          groups['a'] << uid
        elsif b > a
          groups['b'] << uid
        else
          groups['a'] << uid
        end
      end
      groups
    end

    # Fraction of shared priorities on which the two voters chose the same
    # value (+1/+1 or -1/-1 = agreement; +1/-1 = disagreement).
    def agreement(votes, a, b)
      shared = votes[a].keys & votes[b].keys
      return 0.0 if shared.empty?

      shared.count { |pid| votes[a][pid] == votes[b][pid] }.to_f / shared.size
    end

    private

    def compute_scores(voting_groups)
      group_of = {}
      voting_groups.each { |key, ids| ids.each { |u| group_of[u] = key } }

      # pid => group_key => [up, down]
      counts = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [0, 0] } }
      Endorsement.active.where(user_id: group_of.keys)
                         .pluck(:user_id, :priority_id, :value).each do |uid, pid, val|
        bucket = counts[pid][group_of[uid]]
        val.to_i > 0 ? bucket[0] += 1 : bucket[1] += 1
      end

      scores = {}
      counts.each do |pid, by_group|
        shares = by_group.values.map do |up, down|
          total = up + down
          total > 0 ? up.to_f / total : nil
        end.compact
        next if shares.size < MIN_GROUPS

        scores[pid] = (shares.min * 100).round
      end
      scores
    end
  end
end
