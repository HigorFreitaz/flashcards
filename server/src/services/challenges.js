import { pool } from '../db.js';
import { createNotification } from './notifications.js';
export function challengeJson(row) {
  return { id: row.id, week: row.week, title: row.title, detail: row.detail, scorePercent: row.score_percent,
    success: row.success, joined: row.joined, kind: row.kind, status: row.status,
    targetCount: row.target_count, deckIds: row.deck_ids, weakOnly: row.weak_only,
    answered: row.answered, startsAt: row.starts_at, endsAt: row.ends_at };
}
export async function refreshChallenges(userId, db = pool, now = new Date()) {
  const result = await db.query("SELECT * FROM challenges WHERE user_id = $1 AND status = 'active'", [userId]);
  for (const challenge of result.rows) {
    const count = await db.query(`SELECT COUNT(*)::int AS answered,
      COUNT(*) FILTER (WHERE correct = true)::int AS correct,
      COUNT(correct)::int AS graded FROM study_logs WHERE user_id = $1 AND created_at >= $2 AND created_at < $3
      AND ($4 = 'weekly' OR challenge_id = $5)`,
      [userId, challenge.starts_at, challenge.ends_at, challenge.kind, challenge.id]);
    const stats = count.rows[0];
    const complete = stats.answered >= challenge.target_count;
    const status = complete ? 'completed' : now >= challenge.ends_at ? 'expired' : 'active';
    const score = stats.graded ? Math.round(stats.correct * 100 / stats.graded) : 0;
    await db.query(`UPDATE challenges SET answered = $2, score_percent = $3, success = $4, status = $5,
      completed_at = CASE WHEN $4 THEN COALESCE(completed_at, $6) ELSE completed_at END WHERE id = $1`,
      [challenge.id, stats.answered, score, complete, status, now]);
    if (complete) await createNotification(db, userId, { title: 'Desafio concluído',
      body: `Você concluiu ${challenge.title}!`, sourceKey: `challenge:${challenge.id}:completed` });
  }
}
