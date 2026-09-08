# Integration proof — Newdrop fifth Hobby publish drain via billing-reconcile (#124)

- **When:** 2026-09-08T04:48Z (Mac hub agent)
- **Repo:** Newdrop (CaaS) @ `/Users/togi/CaaS`
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (after #123)
- **Irreversible artifact:** merged PR https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/124
  - branch `peer/factory-hf52-billing-nest5-after121`
  - product commit `768e8aa4739dd87f6f4057bfa833e1e7a015c89c`
  - merge commit `10d13b250d735dbec88faac47d18a37adc22d92c` on `main`
- **Needle:** Hard-Fix #52 residual · `/api/cron/billing-reconcile` nests multi-round `publishDueScheduledUpdates` (06:15 UTC) · fifth Hobby daily tick (purge 03:30 + data-backup 04:00 + publish-scheduled 05:00 + billing-reconcile 06:15 + clone-spike 07:10) · fail-soft · paid hourly residual
- **Native verify (pre-merge tip after rebase onto #123):**
  - `npm test` — **468 passed** EXIT 0
  - `npm run check:controls` — **117 ok · 0 fail** EXIT 0
- **UI:** untouched · **NO PAY**
- **Same wave:** [#123](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/123) delivery ledger · [#121](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/121) CI tsc · [#119](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/119) data-backup nest
- **Next step:** closed — leave Active after #124 open
- **NO PAY**
