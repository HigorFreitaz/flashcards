import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';

// Deliberately require an explicitly selected test database.
const url = process.env.TEST_DATABASE_URL;
if (!url || !new URL(url).pathname.endsWith('_test')) {
  throw new Error('Set TEST_DATABASE_URL to a dedicated database whose name ends in _test.');
}
process.env.DATABASE_URL = url;
const { pool, initDb } = await import('../src/db.js');
const { app } = await import('../src/server.js');
const { processNotifications } = await import('../src/services/notifications.js');
const { dateKey, weekKey } = await import('../src/services/calendar.js');
const { refreshChallenges } = await import('../src/services/challenges.js');
let server, base;
const accounts = [];
before(async () => {
  await initDb();
  await initDb(); // Startup must also work with an existing schema.
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}/api`;
});
after(async () => {
  for (const user of accounts) {
    for (const table of ['study_logs','notifications','challenges']) await pool.query(`DELETE FROM ${table} WHERE user_id = $1`, [user.id]);
    await pool.query('DELETE FROM users WHERE id = $1', [user.id]);
  }
  if (server) await new Promise(resolve => server.close(resolve));
  await pool.end();
});
async function request(path, { token, method = 'GET', body } = {}) {
  const response = await fetch(base + path, {
    method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  return { status: response.status, body: text ? JSON.parse(text) : null };
}
async function signup(name) {
  const email = `${randomUUID()}@test.local`;
  const result = await request('/auth/signup', { method: 'POST', body: { name, email, password: 'password123' } });
  assert.equal(result.status, 201);
  accounts.push(result.body.user);
  return { ...result.body.user, token: result.body.token };
}

test('basic account, deck, card, review and deletion flows stay isolated', async () => {
  const alice = await signup('Alice'), bob = await signup('Bob');
  for (const path of ['/decks', '/progress', '/settings', '/challenges', '/notifications']) {
    assert.equal((await request(path)).status, 401);
    assert.equal((await request(path, { token: `token-${alice.id}` })).status, 401);
  }
  const login = await request('/auth/login', { method: 'POST', body: { email: alice.email, password: 'password123' } });
  assert.equal(login.status, 200);
  assert.notEqual(login.body.token, alice.token);
  const deck = await request('/decks', { token: alice.token, method: 'POST', body: { name: 'Biology', dailyGoal: 5 } });
  assert.equal(deck.status, 201);
  const id = deck.body.id;
  assert.equal((await request('/decks', { token: bob.token })).body.length, 0);
  for (const method of ['GET', 'PUT', 'DELETE']) {
    assert.equal((await request(`/decks/${id}`, { token: bob.token, method, body: method === 'PUT' ? { name: 'Stolen' } : undefined })).status, 404);
  }
  const card = await request(`/decks/${id}/cards`, { token: alice.token, method: 'POST', body: { front: '2+2?', back: '4', options: ['3', '4'], correctIndex: 1 } });
  assert.equal(card.status, 201);
  const cardPath = `/decks/${id}/cards/${card.body.id}`;
  assert.equal((await request(cardPath + '/review', { token: bob.token, method: 'POST', body: { correct: true } })).status, 404);
  assert.equal((await request(cardPath, { token: bob.token, method: 'DELETE' })).status, 404);
  assert.equal((await request(cardPath, { token: alice.token, method: 'PUT', body: { front: 'Question', back: 'Answer', options: null, correctIndex: null } })).body.options, null);
  assert.equal((await request(cardPath + '/review', { token: alice.token, method: 'POST', body: { correct: true } })).status, 200);
  assert.equal((await request('/progress', { token: alice.token })).body.totalXp, 10);
  assert.equal((await request('/progress', { token: bob.token })).body.totalXp, 0);
  assert.equal((await request('/challenges', { token: alice.token })).body.weeklyAnswered, 1);
  assert.equal((await request('/challenges', { token: bob.token })).body.weeklyAnswered, 0);
  await request('/settings', { token: alice.token, method: 'PUT', body: { themeMode: 'dark' } });
  assert.equal((await request('/settings', { token: alice.token })).body.themeMode, 'dark');
  assert.equal((await request('/settings', { token: bob.token })).body.themeMode, 'light');
  assert.equal((await request('/challenges/join', { token: alice.token, method: 'POST', body: {} })).status, 200);
  assert.equal((await request('/challenges', { token: bob.token })).body.joined, false);
  await pool.query("INSERT INTO notifications (id, user_id, title, body, when_text) VALUES ($1, $2, 'Hello', 'Study', 'now')", [randomUUID(), alice.id]);
  assert.equal((await request('/notifications', { token: bob.token })).body.length, 0);
  await request('/notifications/read-all', { token: bob.token, method: 'PUT', body: {} });
  assert.equal((await request('/notifications', { token: alice.token })).body[0].unread, true);
  await request('/auth/profile', { token: alice.token, method: 'PUT', body: { id: bob.id, name: 'Alice Updated', password: 'newpassword123' } });
  assert.equal((await pool.query('SELECT name FROM users WHERE id = $1', [bob.id])).rows[0].name, 'Bob');
  assert.equal((await request('/auth/login', { method: 'POST', body: { email: alice.email, password: 'password123' } })).status, 401);
  assert.equal((await request('/auth/login', { method: 'POST', body: { email: alice.email, password: 'newpassword123' } })).status, 200);
  assert.equal((await request('/auth/account', { token: alice.token, method: 'DELETE' })).status, 204);
  for (const table of ['users', 'decks', 'study_logs', 'notifications', 'challenges', 'user_settings', 'sessions']) {
    const column = table === 'users' ? 'id' : 'user_id';
    assert.equal((await pool.query(`SELECT * FROM ${table} WHERE ${column} = $1`, [alice.id])).rows.length, 0);
  }
  assert.equal((await request('/decks', { token: login.body.token })).status, 401);
  assert.equal((await request('/decks', { token: bob.token })).status, 200);
  await request('/auth/logout', { token: bob.token, method: 'POST', body: {} });
  assert.equal((await request('/decks', { token: bob.token })).status, 401);
});

test('validation and ordinary card/deck deletion', async () => {
  const user = await signup('Carol');
  assert.equal((await request('/decks', { token: user.token, method: 'POST', body: { name: ' ' } })).status, 400);
  const deck = (await request('/decks', { token: user.token, method: 'POST', body: { name: 'Delete me' } })).body;
  const invalidBatch = await request(`/decks/${deck.id}/cards/batch`, { token: user.token, method: 'POST', body: { cards: [{ front: 'Q', back: 'A' }, { front: '' }] } });
  assert.equal(invalidBatch.status, 400);
  assert.equal((await request(`/decks/${deck.id}`, { token: user.token })).body.cards.length, 0);
  const batch = await request(`/decks/${deck.id}/cards/batch`, { token: user.token, method: 'POST', body: { cards: [{ front: 'Q1', back: 'A1' }, { front: 'Q2', back: 'A2' }] } });
  assert.equal(batch.status, 201);
  assert.equal(batch.body.length, 2);
  for (const card of batch.body) await request(`/decks/${deck.id}/cards/${card.id}`, { token: user.token, method: 'DELETE' });
  const card = (await request(`/decks/${deck.id}/cards`, { token: user.token, method: 'POST', body: { front: 'Q', back: 'A' } })).body;
  assert.equal((await request(`/decks/${deck.id}/cards/${card.id}`, { token: user.token, method: 'DELETE' })).status, 204);
  assert.equal((await request(`/decks/${deck.id}`, { token: user.token })).body.cards.length, 0);
  assert.equal((await request(`/decks/${deck.id}`, { token: user.token, method: 'DELETE' })).status, 204);
  assert.equal((await request('/decks', { token: user.token })).body.length, 0);
});


test('account validation, email reset adapter, single-use codes and session revocation', async () => {
  assert.equal((await request('/auth/signup', {method:'POST',body:{name:'Invalid',email:'invalid',password:'x'}})).status,400);
  const a = await signup('Reset'), b = await signup('Existing');
  assert.equal((await request('/auth/me',{token:a.token})).body.user.id,a.id);
  assert.equal((await request('/auth/profile',{token:a.token,method:'PUT',body:{email:b.email}})).status,409);
  assert.equal((await request('/auth/profile',{token:a.token,method:'PUT',body:{password:'short'}})).status,400);
  assert.equal((await request('/auth/forgot-password',{method:'POST',body:{email:a.email}})).status,503);
  const messages = [];
  const gateway = createServer(async (req,res) => { let data=''; for await (const chunk of req) data+=chunk; messages.push(JSON.parse(data)); res.writeHead(200).end(); });
  await new Promise(resolve=>gateway.listen(0,'127.0.0.1',resolve));
  process.env.EMAIL_WEBHOOK_URL = `http://127.0.0.1:${gateway.address().port}`;
  try {
    assert.equal((await request('/auth/forgot-password',{method:'POST',body:{email:a.email}})).status,200);
    assert.equal(messages.length,1);
    const token = messages[0].text.match(/[a-f0-9]{48}/)[0];
    assert.equal((await request('/auth/reset-password',{method:'POST',body:{token,password:'replacement123'}})).status,200);
    assert.equal((await request('/auth/reset-password',{method:'POST',body:{token,password:'replacement123'}})).status,400);
    assert.equal((await request('/auth/me',{token:a.token})).status,401);
    assert.equal((await request('/auth/login',{method:'POST',body:{email:a.email,password:'replacement123'}})).status,200);
  } finally { delete process.env.EMAIL_WEBHOOK_URL; await new Promise(resolve=>gateway.close(resolve)); }
});

test('moving, suspension, preserved history, measured time, settings validation and reset', async () => {
  const user = await signup('History');
  const other = await signup('Other');
  const createDeck = async (token,name) => (await request('/decks',{token,method:'POST',body:{name,remindersEnabled:false}})).body;
  const d1 = await createDeck(user.token,'Original'), d2 = await createDeck(user.token,'Destination'), foreign = await createDeck(other.token,'Private');
  const card = (await request(`/decks/${d1.id}/cards`,{token:user.token,method:'POST',body:{front:'Preserve this',back:'Answer'}})).body;
  const oldPath = `/decks/${d1.id}/cards/${card.id}`;
  assert.equal((await request(oldPath,{token:user.token,method:'PUT',body:{targetDeckId:foreign.id}})).status,404);
  assert.equal((await request(oldPath,{token:user.token,method:'PUT',body:{targetDeckId:d2.id,front:'Moved'}})).status,200);
  assert.equal((await request(`/decks/${d1.id}`,{token:user.token})).body.cards.length,0);
  const path = `/decks/${d2.id}/cards/${card.id}`;
  assert.equal((await request(path,{token:user.token,method:'PUT',body:{suspended:true}})).body.suspended,true);
  assert.equal((await request(path+'/review',{token:user.token,method:'POST',body:{correct:true}})).status,409);
  await request(path,{token:user.token,method:'PUT',body:{suspended:false}});
  assert.equal((await request(path+'/review',{token:user.token,method:'POST',body:{correct:false,durationSeconds:120}})).status,200);
  assert.equal((await request('/progress',{token:user.token})).body.minutesStudiedToday,2);
  assert.equal((await request('/progress',{token:user.token})).body.weeklyAccuracy,0);
  await request(`/decks/${d2.id}`,{token:user.token,method:'DELETE'});
  assert.equal((await request('/progress',{token:user.token})).body.totalXp,10);
  const history = (await request('/progress/history',{token:user.token})).body;
  assert.equal(history[0].deckName,'Destination'); assert.equal(history[0].cardFront,'Moved');
  assert.equal((await request('/progress/history',{token:other.token})).body.length,0);
  assert.equal((await request('/settings',{token:user.token,method:'PUT',body:{themeMode:'bad'}})).status,400);
  assert.equal((await request('/settings',{token:user.token,method:'PUT',body:{timeZone:'Bad/Zone'}})).status,400);
  assert.equal((await request('/settings',{token:user.token,method:'PUT',body:{themeMode:'dark',timeZone:'UTC'}})).status,200);
  assert.equal((await request('/settings',{token:user.token,method:'DELETE'})).body.themeMode,'light');
  assert.equal((await request('/progress',{token:user.token,method:'DELETE'})).status,204);
  assert.equal((await request('/progress',{token:user.token})).body.totalXp,0);
});

test('custom challenge CRUD, completion notification, cancellation, expiry and weekly rollover', async () => {
  const user = await signup('Challenger'), other = await signup('Challenge outsider');
  const deck = (await request('/decks',{token:user.token,method:'POST',body:{name:'Challenge deck',remindersEnabled:false}})).body;
  const card = (await request(`/decks/${deck.id}/cards`,{token:user.token,method:'POST',body:{front:'Q',back:'A'}})).body;
  const payload = {title:'My challenge',targetCount:2,deckIds:[deck.id],durationDays:3,weakOnly:false};
  const created = await request('/challenges',{token:user.token,method:'POST',body:payload}); assert.equal(created.status,201);
  const id = created.body.id;
  assert.equal((await request(`/challenges/${id}`,{token:other.token,method:'PUT',body:payload})).status,404);
  assert.equal((await request(`/challenges/${id}`,{token:user.token,method:'PUT',body:{...payload,title:'Edited'}})).status,200);
  for (const correct of [true,false]) assert.equal((await request(`/decks/${deck.id}/cards/${card.id}/review`,{token:user.token,method:'POST',body:{correct,challengeId:id,durationSeconds:10}})).status,200);
  const result = (await request('/challenges',{token:user.token})).body.history.find(c=>c.id===id);
  assert.equal(result.status,'completed'); assert.equal(result.scorePercent,50); assert.equal(result.answered,2);
  assert.ok((await request('/notifications',{token:user.token})).body.some(n=>n.title==='Desafio concluído'));
  const cancelled = (await request('/challenges',{token:user.token,method:'POST',body:payload})).body;
  assert.equal((await request(`/challenges/${cancelled.id}`,{token:user.token,method:'PUT',body:{status:'cancelled'}})).body.status,'cancelled');
  assert.equal((await request(`/challenges/${cancelled.id}`,{token:user.token,method:'DELETE'})).status,204);
  const expired = (await request('/challenges',{token:user.token,method:'POST',body:payload})).body;
  await pool.query("UPDATE challenges SET ends_at = CURRENT_TIMESTAMP - INTERVAL '1 second' WHERE id = $1",[expired.id]);
  await refreshChallenges(user.id);
  assert.equal((await request('/challenges',{token:user.token})).body.history.find(c=>c.id===expired.id).status,'expired');
  const weekly = await request('/challenges/join',{token:user.token,method:'POST',body:{}}); assert.equal(weekly.status,200);
  assert.equal(weekly.body.challenge.week,weekKey(new Date(),'America/Sao_Paulo'));
  const repeat = await request('/challenges/join',{token:user.token,method:'POST',body:{}}); assert.equal(repeat.body.challenge.id,weekly.body.challenge.id);
  assert.equal(weekKey(new Date('2026-10-26T02:00:00Z'),'America/Sao_Paulo'),'2026-10-19');
  assert.equal(weekKey(new Date('2026-10-26T03:00:00Z'),'America/Sao_Paulo'),'2026-10-26');
  assert.equal(dateKey(new Date('2026-10-24T01:00:00Z'),'America/Sao_Paulo'),'2026-10-23');
});

test('notification CRUD, due scheduling, deduplication, and push failures remain recoverable', async () => {
  const user = await signup('Notify'), other = await signup('Notified outsider');
  const now = new Date();
  const created = await request('/notifications',{token:user.token,method:'POST',body:{title:'Later',body:'Body',scheduledAt:new Date(now.getTime()+86400000).toISOString()}});
  assert.equal(created.status,201); const id = created.body.id;
  assert.equal((await request(`/notifications/${id}`,{token:other.token,method:'PUT',body:{unread:false}})).status,404);
  assert.equal((await request(`/notifications/${id}`,{token:other.token,method:'DELETE'})).status,404);
  await processNotifications(now);
  assert.equal((await pool.query('SELECT delivered_at FROM notifications WHERE id = $1',[id])).rows[0].delivered_at,null);
  assert.equal((await request(`/notifications/${id}`,{token:user.token,method:'PUT',body:{title:'Now',scheduledAt:now.toISOString()}})).status,200);
  await processNotifications(now);
  assert.ok((await pool.query('SELECT delivered_at FROM notifications WHERE id = $1',[id])).rows[0].delivered_at);
  assert.equal((await request(`/notifications/${id}`,{token:user.token,method:'PUT',body:{unread:false}})).body.unread,false);
  assert.equal((await request(`/notifications/${id}`,{token:user.token,method:'PUT',body:{unread:true}})).body.unread,true);
  await request('/notifications/devices',{token:user.token,method:'POST',body:{token:'test-device',platform:'android'}});
  let fail = true; const deliveries = [];
  const gateway = createServer(async (req,res) => {let data='';for await(const chunk of req)data+=chunk;deliveries.push(JSON.parse(data));res.writeHead(fail?503:200).end();});
  await new Promise(resolve=>gateway.listen(0,'127.0.0.1',resolve));
  process.env.PUSH_WEBHOOK_URL=`http://127.0.0.1:${gateway.address().port}`;
  try {
    for(let i=0;i<5;i++) {await pool.query('UPDATE notifications SET push_retry_at = NULL WHERE id = $1',[id]);await processNotifications(now);}
    assert.equal((await pool.query('SELECT push_status FROM notifications WHERE id = $1',[id])).rows[0].push_status,'failed');
    assert.ok((await request('/notifications',{token:user.token})).body.some(n=>n.id===id));
    await request(`/notifications/${id}`,{token:user.token,method:'PUT',body:{retryPush:true}});
    fail=false; await processNotifications(now);
    assert.equal((await pool.query('SELECT push_status FROM notifications WHERE id = $1',[id])).rows[0].push_status,'sent');
    assert.ok(deliveries.some(n=>n.id===id && n.devices[0]?.token==='test-device'));
  } finally {delete process.env.PUSH_WEBHOOK_URL;await new Promise(resolve=>gateway.close(resolve));}
  const deck = (await request('/decks',{token:user.token,method:'POST',body:{name:'Reminder',reminderTimes:['00:00']}})).body;
  await processNotifications(now); await processNotifications(now);
  let reminders=(await request('/notifications',{token:user.token})).body.filter(n=>n.body.includes('Reminder'));
  assert.equal(reminders.length,1);
  await request(`/notifications/${reminders[0].id}`,{token:user.token,method:'DELETE'});
  await processNotifications(now);
  assert.equal((await request('/notifications',{token:user.token})).body.filter(n=>n.body.includes('Reminder')).length,0);
  await request(`/notifications/${id}`,{token:user.token,method:'DELETE'});
  assert.equal((await request('/notifications',{token:user.token})).body.some(n=>n.id===id),false);
});
