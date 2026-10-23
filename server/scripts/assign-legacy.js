// Explicit, preview-first assignment; never guess the owner of old shared data.
// node scripts/assign-legacy.js <account-email> [--apply]
import { pool } from '../src/db.js';
const email = process.argv[2];
if (!email || email.startsWith('--')) throw new Error('Provide the account email to receive legacy data.');
const client = await pool.connect();
try {
  await client.query('BEGIN');
  const users = await client.query('SELECT id, email FROM users WHERE lower(email) = lower($1)', [email]);
  if (users.rows.length !== 1) throw new Error('The account must resolve to exactly one existing user.');
  const user = users.rows[0];
  for (const table of ['decks','study_logs','notifications','challenges']) {
    const count = await client.query(`SELECT COUNT(*)::int AS count FROM ${table} WHERE user_id IS NULL`);
    console.log(`${table}: ${count.rows[0].count} unassigned records -> ${user.email}`);
    if (process.argv.includes('--apply')) await client.query(`UPDATE ${table} SET user_id = $1 WHERE user_id IS NULL`, [user.id]);
  }
  await client.query(process.argv.includes('--apply') ? 'COMMIT' : 'ROLLBACK');
  console.log(process.argv.includes('--apply') ? 'Assignment complete.' : 'Preview only. Add --apply to assign these records.');
} catch (error) { await client.query('ROLLBACK'); throw error; }
finally { client.release(); await pool.end(); }
