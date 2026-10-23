import { Router } from 'express';
import { pool } from '../db.js';
import { dateKey, addDays, weekKey, userTimeZone } from '../services/calendar.js';
const router = Router();
router.get('/', async (req, res, next) => {
  try {
    const zone = await userTimeZone(pool, req.userId);
    const logs = (await pool.query('SELECT correct, created_at, duration_seconds FROM study_logs WHERE user_id = $1 ORDER BY created_at', [req.userId])).rows;
    const today = dateKey(new Date(), zone), monday = weekKey(new Date(), zone);
    const dates = new Set(logs.map(log => dateKey(log.created_at, zone)));
    const todayLogs = logs.filter(log => dateKey(log.created_at, zone) === today);
    const recent = logs.filter(log => dateKey(log.created_at, zone) >= addDays(today, -6) && log.correct !== null);
    let streakDays = 0, date = dates.has(today) ? today : addDays(today, -1);
    while (dates.has(date)) { streakDays++; date = addDays(date, -1); }
    const totalXp = logs.length * 10;
    res.json({ streakDays, level: Math.floor(totalXp / 200) + 1, totalXp, xpToNextLevel: 200 - totalXp % 200,
      weeklyAccuracy: recent.length ? recent.filter(log => log.correct).length / recent.length : 0,
      minutesStudiedToday: Math.round(todayLogs.reduce((sum, log) => sum + log.duration_seconds, 0) / 60),
      reviewedToday: todayLogs.length, weekProgress: Array.from({ length: 7 }, (_, i) => dates.has(addDays(monday, i))) });
  } catch (error) { next(error); }
});
router.get('/history', async (req, res, next) => {
  const offset = Math.max(0, Number.parseInt(req.query.offset, 10) || 0);
  try {
    const result = await pool.query(`SELECT id, deck_name AS "deckName", card_front AS "cardFront", correct,
      duration_seconds AS "durationSeconds", created_at AS "createdAt" FROM study_logs WHERE user_id = $1
      ORDER BY created_at DESC, id DESC LIMIT 50 OFFSET $2`, [req.userId, offset]);
    res.json(result.rows);
  } catch (error) { next(error); }
});
router.delete('/', async (req, res, next) => {
  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    await client.query('DELETE FROM study_logs WHERE user_id = $1', [req.userId]);
    await client.query("UPDATE flashcards SET status = 'novo' WHERE deck_id IN (SELECT id FROM decks WHERE user_id = $1)", [req.userId]);
    await client.query("UPDATE challenges SET status = 'cancelled' WHERE user_id = $1 AND status = 'active'", [req.userId]);
    await client.query('COMMIT'); res.status(204).send();
  } catch (error) { if (client) await client.query('ROLLBACK'); next(error); } finally { client?.release(); }
});
export default router;
