# Integration proof — Newdrop editor email on publish (#110)

- **When:** 2026-09-08T04:28Z (Mac hub agent)
- **Repo:** Newdrop (CaaS) @ `/Users/togi/CaaS`
- **Assignment:** `[top10] Newdrop production — next meaningful non-UI merge` (after #104/#101 → #110)
- **Irreversible artifact:** merged PR https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/110
  - branch `peer/factory-hf91-editor-notify-land`
  - product commit `1ff4e854c463a270edfba1eb0b2eb31ac68053be`
  - merge commit `bd6460464a94614d966a444e3127a3739b20f357` on `main`
- **Needle:** Hard-Fix #91 · `notifyEditorsOnPublish` · owner + active editors · default-on · Advanced opt-out deferred · no UI
- **Native verify (pre-merge tip):**
  - `npm test` — **455 passed** EXIT 0
  - `npm run check:controls` — **93 ok · 0 fail** EXIT 0
  - `npx tsc --noEmit` EXIT 0
- **UI:** untouched · **NO PAY**
- **Same wave:** [#101](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/101) privilege SQL · [#100](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/100) Semgrep · [#104](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/104) embed.v2 · [#89](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/89) CodeQL · [#87](https://github.com/heyitsmeyourbudlol-lgtm/caas-changelog/pull/87) expand-contract
- **Next step:** closed — leave Active after #110 open
