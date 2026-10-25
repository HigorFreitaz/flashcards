# Implemented basics and validation

The Flutter app keeps MVVM (screens -> ChangeNotifier view models -> repositories -> services). Biometric, AI/media generation and spaced repetition prototypes remain prototypes. The API address and existing plaintext password storage remain unchanged by request.

| Area | Implemented behavior |
| --- | --- |
| Accounts | Validated registration/profile changes, duplicate-email errors, persistent session restoration, logout/deletion, single-use expiring password reset codes and session revocation. |
| Decks | Owned CRUD, card-content search, new-card filtering/study access, validated reminder times. |
| Cards | Owned CRUD, atomic movement between owned decks, suspend/resume, correct-answer index reset when changing response type. |
| Study/progress | Explicit text-answer grading, measured foreground study time, local-day statistics, paginated history with snapshots that survive card/deck deletion, confirmed progress reset. |
| Challenges | Custom create/read/edit/cancel/delete, participation, review-linked scoring and completion, expiry, weekly rollover and completion notifications. |
| Notifications | Create/read/edit/delete, read/unread, scheduled inbox delivery, deck reminders, deduplication, device registration endpoint, configurable push delivery with bounded retries and manual retry. |
| Settings | Theme and timezone validation, persisted settings and reset to defaults. |

## Delivery configuration

Use `server/config.example.env` to set the project `.env` values, then run `docker compose up -d api`.

- Email: configure `EMAIL_WEBHOOK_URL` and optional `EMAIL_WEBHOOK_TOKEN`. The gateway accepts `{to, subject, text}` and returns 2xx after accepting delivery. Reset codes expire after 30 minutes and can be used once. Without a gateway, recovery reports unavailable; no email is sent.
- Device push: configure `PUSH_WEBHOOK_URL` and optional `PUSH_WEBHOOK_TOKEN`. The gateway accepts `{id, userId, title, body, devices}`. Deduplicate deliveries by `id`. Integrate the chosen mobile push SDK and register its token through `POST /api/notifications/devices`. Without these steps, in-app notifications work, but operating-system push is not delivered. Empty configuration keeps pushes pending; failed configured deliveries retry up to five attempts and remain available for manual retry.
- The server checks scheduled notifications once per minute. The signed-in app polls the inbox once per minute and also refreshes after study.

## Existing unowned data

Legacy rows are not automatically assigned to an arbitrary account. From `server`, preview with `node scripts/assign-legacy.js <email>` and add `--apply` to assign them to that account. Back up the database before intentionally applying an ownership migration. Previously deleted study history cannot be recovered by the new history snapshots.

## Validation

- `flutter test --no-pub`: tests cover failed saves, account changes, session restoration, moving cards, new-only deck study access, answer-type changes, text grading, SQLite persistence and offline synchronization. Set `LUME_TEST_API` to a disposable API to run the live offline integration test too.
- `flutter analyze --no-pub`: no issues.
- `npm test` with `TEST_DATABASE_URL` pointing at a disposable database ending in `_test`: integration tests covering accounts, ownership, decks/cards, history/settings, challenges, scheduling, push failure/retry and idempotent offline mutations.
- Delivery tests use local mock gateways. Real email providers, native push SDKs and physical-device delivery still need configuration and device testing.

## Offline synchronization (#9)

The mobile app caches decks/cards and previously fetched read responses in
SQLite, scoped by account. Deck/card changes and ordinary study reviews are
saved atomically with a durable FIFO outbox. The app retries on launch, foreground
resume, manual synchronization, and every 30 seconds while running. PostgreSQL
remains authoritative: after replaying pending writes, the app replaces its deck
snapshot with the server response. See `../docs/OFFLINE.md` for behavior, conflict
resolution, limitations and a reproducible test procedure.
