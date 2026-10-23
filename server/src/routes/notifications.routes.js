import { Router } from 'express';
import { pool } from '../db.js';
import { createNotification, notificationJson } from '../services/notifications.js';
const router = Router();
router.get('/', async (req, res, next) => {
  try { res.json((await pool.query('SELECT * FROM notifications WHERE user_id = $1 AND deleted_at IS NULL ORDER BY scheduled_at DESC', [req.userId])).rows.map(notificationJson)); }
  catch (error) { next(error); }
});
router.post('/', async (req, res, next) => {
  const { title, body, scheduledAt } = req.body;
  const date = scheduledAt ? new Date(scheduledAt) : new Date();
  if (typeof title !== 'string' || !title.trim() || title.length > 200 || typeof body !== 'string' || !body.trim() || body.length > 2000 || !Number.isFinite(date.getTime()))
    return res.status(400).json({ error: 'Informe título, mensagem e horário válidos.' });
  try { res.status(201).json(notificationJson(await createNotification(pool, req.userId, { title: title.trim(), body: body.trim(), scheduledAt: date }))); }
  catch (error) { next(error); }
});
router.put('/read-all', async (req, res, next) => {
  try { await pool.query('UPDATE notifications SET unread = false WHERE user_id = $1 AND deleted_at IS NULL AND scheduled_at <= CURRENT_TIMESTAMP', [req.userId]); res.json({ success: true }); }
  catch (error) { next(error); }
});
router.post('/devices', async (req, res, next) => {
  const { token, platform = 'unknown' } = req.body;
  if (typeof token !== 'string' || !token || token.length > 4096 || !['android','ios','unknown'].includes(platform)) return res.status(400).json({ error: 'Dispositivo inválido.' });
  try { await pool.query('INSERT INTO push_devices (user_id,token,platform) VALUES ($1,$2,$3) ON CONFLICT (user_id,token) DO UPDATE SET platform = $3', [req.userId,token,platform]); res.status(204).send(); }
  catch (error) { next(error); }
});
router.put('/:id', async (req, res, next) => {
  const { title, body, unread, scheduledAt, retryPush } = req.body;
  if ((title !== undefined && (typeof title !== 'string' || !title.trim())) ||
      (body !== undefined && (typeof body !== 'string' || !body.trim())) ||
      (unread !== undefined && typeof unread !== 'boolean') ||
      (scheduledAt !== undefined && !Number.isFinite(new Date(scheduledAt).getTime()))) return res.status(400).json({ error: 'Dados inválidos.' });
  try {
    const result = await pool.query(`UPDATE notifications SET title = COALESCE($3,title), body = COALESCE($4,body), unread = COALESCE($5,unread),
      scheduled_at = COALESCE($6,scheduled_at), delivered_at = CASE WHEN $6::timestamptz IS NOT NULL THEN NULL ELSE delivered_at END,
      push_status = CASE WHEN $7 OR $6::timestamptz IS NOT NULL THEN 'pending' ELSE push_status END,
      push_attempts = CASE WHEN $7 OR $6::timestamptz IS NOT NULL THEN 0 ELSE push_attempts END, push_retry_at = CASE WHEN $7 OR $6::timestamptz IS NOT NULL THEN NULL ELSE push_retry_at END
      WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL RETURNING *`, [req.params.id,req.userId,title?.trim(),body?.trim(),unread,scheduledAt,retryPush === true]);
    if (!result.rows.length) return res.status(404).json({ error: 'Notificação não encontrada.' });
    res.json(notificationJson(result.rows[0]));
  } catch (error) { next(error); }
});
router.delete('/:id', async (req, res, next) => {
  try { const result = await pool.query('UPDATE notifications SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL RETURNING id', [req.params.id,req.userId]); res.status(result.rows.length ? 204 : 404).send(); }
  catch (error) { next(error); }
});
export default router;
