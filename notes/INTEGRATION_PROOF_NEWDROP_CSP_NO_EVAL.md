# Integration proof — Newdrop CSP drop unsafe-eval (#117)

- **When:** 2026-09-08T04:39Z (Mac hub agent)
- **Repo:** Newdrop (CaaS) @ `/Users/togi/CaaS`
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (after #112/#114 tip → #117)
- **Irreversible artifact:** merged PR https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/117
  - branch `peer/factory-hf71-csp-no-eval-after112`
  - product commit `437b42e`
  - merge commit `cb47dde5b8994167f324424376c5e3421041e9c4` on `main`
- **Needle:** Hard-Fix #71 · `script-src` omits `'unsafe-eval'` · keeps `'unsafe-inline'` + Stripe.js · `cspLooksHardened` + `check:controls` · AGENT_WORKFLOW · nonces residual
- **Native verify (pre-merge tip):**
  - `npm test` — **461 passed** EXIT 0
  - `npm run check:controls` — **107 ok · 0 fail** EXIT 0
- **UI:** untouched · **NO PAY**
- **Same wave:** [#114](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/114) Auth OTP residual · [#112](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/112) third Hobby drain · [#111](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/111) ops alerts · [#101](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/101) privilege SQL · [#100](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/100) Semgrep · [#98](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/98) embed TTL
- **Next step:** closed — tip after #117; Active after #117 open
