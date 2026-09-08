# Integration proof — Newdrop service-role blast radius (#129)

- **When:** 2026-09-08T04:53Z
- **Repo:** Newdrop (CaaS) @ `/Users/togi/CaaS`
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (after #130 → tip #129)
- **Irreversible artifact:** merged PR https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/129
  - branch `peer/factory-hf97-after123`
  - product commit `4a5fa5c`
  - merge commit `bfe4cc3` on `main`
- **Needle:** Hard-Fix #97 · Stripe webhook one `createAdminClient` (−2) · `check:service-role` max fixture 86 · DEFINER RPC residual
- **Native verify (tip at land):**
  - `npm test` — **470 passed** EXIT 0
  - `npm run check:controls` — **123 ok · 0 fail** EXIT 0
  - `npm run check:service-role` — OK 86/86
- **UI:** untouched · **NO PAY**
- **Same wave:** [#130](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/130) deliverability · [#127](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/127) pentest trigger · [#124](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/124) billing nest
- **Next step:** closed — leave Active after #129 open
