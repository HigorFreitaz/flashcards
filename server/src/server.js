import { syncMutation } from './services/sync_mutation.js';
import { processNotifications } from './services/notifications.js';
import { refreshChallenges } from './services/challenges.js';
import { pool } from './db.js';
import { pathToFileURL } from 'node:url';
import { requireAuth } from './auth.js';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import swaggerUi from 'swagger-ui-express';

import { initDb } from './db.js';
import { swaggerSpec } from './swagger.js';

import authRoutes from './routes/auth.routes.js';
import decksRoutes from './routes/decks.routes.js';
import progressRoutes from './routes/progress.routes.js';
import challengesRoutes from './routes/challenges.routes.js';
import notificationsRoutes from './routes/notifications.routes.js';
import settingsRoutes from './routes/settings.routes.js';

dotenv.config();

const errorStatus = err => Number.isInteger(err.status) && err.status >= 400 && err.status < 600 ? err.status : 500;
export const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Middleware de Log das Requisições
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} - IP: ${req.ip}`);
  next();
});

// Documentação Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Rotas da API REST
app.use('/api/auth', authRoutes);
app.use('/api/decks', requireAuth, syncMutation, decksRoutes);
app.use('/api/progress', requireAuth, progressRoutes);
app.use('/api/challenges', requireAuth, challengesRoutes);
app.use('/api/notifications', requireAuth, notificationsRoutes);
app.use('/api/settings', requireAuth, settingsRoutes);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(errorStatus(err)).json({ error: err.status ? err.message : 'Erro interno do servidor.' });
});

// Healthcheck
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

async function startServer() {
  try {
    await initDb();
    let ticking = false;
    const tick = async () => {
      if (ticking) return; ticking = true;
      try {
        const users = await pool.query("SELECT DISTINCT user_id FROM challenges WHERE status = 'active' AND user_id IS NOT NULL");
        for (const user of users.rows) await refreshChallenges(user.user_id);
        await processNotifications();
      } catch (error) { console.error('Scheduler:', error.message); }
      finally { ticking = false; }
    };
    void tick();
    setInterval(tick, 60000).unref();
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Servidor Lume API rodando na porta ${PORT} (0.0.0.0)`);
      console.log(`📖 Documentação Swagger disponível em: http://localhost:${PORT}/api-docs`);
    });
  } catch (err) {
    console.error('💥 Falha crítica ao iniciar o servidor:', err);
    process.exit(1);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) startServer();
