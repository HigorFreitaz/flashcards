import { randomUUID } from 'node:crypto';
import { pool } from '../db.js';
import { dateKey, defaultTimeZone } from './calendar.js';
import { deliverPush } from './push_delivery.js';

export async function createNotification(db, userId, { title, body, scheduledAt = new Date(), sourceKey = null }) {
  const result = await db.query(`INSERT INTO notifications (id, user_id, title, body, when_text, scheduled_at, source_key)
    VALUES ($1,$2,$3,$4,'agora',$5,$6) ON CONFLICT (user_id, source_key) DO NOTHING RETURNING *`,
    [randomUUID(), userId, title, body, scheduledAt, sourceKey]);
  return result.rows[0];
}
export function notificationJson(row) {
  return { id: row.id, title: row.title, body: row.body, unread: row.unread,
    when: row.created_at.toISOString(), createdAt: row.created_at, scheduledAt: row.scheduled_at,
    deliveredAt: row.delivered_at, pushStatus: row.push_status };
}
let running = false;
export async function processNotifications(now = new Date()) {
  if (running) return; running = true;
  try {
    const decks = await pool.query(`SELECT d.*, COALESCE(s.time_zone, $1) AS time_zone FROM decks d
      LEFT JOIN user_settings s ON s.user_id = d.user_id WHERE d.user_id IS NOT NULL AND reminders_enabled = true`, [defaultTimeZone]);
    for (const deck of decks.rows) {
      const date = dateKey(now, deck.time_zone);
      const time = new Intl.DateTimeFormat('en-GB', { timeZone: deck.time_zone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(now);
      for (const reminder of deck.reminder_times) {
        if (reminder <= time) await createNotification(pool, deck.user_id, {
          title: 'Hora de estudar', body: `Revise seu baralho ${deck.name}.`, scheduledAt: now,
          sourceKey: `reminder:${deck.id}:${date}:${reminder}`,
        });
      }
    }
    await pool.query('UPDATE notifications SET delivered_at = $1 WHERE scheduled_at <= $1 AND delivered_at IS NULL AND deleted_at IS NULL', [now]);
    if (!process.env.PUSH_WEBHOOK_URL) return;
    const pending = await pool.query(`SELECT * FROM notifications WHERE delivered_at IS NOT NULL AND deleted_at IS NULL
      AND push_status = 'pending' AND (push_retry_at IS NULL OR push_retry_at <= $1) ORDER BY scheduled_at LIMIT 50`, [now]);
    for (const item of pending.rows) {
      try {
        const devices = await pool.query('SELECT token, platform FROM push_devices WHERE user_id = $1', [item.user_id]);
        if (await deliverPush(item, devices.rows)) await pool.query("UPDATE notifications SET push_status = 'sent' WHERE id = $1", [item.id]);
      } catch {
        await pool.query(`UPDATE notifications SET push_attempts = push_attempts + 1,
          push_status = CASE WHEN push_attempts >= 4 THEN 'failed' ELSE 'pending' END,
          push_retry_at = $2 WHERE id = $1`, [item.id, new Date(now.getTime() + 60000 * 2 ** item.push_attempts)]);
      }
    }
  } finally { running = false; }
}
