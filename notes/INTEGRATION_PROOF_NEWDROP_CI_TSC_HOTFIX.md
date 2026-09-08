# Integration proof — Newdrop CI typecheck hotfix (#121)

- **When:** 2026-09-08T04:43Z (Mac hub agent)
- **Repo:** Newdrop (CaaS) @ `/Users/togi/CaaS`
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (user after #110 → tip raced through #111/#112/#114/#117/#119 → land #121)
- **Irreversible artifact:** merged PR https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/121
  - branch `peer/factory-ci-tsc-hotfix-after119`
  - product commit `0d83c98`
  - merge commit `64ff4a6169834ca045f1082884221247fdd4c3db` on `main`
- **Needle:** CI build restore · `product-alerts.test.ts` `vi.hoisted` mock (no `unknown[]` spread) · clone-spike `alerted: string[]` matches `runCloneSpikeCheck` · prior #116 closed mid-race
- **Native verify (pre-merge tip):**
  - `npx tsc --noEmit` EXIT 0
  - `npm test` — **464 passed** EXIT 0
  - `npm run check:controls` — **110 ok · 0 fail** EXIT 0
- **UI:** untouched · **NO PAY**
- **Same wave:** [#119](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/119) data-backup nest · [#117](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/117) CSP · [#112](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/112) clone-spike · [#111](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/111) obs alerts
- **Next step:** closed — leave Active after #121 open
