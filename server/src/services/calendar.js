export const defaultTimeZone = 'America/Sao_Paulo';
export function validTimeZone(value) {
  try { new Intl.DateTimeFormat('en', { timeZone: value }).format(); return typeof value === 'string'; }
  catch { return false; }
}
export function dateKey(date, timeZone = defaultTimeZone) {
  return new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(date);
}
export function addDays(key, days) {
  const date = new Date(`${key}T12:00:00Z`); date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}
export function weekKey(now, zone) {
  const key = dateKey(now, zone);
  return addDays(key, -((new Date(`${key}T12:00:00Z`).getUTCDay() + 6) % 7));
}
export async function userTimeZone(db, userId) {
  const result = await db.query('SELECT time_zone FROM user_settings WHERE user_id = $1', [userId]);
  return result.rows[0]?.time_zone ?? defaultTimeZone;
}
