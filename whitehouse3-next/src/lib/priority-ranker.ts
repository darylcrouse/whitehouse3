/**
 * Priority ranking algorithm - ported from lib/priority_ranker.rb
 *
 * Calculates priority scores based on endorsement positions and user scores.
 * Each endorsement contributes: user.score * endorsement.value * (maxPosition - position)
 * where maxPosition is 100 (endorsements beyond position 100 score 0).
 */

const MAX_POSITION = 100;

interface EndorsementForScoring {
  position: number;
  value: number; // 1 or -1
  userScore: number;
}

/**
 * Calculate the score for a single endorsement
 */
export function calculateEndorsementScore(
  endorsement: EndorsementForScoring
): number {
  if (endorsement.position > MAX_POSITION) return 0;
  return (
    endorsement.userScore *
    endorsement.value *
    (MAX_POSITION - endorsement.position)
  );
}

/**
 * Calculate the total score for a priority based on all its active endorsements
 */
export function calculatePriorityScore(
  endorsements: EndorsementForScoring[]
): number {
  return endorsements.reduce(
    (total, e) => total + calculateEndorsementScore(e),
    0
  );
}

/**
 * Calculate trending score based on position changes
 */
export function calculateTrendingScore(
  position24hrChange: number,
  position7daysChange: number,
  position30daysChange: number
): number {
  // Weight recent changes more heavily
  return position24hrChange * 3 + position7daysChange * 2 + position30daysChange;
}

/**
 * Determine if a priority is controversial based on endorsement ratios
 */
export function isControversial(
  upEndorsementsCount: number,
  downEndorsementsCount: number
): boolean {
  if (downEndorsementsCount === 0 || upEndorsementsCount === 0) return false;
  const ratio = upEndorsementsCount / downEndorsementsCount;
  return ratio > 0.5 && ratio < 2;
}
