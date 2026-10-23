// Configure PUSH_WEBHOOK_URL and optionally PUSH_WEBHOOK_TOKEN later.
// A provider adapter should deliver to the supplied device tokens (FCM/APNs).
// Unconfigured push remains pending; inbox notifications still work normally.
export async function deliverPush(notification, devices) {
  if (!process.env.PUSH_WEBHOOK_URL) return false;
  const response = await fetch(process.env.PUSH_WEBHOOK_URL, {
    method: 'POST', headers: { 'Content-Type': 'application/json',
      ...(process.env.PUSH_WEBHOOK_TOKEN ? { Authorization: `Bearer ${process.env.PUSH_WEBHOOK_TOKEN}` } : {}) },
    body: JSON.stringify({ id: notification.id, userId: notification.user_id,
      title: notification.title, body: notification.body, devices }),
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error(`Push gateway returned ${response.status}`);
  return true;
}
