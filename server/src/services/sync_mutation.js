import { createHash } from 'node:crypto';
import { syncTransaction } from '../db.js';

// Receipts make retrying a timed-out write safe: the mutation and receipt
// either commit together or both roll back. No session token is stored here.
export async function syncMutation(req, res, next) {
  const key = req.get('Idempotency-Key');
  if (!key || req.method === 'GET') return next();
  if (!/^[a-f0-9]{32}$/.test(key) || !['POST', 'PUT', 'DELETE'].includes(req.method))
    return res.status(400).json({ error: 'Operação de sincronização inválida.' });
  const segment = '[A-Za-z0-9_-]+';
  const allowed = req.method === 'POST'
    ? new RegExp(`^/(?:${segment}/cards(?:/batch|/${segment}/review)?)?/?$`)
    : new RegExp(`^/${segment}(?:/cards/${segment})?/?$`);
  if (!allowed.test(req.path)) return res.status(400).json({ error: 'Rota de sincronização inválida.' });
  const creating = req.method === 'POST' && !req.path.endsWith('/review');
  const ids = req.path.endsWith('/batch')
    ? (Array.isArray(req.body.cards) ? req.body.cards.map(c => c?.id) : [])
    : [req.body.id];
  if (creating && (!ids?.length || ids.some(id => !/^local-[a-f0-9]{32}$/.test(id))))
    return res.status(400).json({ error: 'Identificador local inválido.' });
  if (req.path.endsWith('/review') && (!Number.isFinite(Date.parse(req.body.reviewedAt)) ||
      Date.parse(req.body.reviewedAt) > Date.now() + 300000))
    return res.status(400).json({ error: 'Data da revisão inválida.' });
  const fingerprint = createHash('sha256').update(JSON.stringify([req.method, req.originalUrl, req.body])).digest('hex');
  const originalJson = res.json.bind(res), originalSend = res.send.bind(res);
  try {
    const result = await syncTransaction(async client => {
      await client.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [req.userId]);
      const previous = (await client.query('SELECT * FROM sync_receipts WHERE user_id=$1 AND operation_id=$2', [req.userId, key])).rows[0];
      if (previous) {
        if (previous.fingerprint !== fingerprint) throw Object.assign(new Error('Identificador reutilizado com outro conteúdo.'), { status: 409 });
        return { status: previous.status, body: previous.response };
      }
      req.syncOperation = true;
      const response = await new Promise(resolve => {
        res.json = body => { resolve({ status: res.statusCode, body }); return res; };
        res.send = body => { resolve({ status: res.statusCode, body: body ?? null }); return res; };
        next();
      });
      if (response.status >= 400) throw Object.assign(new Error(response.body?.error ?? 'Falha ao sincronizar.'), { status: response.status });
      await client.query('INSERT INTO sync_receipts(user_id,operation_id,fingerprint,status,response) VALUES($1,$2,$3,$4,$5)',
        [req.userId, key, fingerprint, response.status, JSON.stringify(response.body)]);
      return response;
    });
    res.json = originalJson; res.send = originalSend;
    res.status(result.status);
    if (result.status === 204) return res.send();
    return res.json(result.body);
  } catch (error) {
    res.json = originalJson; res.send = originalSend;
    return res.status(error.status ?? 500).json({ error: error.status ? error.message : 'Falha ao sincronizar. Tente novamente.' });
  }
}
