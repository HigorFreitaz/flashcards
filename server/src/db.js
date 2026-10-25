import { AsyncLocalStorage } from 'node:async_hooks';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const connectionString = process.env.DATABASE_URL ||
  `postgres://${process.env.POSTGRES_USER || 'lume_user'}:${process.env.POSTGRES_PASSWORD || 'lume_password'}@${process.env.POSTGRES_HOST || 'localhost'}:${process.env.POSTGRES_PORT || 5432}/${process.env.POSTGRES_DB || 'lume_db'}`;

const realPool = new Pool({
  connectionString,
});

// A queued mutation and its receipt share one transaction, even when a route
// normally opens its own transaction. Route-level commits become no-ops here.
export const transactionScope = new AsyncLocalStorage();
export const pool = {
  query: (...args) => (transactionScope.getStore() ?? realPool).query(...args),
  connect: async () => transactionScope.getStore() ?? realPool.connect(),
  end: () => realPool.end(),
};
export async function syncTransaction(work) {
  const client = await realPool.connect();
  try {
    await client.query('BEGIN');
    const scoped = {
      query: (sql, ...args) => /^(BEGIN|COMMIT|ROLLBACK)$/i.test(sql.trim())
        ? Promise.resolve({ rows: [] }) : client.query(sql, ...args),
      release() {},
    };
    const result = await transactionScope.run(scoped, () => work(client));
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally { client.release(); }
}

export async function initDb() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Tabela de Usuários
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Tabela de Baralhos
    await client.query(`
      CREATE TABLE IF NOT EXISTS decks (
        id TEXT PRIMARY KEY,
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        daily_goal INT DEFAULT 20,
        reminders_enabled BOOLEAN DEFAULT true,
        reminder_times JSONB DEFAULT '["20:00"]'::jsonb,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Tabela de Cartões
    await client.query(`
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        type TEXT DEFAULT 'text',
        status TEXT DEFAULT 'novo',
        hint TEXT,
        options JSONB,
        correct_index INT,
        audio_seconds INT DEFAULT 8,
        ai_generated BOOLEAN DEFAULT false,
        media_caption TEXT
      );
    `);

    // Tabela de Registros de Estudos / Logs de Revisão
    await client.query(`
      CREATE TABLE IF NOT EXISTS study_logs (
        id SERIAL PRIMARY KEY,
        user_id TEXT,
        deck_id TEXT REFERENCES decks(id) ON DELETE CASCADE,
        card_id TEXT REFERENCES flashcards(id) ON DELETE CASCADE,
        correct BOOLEAN NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Tabela de Notificações
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        when_text TEXT NOT NULL,
        unread BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Tabela de Desafios
    await client.query(`
      CREATE TABLE IF NOT EXISTS challenges (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        week TEXT NOT NULL,
        title TEXT NOT NULL,
        detail TEXT NOT NULL,
        score_percent INT DEFAULT 0,
        success BOOLEAN DEFAULT false,
        joined BOOLEAN DEFAULT false
      );
    `);

    // Tabela de Configurações
    await client.query(`
      CREATE TABLE IF NOT EXISTS settings (
        id INT PRIMARY KEY DEFAULT 1,
        user_id TEXT,
        theme_mode TEXT DEFAULT 'light',
        biometric_lock_enabled BOOLEAN DEFAULT false
      );
    `);

    // Inserir registro inicial de configurações se vazio
    const resSettings = await client.query('SELECT COUNT(*) FROM settings');
    if (parseInt(resSettings.rows[0].count, 10) === 0) {
      await client.query(`
        INSERT INTO settings (id, theme_mode, biometric_lock_enabled)
        VALUES (1, 'light', false);
      `);
    }

    await client.query(`
      CREATE TABLE IF NOT EXISTS sessions (
        token TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        expires_at TIMESTAMPTZ NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days')
      );
      CREATE TABLE IF NOT EXISTS user_settings (
        user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        theme_mode TEXT DEFAULT 'light', biometric_lock_enabled BOOLEAN DEFAULT false
      );
    `);
    await client.query(`
      ALTER TABLE flashcards ADD COLUMN IF NOT EXISTS suspended BOOLEAN NOT NULL DEFAULT false;
      ALTER TABLE study_logs DROP CONSTRAINT IF EXISTS study_logs_deck_id_fkey;
      ALTER TABLE study_logs ADD CONSTRAINT study_logs_deck_id_fkey FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE SET NULL;
      ALTER TABLE study_logs DROP CONSTRAINT IF EXISTS study_logs_card_id_fkey;
      ALTER TABLE study_logs ADD CONSTRAINT study_logs_card_id_fkey FOREIGN KEY (card_id) REFERENCES flashcards(id) ON DELETE SET NULL;
      ALTER TABLE study_logs ALTER COLUMN correct DROP NOT NULL;
      ALTER TABLE study_logs ADD COLUMN IF NOT EXISTS duration_seconds INT NOT NULL DEFAULT 0;
      ALTER TABLE study_logs ADD COLUMN IF NOT EXISTS deck_name TEXT;
      ALTER TABLE study_logs ADD COLUMN IF NOT EXISTS card_front TEXT;
      ALTER TABLE study_logs ADD COLUMN IF NOT EXISTS challenge_id TEXT;
      UPDATE study_logs l SET deck_name = d.name FROM decks d WHERE l.deck_id = d.id AND l.deck_name IS NULL;
      UPDATE study_logs l SET card_front = f.front FROM flashcards f WHERE l.card_id = f.id AND l.card_front IS NULL;
      ALTER TABLE user_settings ADD COLUMN IF NOT EXISTS time_zone TEXT NOT NULL DEFAULT 'America/Sao_Paulo';
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'weekly';
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS target_count INT NOT NULL DEFAULT 15;
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS deck_ids JSONB NOT NULL DEFAULT '[]';
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS weak_only BOOLEAN NOT NULL DEFAULT false;
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS answered INT NOT NULL DEFAULT 0;
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS ends_at TIMESTAMPTZ NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days');
      ALTER TABLE challenges ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
      ALTER TABLE notifications ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE notifications ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
      ALTER TABLE notifications ADD COLUMN IF NOT EXISTS push_status TEXT NOT NULL DEFAULT 'pending';
      ALTER TABLE notifications ADD COLUMN IF NOT EXISTS push_attempts INT NOT NULL DEFAULT 0;
      ALTER TABLE notifications ADD COLUMN IF NOT EXISTS push_retry_at TIMESTAMPTZ;
      ALTER TABLE notifications ADD COLUMN IF NOT EXISTS source_key TEXT;
      ALTER TABLE notifications ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
      CREATE UNIQUE INDEX IF NOT EXISTS notification_source_key ON notifications(user_id, source_key);
      CREATE INDEX IF NOT EXISTS study_logs_user_date ON study_logs(user_id, created_at);
      CREATE TABLE IF NOT EXISTS password_resets (
        token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        expires_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS push_devices (
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token TEXT NOT NULL, platform TEXT NOT NULL DEFAULT 'unknown', PRIMARY KEY (user_id, token)
      );
    `);
    await client.query(`CREATE TABLE IF NOT EXISTS sync_receipts (
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      operation_id TEXT NOT NULL, fingerprint TEXT NOT NULL,
      status INTEGER NOT NULL, response JSONB,
      created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, operation_id)
    )`);
    await client.query('COMMIT');
    console.log('✅ Banco de dados PostgreSQL inicializado sem dados mockados (Production-Ready).');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erro ao inicializar banco de dados PostgreSQL:', err);
    throw err;
  } finally {
    client.release();
  }
}
