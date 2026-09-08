# Integration proof — Newdrop Auth OTP RL residual (#114)

- **When:** 2026-09-08T04:37Z
- **Repo:** Newdrop (CaaS) @ `/Users/togi/CaaS`
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (after #97 → tip after #112 → #114)
- **Irreversible artifact:** merged PR https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/114
  - branch `peer/factory-hf23-auth-otp-residual`
  - product commit `5415528`
  - merge commit `e93d0a3` on `main`
- **Needle:** Hard-Fix #23 · app `/api/auth/otp` 8/hr/IP + 4/hr/email fail-closed · Supabase Auth dashboard RL ≤ app residual · SECURITY_AUDIT §21.7 · AGENT_WORKFLOW · `check:controls` pins
- **Native verify (tip at land):**
  - `npm test` — **461 passed** EXIT 0
  - `npm run check:controls` — **104 ok · 0 fail** EXIT 0
- **UI:** untouched · **NO PAY**
- **Same wave:** [#112](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/112) clone-spike drain · [#111](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/111) observability
- **Next step:** closed — leave Active after #114 open
