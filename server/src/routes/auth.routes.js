import { randomUUID, randomBytes, createHash } from 'node:crypto';
import { createSession, requireAuth } from '../auth.js';
import { Router } from 'express';
import { pool } from '../db.js';
import { sendResetEmail } from '../services/email_delivery.js';
const router = Router();
const emailValid = value => typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
const passwordValid = value => typeof value === 'string' && value.trim().length >= 8;
const publicUser = row => ({ id: row.id, name: row.name, email: row.email });
const hash = token => createHash('sha256').update(token).digest('hex');

router.post('/login', async (req, res, next) => {
  const { email, password } = req.body;
  if (typeof email !== 'string' || typeof password !== 'string') return res.status(400).json({ error: 'Informe e-mail e senha.' });
  try {
    const result = await pool.query('SELECT * FROM users WHERE lower(email) = lower($1) AND password = $2', [email.trim(), password.trim()]);
    if (!result.rows.length) return res.status(401).json({ error: 'Credenciais inválidas.' });
    const user = result.rows[0];
    res.json({ user: publicUser(user), token: await createSession(user.id) });
  } catch (error) { next(error); }
});
router.post('/signup', async (req, res, next) => {
  const { name, email, password } = req.body;
  if (typeof name !== 'string' || !name.trim() || !emailValid(email) || !passwordValid(password))
    return res.status(400).json({ error: 'Informe nome, e-mail válido e senha com pelo menos 8 caracteres.' });
  try {
    const exists = await pool.query('SELECT id FROM users WHERE lower(email) = lower($1)', [email.trim()]);
    if (exists.rows.length) return res.status(409).json({ error: 'Este e-mail já está cadastrado.' });
    const result = await pool.query('INSERT INTO users (id, name, email, password) VALUES ($1,$2,$3,$4) RETURNING *',
      [`user-${randomUUID()}`, name.trim(), email.trim().toLowerCase(), password.trim()]);
    const user = result.rows[0];
    res.status(201).json({ user: publicUser(user), token: await createSession(user.id) });
  } catch (error) {
    if (error.code === '23505') return res.status(409).json({ error: 'Este e-mail já está cadastrado.' });
    next(error);
  }
});
router.get('/me', requireAuth, async (req, res, next) => {
  try { const result = await pool.query('SELECT id, name, email FROM users WHERE id = $1', [req.userId]); res.json({ user: result.rows[0] }); }
  catch (error) { next(error); }
});
router.put('/profile', requireAuth, async (req, res, next) => {
  const { name, email, password } = req.body;
  if ((name != null && (typeof name !== 'string' || !name.trim())) || (email != null && !emailValid(email)) ||
      (password != null && !passwordValid(password))) return res.status(400).json({ error: 'Verifique nome, e-mail e senha (mínimo 8 caracteres).' });
  try {
    if (email) {
      const exists = await pool.query('SELECT id FROM users WHERE lower(email) = lower($1) AND id <> $2', [email.trim(), req.userId]);
      if (exists.rows.length) return res.status(409).json({ error: 'Este e-mail já está cadastrado.' });
    }
    const result = await pool.query(`UPDATE users SET name = COALESCE($2, name), email = COALESCE($3, email),
      password = COALESCE($4, password) WHERE id = $1 RETURNING id, name, email`,
      [req.userId, name?.trim(), email?.trim().toLowerCase(), password?.trim()]);
    res.json({ user: result.rows[0] });
  } catch (error) {
    if (error.code === '23505') return res.status(409).json({ error: 'Este e-mail já está cadastrado.' });
    next(error);
  }
});
router.post('/forgot-password', async (req, res, next) => {
  if (!emailValid(req.body.email)) return res.status(400).json({ error: 'Informe um e-mail válido.' });
  if (!process.env.EMAIL_WEBHOOK_URL) return res.status(503).json({ error: 'Recuperação por e-mail ainda não configurada.' });
  try {
    const result = await pool.query('SELECT id, email FROM users WHERE lower(email) = lower($1)', [req.body.email.trim()]);
    if (result.rows.length) {
      const user = result.rows[0];
      const recent = await pool.query("SELECT 1 FROM password_resets WHERE user_id = $1 AND created_at > CURRENT_TIMESTAMP - INTERVAL '1 minute'", [user.id]);
      if (!recent.rows.length) {
        const token = randomBytes(24).toString('hex');
        await pool.query("INSERT INTO password_resets (token_hash, user_id, expires_at) VALUES ($1,$2,CURRENT_TIMESTAMP + INTERVAL '30 minutes')", [hash(token), user.id]);
        try { await sendResetEmail(user.email, token); }
        catch (error) { await pool.query('DELETE FROM password_resets WHERE token_hash = $1', [hash(token)]); throw error; }
      }
    }
    res.json({ message: 'Se o e-mail estiver cadastrado, você receberá um código de recuperação.' });
  } catch (error) { next(error); }
});
router.post('/reset-password', async (req, res, next) => {
  const { token, password } = req.body;
  if (typeof token !== 'string' || !passwordValid(password)) return res.status(400).json({ error: 'Informe o código e uma senha com pelo menos 8 caracteres.' });
  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    const result = await client.query('DELETE FROM password_resets WHERE token_hash = $1 AND expires_at > CURRENT_TIMESTAMP RETURNING user_id', [hash(token.trim())]);
    if (!result.rows.length) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'Código inválido ou expirado.' }); }
    const id = result.rows[0].user_id;
    await client.query('UPDATE users SET password = $2 WHERE id = $1', [id, password.trim()]);
    await client.query('DELETE FROM sessions WHERE user_id = $1', [id]);
    await client.query('DELETE FROM password_resets WHERE user_id = $1', [id]);
    await client.query('COMMIT'); res.json({ success: true });
  } catch (error) { if (client) await client.query('ROLLBACK'); next(error); } finally { client?.release(); }
});
router.post('/logout', requireAuth, async (req, res, next) => {
  try { await pool.query('DELETE FROM sessions WHERE token = $1', [req.token]); res.status(204).send(); }
  catch (error) { next(error); }
});
router.delete('/account', requireAuth, async (req, res, next) => {
  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    for (const table of ['study_logs', 'notifications', 'challenges', 'settings']) await client.query(`DELETE FROM ${table} WHERE user_id = $1`, [req.userId]);
    await client.query('DELETE FROM users WHERE id = $1', [req.userId]);
    await client.query('COMMIT'); res.status(204).send();
  } catch (error) { if (client) await client.query('ROLLBACK'); next(error); } finally { client?.release(); }
});
export default router;
