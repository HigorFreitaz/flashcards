import { Router } from 'express';
import { randomUUID } from 'node:crypto';
import { pool } from '../db.js';
import { refreshChallenges, challengeJson } from '../services/challenges.js';
import { weekKey, userTimeZone } from '../services/calendar.js';
const router = Router();
async function validBody(body, userId) {
  if (typeof body.title !== 'string' || !body.title.trim() || !Number.isInteger(body.targetCount) || body.targetCount < 1 || body.targetCount > 1000 ||
      !Array.isArray(body.deckIds) || !body.deckIds.length || body.deckIds.some(id => typeof id !== 'string') ||
      !Number.isInteger(body.durationDays) || body.durationDays < 1 || body.durationDays > 365 || typeof body.weakOnly !== 'boolean') return false;
  const ids = [...new Set(body.deckIds)];
  const result = await pool.query('SELECT id FROM decks WHERE user_id = $1 AND id = ANY($2::text[])', [userId, ids]);
  return result.rows.length === ids.length;
}
router.get('/', async (req, res, next) => {
  try {
    await refreshChallenges(req.userId);
    const zone = await userTimeZone(pool, req.userId), week = weekKey(new Date(), zone);
    const rows = (await pool.query('SELECT * FROM challenges WHERE user_id = $1 ORDER BY starts_at DESC', [req.userId])).rows;
    const count = await pool.query(`SELECT COUNT(*)::int AS count FROM study_logs WHERE user_id = $1
      AND created_at >= ($2::date::timestamp AT TIME ZONE $3)`, [req.userId, week, zone]);
    res.json({ joined: rows.some(row => row.kind === 'weekly' && row.week === week && row.status !== 'cancelled'),
      weeklyAnswered: count.rows[0].count, history: rows.map(challengeJson) });
  } catch (error) { next(error); }
});
router.post('/join', async (req, res, next) => {
  try {
    const zone = await userTimeZone(pool, req.userId), week = weekKey(new Date(), zone);
    const result = await pool.query(`INSERT INTO challenges (id, user_id, week, title, detail, joined, starts_at, ends_at)
      VALUES ($1,$2,$3::text,'Mestre dos Flashcards','Revise 15 cartões nesta semana.',true,
      ($3::text::date::timestamp AT TIME ZONE $4), (($3::text::date + 7)::timestamp AT TIME ZONE $4))
      ON CONFLICT (id) DO UPDATE SET joined = true, status = CASE WHEN challenges.status = 'cancelled' THEN 'active' ELSE challenges.status END RETURNING *`,
      [`weekly:${req.userId}:${week}`, req.userId, week, zone]);
    await refreshChallenges(req.userId);
    res.json({ joined: true, challenge: challengeJson(result.rows[0]) });
  } catch (error) { next(error); }
});
router.post('/', async (req, res, next) => {
  try {
    if (!await validBody(req.body, req.userId)) return res.status(400).json({ error: 'Informe título, baralhos, meta e prazo válidos.' });
    const b = req.body;
    const result = await pool.query(`INSERT INTO challenges (id,user_id,week,title,detail,joined,kind,target_count,deck_ids,weak_only,ends_at)
      VALUES ($1,$2,'Personalizado',$3,$4,true,'custom',$5,$6,$7,CURRENT_TIMESTAMP + $8 * INTERVAL '1 day') RETURNING *`,
      [randomUUID(), req.userId, b.title.trim(), `Revise ${b.targetCount} cartões.`, b.targetCount, JSON.stringify([...new Set(b.deckIds)]), b.weakOnly, b.durationDays]);
    res.status(201).json(challengeJson(result.rows[0]));
  } catch (error) { next(error); }
});
router.put('/:id', async (req, res, next) => {
  try {
    await refreshChallenges(req.userId);
    const old = (await pool.query('SELECT * FROM challenges WHERE id = $1 AND user_id = $2', [req.params.id, req.userId])).rows[0];
    if (!old) return res.status(404).json({ error: 'Desafio não encontrado.' });
    if (req.body.status === 'cancelled') {
      if (old.status !== 'active') return res.status(409).json({ error: 'Este desafio já foi encerrado.' });
      const result = await pool.query("UPDATE challenges SET status = 'cancelled' WHERE id = $1 RETURNING *", [old.id]);
      return res.json(challengeJson(result.rows[0]));
    }
    if (old.kind !== 'custom' || old.status !== 'active') return res.status(409).json({ error: 'Só desafios personalizados ativos podem ser editados.' });
    if (!await validBody(req.body, req.userId)) return res.status(400).json({ error: 'Dados inválidos.' });
    const b = req.body;
    await pool.query(`UPDATE challenges SET title = $2, target_count = $3, detail = $4, deck_ids = $5, weak_only = $6,
      ends_at = CURRENT_TIMESTAMP + $7 * INTERVAL '1 day' WHERE id = $1`,
      [old.id, b.title.trim(), b.targetCount, `Revise ${b.targetCount} cartões.`, JSON.stringify(b.deckIds), b.weakOnly, b.durationDays]);
    await refreshChallenges(req.userId);
    res.json(challengeJson((await pool.query('SELECT * FROM challenges WHERE id = $1', [old.id])).rows[0]));
  } catch (error) { next(error); }
});
router.delete('/:id', async (req, res, next) => {
  try {
    const result = await pool.query('DELETE FROM challenges WHERE id = $1 AND user_id = $2 RETURNING id', [req.params.id, req.userId]);
    res.status(result.rows.length ? 204 : 404).send();
  } catch (error) { next(error); }
});
export default router;
