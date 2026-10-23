import { Router } from 'express';
import { pool } from '../db.js';
import { validTimeZone, defaultTimeZone } from '../services/calendar.js';
const router = Router();
const json = row => ({ themeMode: row?.theme_mode ?? 'light', biometricLockEnabled: row?.biometric_lock_enabled ?? false, timeZone: row?.time_zone ?? defaultTimeZone });
router.get('/', async (req, res, next) => {
  try { res.json(json((await pool.query('SELECT * FROM user_settings WHERE user_id = $1', [req.userId])).rows[0])); }
  catch (error) { next(error); }
});
router.put('/', async (req, res, next) => {
  const { themeMode, biometricLockEnabled, timeZone } = req.body;
  if ((themeMode !== undefined && !['light','dark','system'].includes(themeMode)) ||
      (biometricLockEnabled !== undefined && typeof biometricLockEnabled !== 'boolean') ||
      (timeZone !== undefined && !validTimeZone(timeZone))) return res.status(400).json({ error: 'Configurações inválidas.' });
  try {
    const result = await pool.query(`INSERT INTO user_settings (user_id, theme_mode, biometric_lock_enabled, time_zone)
      VALUES ($1,COALESCE($2,'light'),COALESCE($3,false),COALESCE($4,$5)) ON CONFLICT (user_id) DO UPDATE SET
      theme_mode = COALESCE($2,user_settings.theme_mode), biometric_lock_enabled = COALESCE($3,user_settings.biometric_lock_enabled),
      time_zone = COALESCE($4,user_settings.time_zone) RETURNING *`, [req.userId, themeMode, biometricLockEnabled, timeZone, defaultTimeZone]);
    res.json(json(result.rows[0]));
  } catch (error) { next(error); }
});
router.delete('/', async (req, res, next) => {
  try { await pool.query('DELETE FROM user_settings WHERE user_id = $1', [req.userId]); res.json(json()); }
  catch (error) { next(error); }
});
export default router;
