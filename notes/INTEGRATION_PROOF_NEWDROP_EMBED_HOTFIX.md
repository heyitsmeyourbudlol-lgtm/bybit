# Integration proof — Newdrop embed.js hotfix purge (#92)

- **When:** 2026-09-08T04:12Z (restamped full 2026-09-08T04:28Z — stub → tip proof)
- **Repo:** Newdrop (CaaS) @ `/Users/togi/CaaS`
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (after #91 → #92)
- **Irreversible artifact:** merged PR https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/92
  - branch `peer/factory-hf88-embed-purge-v2`
  - product commit `425647b`
  - merge commit `c90ec94` on `main`
- **Needle:** Hard-Fix #88 · embed.js hotfix purge path · `s-maxage=15` (later tightened to 5 in #98) · AGENT_WORKFLOW purge/redeploy steps · `check:controls` pins · breaking rename still #62
- **Native verify (tip at land):**
  - `npm test` — **452 passed** EXIT 0
  - `npm run check:controls` — **79 ok · 0 fail** EXIT 0
- **UI:** untouched · **NO PAY**
- **Same wave:** [#91](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/91) publish nest · [#89](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/89) CodeQL · [#88](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/88) soft budget
- **Next step:** closed — tip advanced; Active after later tips
