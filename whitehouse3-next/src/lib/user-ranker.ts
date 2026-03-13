/**
 * User ranking algorithm - ported from lib/user_ranker.rb
 *
 * Calculates a user's score (0.1 to 1.0) based on their activity level.
 */

interface UserForScoring {
  status: string;
  loggedinAt: Date | null;
  pointsCount: number;
  upIssuesCount: number;
  upEndorsementsCount: number;
  constituentsCount: number;
  qualitiesCount: number;
  documentRevisionsCount: number;
  pointRevisionsCount: number;
  isTags: boolean;
}

/**
 * Check if user has logged in within the last 30 days
 */
function recentLogin(loggedinAt: Date | null): boolean {
  if (!loggedinAt) return false;
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  return loggedinAt > thirtyDaysAgo;
}

/**
 * Calculate issue diversity for a user's endorsements
 */
function upIssueDiversity(
  upIssuesCount: number,
  upEndorsementsCount: number,
  isTags: boolean
): number {
  if (upEndorsementsCount < 5 || !isTags) return 0;
  return upIssuesCount / upEndorsementsCount;
}

/**
 * Calculate user score (0.1 to 1.0)
 */
export function calculateUserScore(user: UserForScoring): number {
  let count = 0.1;
  if (user.status === "active") count += 1;
  if (recentLogin(user.loggedinAt)) count += 3;
  if (user.pointsCount > 0) count += 0.5;
  count += upIssueDiversity(
    user.upIssuesCount,
    user.upEndorsementsCount,
    user.isTags
  );
  if (user.constituentsCount > 1) count += 0.6;
  count = count / 6;
  if (count > 1) count = 1;
  if (count < 0.1) count = 0.1;
  return count;
}

/**
 * Calculate quality factor for a user's contributions
 */
export function calculateQualityFactor(
  qualitiesCount: number,
  documentRevisionsCount: number,
  pointRevisionsCount: number
): number {
  if (qualitiesCount < 10) return 1;
  const revCount = documentRevisionsCount + pointRevisionsCount;
  if (revCount === 0) return 10 / qualitiesCount;
  const i = (revCount * 2) / qualitiesCount;
  return i > 1 ? 1 : i;
}
