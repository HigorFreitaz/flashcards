import { randomBytes } from 'node:crypto';
import { pool } from './db.js';
export async function createSession(userId) {
  const token = randomBytes(32).toString('hex');
  await pool.query('INSERT INTO sessions (token, user_id) VALUES ($1, $2)', [token, userId]);
  return token;
}
export async function requireAuth(req, res, next) {
  const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return res.status(401).json({ error: 'Entre na sua conta para continuar.' });
  try {
    const result = await pool.query('SELECT user_id FROM sessions WHERE token = $1 AND expires_at > CURRENT_TIMESTAMP', [token]);
    if (!result.rows.length) return res.status(401).json({ error: 'Sessão expirada. Entre novamente.' });
    req.userId = result.rows[0].user_id;
    req.token = token;
    next();
  } catch (error) { next(error); }
}
