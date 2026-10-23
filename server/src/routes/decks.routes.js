import { refreshChallenges } from '../services/challenges.js';
import { createNotification } from '../services/notifications.js';
import { dateKey, userTimeZone } from '../services/calendar.js';
import { randomUUID } from 'node:crypto';
import { Router } from 'express';
import { pool } from '../db.js';

const router = Router();
router.use((req, res, next) => {
  const body = req.body;
  for (const key of ['name', 'front', 'back']) {
    if (body[key] !== undefined && (typeof body[key] !== 'string' || !body[key].trim()))
      return res.status(400).json({ error: 'Preencha os campos obrigatórios.' });
  }
  if (body.options != null && (!Array.isArray(body.options) || body.options.length < 2 ||
      body.options.some(option => typeof option !== 'string' || !option.trim()) ||
      !Number.isInteger(body.correctIndex) || body.correctIndex < 0 || body.correctIndex >= body.options.length))
    return res.status(400).json({ error: 'Informe as alternativas e a resposta correta.' });
  if (body.dailyGoal !== undefined && (!Number.isInteger(body.dailyGoal) || body.dailyGoal < 1))
    return res.status(400).json({ error: 'Meta diária inválida.' });
  if (body.description !== undefined && typeof body.description !== 'string')
    return res.status(400).json({ error: 'Descrição inválida.' });
  if (body.reminderTimes !== undefined && (!Array.isArray(body.reminderTimes) || body.reminderTimes.some(time => typeof time !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time))))
    return res.status(400).json({ error: 'Horários inválidos.' });
  if (body.remindersEnabled !== undefined && typeof body.remindersEnabled !== 'boolean') return res.status(400).json({ error: 'Lembrete inválido.' });
  next();
});
for (const parameter of ['id', 'deckId']) {
  router.param(parameter, async (req, res, next, id) => {
    try {
      const result = await pool.query('SELECT id FROM decks WHERE id = $1 AND user_id = $2', [id, req.userId]);
      if (!result.rows.length) return res.status(404).json({ error: 'Baralho não encontrado.' });
      next();
    } catch (error) { next(error); }
  });
}

/**
 * @openapi
 * /decks:
 *   get:
 *     summary: Listar todos os baralhos com seus cartões
 *     tags: [Baralhos]
 *     responses:
 *       200:
 *         description: Lista de baralhos
 */
router.get('/', async (req, res) => {
  try {
    const decksRes = await pool.query('SELECT * FROM decks WHERE user_id = $1 ORDER BY updated_at DESC', [req.userId]);
    const cardsRes = await pool.query('SELECT f.* FROM flashcards f JOIN decks d ON d.id = f.deck_id WHERE d.user_id = $1', [req.userId]);

    const cardsByDeck = {};
    for (const card of cardsRes.rows) {
      if (!cardsByDeck[card.deck_id]) cardsByDeck[card.deck_id] = [];
      cardsByDeck[card.deck_id].push({
        id: card.id,
        front: card.front,
        back: card.back,
        type: card.type,
        status: card.status,
      suspended: card.suspended,
        hint: card.hint,
        options: card.options,
        correctIndex: card.correct_index,
        audioSeconds: card.audio_seconds,
        aiGenerated: card.ai_generated,
        mediaCaption: card.media_caption,
      });
    }

    const decks = decksRes.rows.map(deck => ({
      id: deck.id,
      name: deck.name,
      description: deck.description,
      dailyGoal: deck.daily_goal,
      remindersEnabled: deck.reminders_enabled,
      reminderTimes: deck.reminder_times,
      updatedAt: deck.updated_at,
      cards: cardsByDeck[deck.id] || [],
    }));

    return res.json(decks);
  } catch (err) {
    console.error('Erro ao buscar baralhos:', err);
    return res.status(500).json({ error: 'Erro ao buscar baralhos.' });
  }
});

/**
 * @openapi
 * /decks/{id}:
 *   get:
 *     summary: Obter detalhes de um baralho por ID
 *     tags: [Baralhos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Baralho encontrado
 *       404:
 *         description: Baralho não encontrado
 */
router.get('/:id', async (req, res) => {
  try {
    const deckRes = await pool.query('SELECT * FROM decks WHERE id = $1', [req.params.id]);
    if (deckRes.rows.length === 0) {
      return res.status(404).json({ error: 'Baralho não encontrado.' });
    }

    const deck = deckRes.rows[0];
    const cardsRes = await pool.query('SELECT * FROM flashcards WHERE deck_id = $1', [deck.id]);

    const cards = cardsRes.rows.map(card => ({
      id: card.id,
      front: card.front,
      back: card.back,
      type: card.type,
      status: card.status,
      suspended: card.suspended,
      hint: card.hint,
      options: card.options,
      correctIndex: card.correct_index,
      audioSeconds: card.audio_seconds,
      aiGenerated: card.ai_generated,
      mediaCaption: card.media_caption,
    }));

    return res.json({
      id: deck.id,
      name: deck.name,
      description: deck.description,
      dailyGoal: deck.daily_goal,
      remindersEnabled: deck.reminders_enabled,
      reminderTimes: deck.reminder_times,
      updatedAt: deck.updated_at,
      cards,
    });
  } catch (err) {
    console.error('Erro ao buscar baralho:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  }
});

/**
 * @openapi
 * /decks:
 *   post:
 *     summary: Criar novo baralho
 *     tags: [Baralhos]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name: { type: string }
 *               description: { type: string }
 *               dailyGoal: { type: integer }
 *               remindersEnabled: { type: boolean }
 *               reminderTimes: { type: array, items: { type: string } }
 *     responses:
 *       201:
 *         description: Baralho criado
 */
router.post('/', async (req, res) => {
  const { name, description = '', dailyGoal = 20, remindersEnabled = true, reminderTimes = ['20:00'] } = req.body;
  if (!name) return res.status(400).json({ error: 'O nome do baralho é obrigatório.' });

  const id = `deck-${randomUUID()}`;
  try {
    const result = await pool.query(
      `INSERT INTO decks (id, name, description, daily_goal, reminders_enabled, reminder_times, user_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [id, name.trim(), description.trim(), dailyGoal, remindersEnabled, JSON.stringify(reminderTimes), req.userId]
    );

    const deck = result.rows[0];
    return res.status(201).json({
      id: deck.id,
      name: deck.name,
      description: deck.description,
      dailyGoal: deck.daily_goal,
      remindersEnabled: deck.reminders_enabled,
      reminderTimes: deck.reminder_times,
      updatedAt: deck.updated_at,
      cards: [],
    });
  } catch (err) {
    console.error('Erro ao criar baralho:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  }
});

/**
 * @openapi
 * /decks/{id}:
 *   put:
 *     summary: Atualizar metadados de um baralho
 *     tags: [Baralhos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Baralho atualizado
 */
router.put('/:id', async (req, res) => {
  const { name, description, dailyGoal, remindersEnabled, reminderTimes } = req.body;

  try {
    const result = await pool.query(
      `UPDATE decks SET
         name = COALESCE($1, name),
         description = COALESCE($2, description),
         daily_goal = COALESCE($3, daily_goal),
         reminders_enabled = COALESCE($4, reminders_enabled),
         reminder_times = COALESCE($5, reminder_times),
         updated_at = CURRENT_TIMESTAMP
       WHERE id = $6 RETURNING *`,
      [
        name,
        description,
        dailyGoal,
        remindersEnabled,
        reminderTimes ? JSON.stringify(reminderTimes) : null,
        req.params.id,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Baralho não encontrado.' });
    }

    const deck = result.rows[0];
    return res.json({
      id: deck.id,
      name: deck.name,
      description: deck.description,
      dailyGoal: deck.daily_goal,
      remindersEnabled: deck.reminders_enabled,
      reminderTimes: deck.reminder_times,
      updatedAt: deck.updated_at,
    });
  } catch (err) {
    console.error('Erro ao atualizar baralho:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  }
});

/**
 * @openapi
 * /decks/{id}:
 *   delete:
 *     summary: Excluir baralho
 *     tags: [Baralhos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       204:
 *         description: Excluído com sucesso
 */
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM decks WHERE id = $1', [req.params.id]);
    return res.status(204).send();
  } catch (err) {
    console.error('Erro ao excluir baralho:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  }
});

/**
 * @openapi
 * /decks/{id}/cards:
 *   post:
 *     summary: Adicionar cartão a um baralho
 *     tags: [Cartões]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       201:
 *         description: Cartão adicionado
 */
router.post('/:id/cards', async (req, res) => {
  const {
    front,
    back,
    type = 'text',
    status = 'novo',
    hint,
    options,
    correctIndex,
    audioSeconds = 8,
    aiGenerated = false,
    mediaCaption,
  } = req.body;

  if (!front || !back) {
    return res.status(400).json({ error: 'Frente e verso do cartão são obrigatórios.' });
  }

  const cardId = `card-${randomUUID()}`;
  try {
    const result = await pool.query(
      `INSERT INTO flashcards (id, deck_id, front, back, type, status, hint, options, correct_index, audio_seconds, ai_generated, media_caption)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        cardId,
        req.params.id,
        front,
        back,
        type,
        status,
        hint || null,
        options ? JSON.stringify(options) : null,
        correctIndex ?? null,
        audioSeconds,
        aiGenerated,
        mediaCaption || null,
      ]
    );

    await pool.query('UPDATE decks SET updated_at = CURRENT_TIMESTAMP WHERE id = $1', [req.params.id]);

    const card = result.rows[0];
    return res.status(201).json({
      id: card.id,
      front: card.front,
      back: card.back,
      type: card.type,
      status: card.status,
      suspended: card.suspended,
      hint: card.hint,
      options: card.options,
      correctIndex: card.correct_index,
      audioSeconds: card.audio_seconds,
      aiGenerated: card.ai_generated,
      mediaCaption: card.media_caption,
    });
  } catch (err) {
    console.error('Erro ao adicionar cartão:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  }
});

/**
 * @openapi
 * /decks/{deckId}/cards/{cardId}:
 *   put:
 *     summary: Atualizar cartão de um baralho
 *     tags: [Cartões]
 *     responses:
 *       200:
 *         description: Cartão atualizado
 */
router.put('/:deckId/cards/:cardId', async (req, res) => {
  const { front, back, type, status, hint, options, correctIndex, audioSeconds, aiGenerated, mediaCaption, targetDeckId, suspended } = req.body;
  if (suspended !== undefined && typeof suspended !== 'boolean') return res.status(400).json({ error: 'Suspensão inválida.' });

  try {
    if (targetDeckId !== undefined) {
      const target = await pool.query('SELECT id FROM decks WHERE id = $1 AND user_id = $2', [targetDeckId, req.userId]);
      if (!target.rows.length) return res.status(404).json({ error: 'Baralho de destino não encontrado.' });
    }
    const result = await pool.query(
      `UPDATE flashcards SET
         front = COALESCE($1, front),
         back = COALESCE($2, back),
         type = COALESCE($3, type),
         status = COALESCE($4, status),
         hint = COALESCE($5, hint),
         options = CASE WHEN $13 THEN $6::jsonb ELSE options END,
         correct_index = CASE WHEN $13 THEN $7::integer ELSE correct_index END,
         audio_seconds = COALESCE($8, audio_seconds),
         ai_generated = COALESCE($9, ai_generated),
         media_caption = COALESCE($10, media_caption),
         deck_id = COALESCE($14, deck_id), suspended = COALESCE($15, suspended)
       WHERE id = $11 AND deck_id = $12 RETURNING *`,
      [
        front,
        back,
        type,
        status,
        hint,
        options ? JSON.stringify(options) : null,
        correctIndex,
        audioSeconds,
        aiGenerated,
        mediaCaption,
        req.params.cardId,
        req.params.deckId,
        Object.hasOwn(req.body, 'options'),
        targetDeckId, suspended,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Cartão não encontrado.' });
    }

    const card = result.rows[0];
    return res.json({
      id: card.id,
      front: card.front,
      back: card.back,
      type: card.type,
      status: card.status,
      suspended: card.suspended,
      hint: card.hint,
      options: card.options,
      correctIndex: card.correct_index,
      audioSeconds: card.audio_seconds,
      aiGenerated: card.ai_generated,
      mediaCaption: card.media_caption,
    });
  } catch (err) {
    console.error('Erro ao atualizar cartão:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  }
});

/**
 * @openapi
 * /decks/{deckId}/cards/{cardId}:
 *   delete:
 *     summary: Excluir cartão de um baralho
 *     tags: [Cartões]
 *     responses:
 *       204:
 *         description: Cartão excluído
 */
router.delete('/:deckId/cards/:cardId', async (req, res) => {
  try {
    await pool.query('DELETE FROM flashcards WHERE id = $1 AND deck_id = $2', [req.params.cardId, req.params.deckId]);
    return res.status(204).send();
  } catch (err) {
    console.error('Erro ao excluir cartão:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  }
});

/**
 * @openapi
 * /decks/{deckId}/cards/{cardId}/review:
 *   post:
 *     summary: Marcar revisão do cartão
 *     tags: [Cartões]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               correct: { type: boolean }
 *     responses:
 *       200:
 *         description: Status do cartão atualizado
 */
router.post('/:deckId/cards/:cardId/review', async (req, res) => {
  const { correct = null, durationSeconds = 0, challengeId = null } = req.body;
  if ((correct !== null && typeof correct !== 'boolean') || !Number.isInteger(durationSeconds) || durationSeconds < 0 || durationSeconds > 3600 || (challengeId !== null && typeof challengeId !== 'string'))
    return res.status(400).json({ error: 'Revisão inválida.' });

  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    const cardRes = await client.query('SELECT * FROM flashcards WHERE id = $1 AND deck_id = $2 FOR UPDATE', [req.params.cardId, req.params.deckId]);
    if (cardRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Cartão não encontrado.' });
    }

    if (cardRes.rows[0].suspended) { await client.query('ROLLBACK'); return res.status(409).json({ error: 'Este cartão está suspenso.' }); }
    if (challengeId) {
      const challenge = (await client.query("SELECT * FROM challenges WHERE id = $1 AND user_id = $2 AND status = 'active' AND ends_at > CURRENT_TIMESTAMP FOR UPDATE", [challengeId, req.userId])).rows[0];
      if (!challenge || (challenge.kind === 'custom' && !challenge.deck_ids.includes(req.params.deckId)) ||
          (challenge.weak_only && cardRes.rows[0].status !== 'aRevisar')) {
        await client.query('ROLLBACK'); return res.status(409).json({ error: 'Cartão ou desafio indisponível.' });
      }
    }
    const currentStatus = cardRes.rows[0].status;
    let newStatus = 'dominado';

    if (correct === false) {
      newStatus = 'aRevisar';
    } else if (currentStatus === 'novo') {
      newStatus = 'aRevisar';
    } else {
      newStatus = 'dominado';
    }

    const updated = await client.query('UPDATE flashcards SET status = $1 WHERE id = $2 RETURNING *', [newStatus, req.params.cardId]);
    const card = updated.rows[0];

    // Registrar no log de estudos para calculo do progresso real
    await client.query(
      `INSERT INTO study_logs (deck_id,card_id,correct,user_id,duration_seconds,deck_name,card_front,challenge_id)
       VALUES ($1,$2,$3,$4,$5,(SELECT name FROM decks WHERE id = $1),$6,$7)`,
      [req.params.deckId, req.params.cardId, correct, req.userId, durationSeconds, card.front, challengeId]
    );

    await refreshChallenges(req.userId, client);
    const zone = await userTimeZone(client, req.userId), date = dateKey(new Date(), zone);
    const stats = await client.query(`SELECT (SELECT COUNT(*) FROM study_logs WHERE user_id = $1
      AND (created_at AT TIME ZONE $3)::date = $2::date)::int AS done,
      (SELECT COALESCE(SUM(daily_goal),0) FROM decks WHERE user_id = $1)::int AS goal`, [req.userId,date,zone]);
    if (stats.rows[0].goal > 0 && stats.rows[0].done >= stats.rows[0].goal)
      await createNotification(client, req.userId, { title: 'Meta diária concluída', body: 'Você atingiu sua meta de estudo de hoje!', sourceKey: `daily-goal:${date}` });
    await client.query('COMMIT');
    return res.json({
      id: card.id,
      front: card.front,
      back: card.back,
      type: card.type,
      status: card.status,
      suspended: card.suspended,
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK');
    console.error('Erro na revisão do cartão:', err);
    return res.status(500).json({ error: 'Erro interno do servidor.' });
  } finally { client?.release(); }
});

router.post('/:id/cards/batch', async (req, res, next) => {
  const { cards } = req.body;
  if (!Array.isArray(cards) || cards.length === 0 || cards.length > 100 ||
      cards.some(card => !card || typeof card.front !== 'string' || !card.front.trim() ||
        typeof card.back !== 'string' || !card.back.trim())) {
    return res.status(400).json({ error: 'Selecione cartões válidos para salvar.' });
  }
  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    const saved = [];
    for (const card of cards) {
      const result = await client.query(
        `INSERT INTO flashcards (id, deck_id, front, back, type, ai_generated, audio_seconds, media_caption)
         VALUES ($1, $2, $3, $4, $5, true, $6, $7)
         RETURNING id, front, back, type, status, ai_generated AS "aiGenerated",
                   audio_seconds AS "audioSeconds", media_caption AS "mediaCaption"`,
        [`card-${randomUUID()}`, req.params.id, card.front, card.back, card.type ?? 'text',
         card.audioSeconds ?? 8, card.mediaCaption ?? null]);
      saved.push(result.rows[0]);
    }
    await client.query('UPDATE decks SET updated_at = CURRENT_TIMESTAMP WHERE id = $1', [req.params.id]);
    await client.query('COMMIT');
    res.status(201).json(saved);
  } catch (error) {
    if (client) await client.query('ROLLBACK');
    next(error);
  } finally { client?.release(); }
});

export default router;
