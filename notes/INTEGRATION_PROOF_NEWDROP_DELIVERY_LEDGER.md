# Integration proof — Newdrop notification delivery ledger (#123)

- **Date:** 2026-09-08
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (after #121 tip → #123)
- **PR:** [#123](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/123) **MERGED** `a9ff4e7`
- **Product:** `5b76b90` on `peer/factory-hf53-clean`
- **Verify:** `npm test` 467 PASS · `check:controls` 114ok · **UI untouched** · NO PAY
- **Needle:** Hard-Fix #53 · `notification_deliveries` ledger before Resend · mark sent/failed · purge-abuse nests exponential backoff retry (max 5) · raise caps still gated
- **Hard-Fix:** #53
- **Files:** `supabase/migrations/0062_notification_deliveries.sql` · `src/lib/email/notification-deliveries.ts` · `src/lib/email/notify.ts` · `src/app/api/cron/purge-abuse/route.ts`
- **Same wave:** [#121](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/121) CI tsc · [#119](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/119) data-backup nest · [#117](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/117) CSP
- **Next step:** closed — tip after #123; Active after #123 left open
