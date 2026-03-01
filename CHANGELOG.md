# Changelog

All notable changes to this project are documented here.
Each entry includes the date, category, affected files, and a description of what changed and why.

Format: `[YYYY-MM-DD] — Category — Description`

---

## [2026-02-28] — Initial scaffold

**Category:** Foundation

All source files created from scratch as the initial monorepo scaffold.

### Files created
- `package.json` — root workspace config (`shared`, `server`, `client`)
- `shared/src/types.ts` — all shared TypeScript types and runtime constants: `PACKS`, `QUESTS`, `MONSTER_TYPES`, `HERO_BASE_STATS`, `resolveEffectiveRules`
- `shared/package.json` — workspace package config
- `server/src/index.ts` — Express + Socket.io entry point (port 4000, MongoDB connection)
- `server/src/db.ts` — Mongoose `connectDb()` helper
- `server/src/routes/campaigns.ts` — Campaign CRUD + join-by-code
- `server/src/routes/sessions.ts` — Session start/load
- `server/src/routes/heroes.ts` — Hero CRUD + list-by-campaign
- `server/src/socket/handlers.ts` — Socket command handlers: `ADJUST_POINTS`, `SELECT_HERO`, `SET_ROOM_STATE`, `USE_ITEM`, `SPAWN_MONSTER`, `REMOVE_MONSTER`
- `server/src/models/` — Mongoose schemas: Campaign, Session, Hero, Party
- `server/package.json` — server workspace config
- `server/tsconfig.json` — server TypeScript config (CommonJS, outDir: dist)
- `server/.env.example` — environment variable template
- `client/src/App.tsx` — React Router routes: `/`, `/gm/:campaignId`, `/play/:code`, `/hero/:heroId`
- `client/src/socket.ts` — Socket.io singleton reading `VITE_SERVER_URL`
- `client/src/pages/Home.tsx` — Campaign creation + join-by-code
- `client/src/pages/GMDashboard.tsx` — Full GM session control
- `client/src/pages/PlayerLobby.tsx` — Hero selection filtered by quest rules
- `client/src/pages/PlayerSheet.tsx` — Live hero sheet (stats, inventory, spells)
- `client/src/components/` — HeroCard, MonsterTracker, QuestSelector, PartyOverview, RoomGrid, StatAdjuster
- `client/src/stores/` — Zustand stores: campaignStore, sessionStore, heroStore
- `client/package.json` — client workspace config
- `client/tsconfig.json` — client TypeScript config (ESNext, noEmit, bundler moduleResolution)
- `client/vite.config.ts` — Vite config with `@hq/shared` alias + dev proxy to port 4000
- `client/tailwind.config.ts` — Tailwind theme (parchment, hq-dark, hq-brown, hq-amber colours)
- `client/postcss.config.js` — PostCSS with Tailwind + autoprefixer
- `client/index.html` — SPA entry HTML
- `client/src/main.tsx` — React root mount
- `client/src/index.css` — Tailwind directives + custom component classes
- `README.md` — Design specification document

---

## [2026-02-28] — Deployment infrastructure

**Category:** Deployment / Docs

Created AWS + Cloudflare Tunnel deployment guide.

### Files created
- `DEPLOY.md` — full deployment guide: EC2 setup, MongoDB install, `cloudflared` install, Cloudflare tunnel config

### Files updated
- `DEPLOY.md` — revised to include **Cloudflare Origin CA certificate** setup (Part 4) for end-to-end HTTPS using `Full (Strict)` SSL mode; updated TLS architecture diagram; updated tunnel `config.yml` to use `https://localhost:4000` with `caPool` and `originServerName`; added SSL mode note to Gotchas

---

## [2026-02-28] — Production readiness fixes

**Category:** Bug Fix / Build

Fixed three deployment-blocking gaps identified during pre-deployment audit.

### `server/src/index.ts`
- **Added HTTPS support**: replaced `import { createServer } from "http"` with conditional `createHttpsServer` / `createHttpServer` switch driven by `TLS_CERT_PATH` and `TLS_KEY_PATH` environment variables. When those variables are absent (local dev), the server falls back to plain HTTP — no dev workflow change.
- **Added static file serving**: added `express.static(client/dist)` + SPA wildcard route after the REST routes so the built React client is served by the same Express process on port 4000. Without this, all non-API routes returned 404 in production.

### `client/.env.production` _(new file)_
- Created with `VITE_SERVER_URL=https://HQv2.savvy-des.com`. Without this, Vite bakes `http://localhost:4000` into the production bundle and the client can never reach the server.

---

## [2026-02-28] — Build system fixes

**Category:** Bug Fix / Build

Four interconnected issues prevented `npm run build` from completing. Fixed in order of the build chain.

### `shared/tsconfig.json` _(new file)_
- Created TypeScript config for the shared workspace: `target: ES2022`, `module: CommonJS`, `declaration: true`, `outDir: dist`. Without this, running `tsc` inside `shared/` had no configuration and exited immediately with an error.

### `shared/package.json`
- Added `"scripts": { "build": "tsc" }` — the root build script calls `npm run build --workspace=shared` as its first step; without a `build` script in this package, the entire build chain aborted at step 1 with `npm ERR! missing script: build`.
- Changed `"main"` from `"./src/types.ts"` to `"./dist/types.js"` — in production, `node server/dist/index.js` resolves `require("@hq/shared")` via the npm workspace symlink to this `main` field. Pointing to a `.ts` source file caused Node to throw at startup since it cannot execute TypeScript without a loader.
- Changed `"types"` from `"./src/types.ts"` to `"./dist/types.d.ts"` — consistent with the compiled output.
- Added `"devDependencies": { "typescript": "^5.4.5" }` — makes the `tsc` binary available explicitly within the workspace.

### `server/tsconfig.json`
- Changed `paths["@hq/shared"]` from `["../shared/src/types.ts"]` to `["../shared/dist/types"]`. The previous value pointed to a `.ts` source file outside `rootDir: "src"`. TypeScript adds path-aliased `.ts` files to the compilation program; a file outside `rootDir` causes error `TS6059: File is not under rootDir`. Pointing to the compiled `.d.ts` (a declaration file, never added to the compilation program) avoids this error entirely.

### `package.json` (root)
- Updated `"dev"` script from `concurrently "..."` to `npm run build --workspace=shared && concurrently "..."`. The development servers (`tsx watch` for server, `vite` for client) resolve `@hq/shared` at runtime via the npm workspace symlink. Since `shared/package.json` now points to `./dist/types.js`, shared must be compiled at least once before the dev servers start. The pre-build step ensures `shared/dist/` always exists when dev mode launches.

---

## [2026-02-28] — Documentation update

**Category:** Docs

Updated all documentation to reflect the current state of the codebase.

### `README.md`
- Added **Quick Start** section at the top with install/run/build instructions, env variable table, and project directory structure.
- Added link to `DEPLOY.md`.
- Replaced speculative "Tech Stack (Recommended)" section with the actual stack as built: Vite, React 18, TailwindCSS v3, Zustand, Socket.io-client, Node 20, Express, Mongoose, npm workspaces.

### `DEPLOY.md`
- Rewrote **Part 1** from "manual code change instructions" to a "verify local build" checklist — the code changes it previously described are already in the repository.
- Added `server/.env.example` copy step to the local smoke-test instructions.
- Added two new items to **Notes & Gotchas**: dev workflow note about `npm run dev` pre-building shared, and instruction for rebuilding shared when `types.ts` is edited mid-session.

### `CHANGELOG.md` _(this file — new)_
- Created as the permanent change history for the project.

---

_Update this file whenever changes are made to the codebase, configuration, or documentation._

---

## [2026-03-01] — Security, bug fixes, and GM inventory management

**Category:** Bug Fix / Security / Feature

Addressed all high and medium priority issues found in a full codebase review. Changes span shared types, all server routes, socket handlers, and every client page.

### Security & Authorization

- **`server/src/socket/handlers.ts`** — `ADJUST_POINTS` now requires GM role for monster adjustments; hero adjustments require either GM or the owning player (`socket.data.playerId`). `USE_ITEM` has the same ownership check. Previously any connected socket could modify any entity.
- **`server/src/socket/handlers.ts`** — `SPAWN_MONSTER` validates `monsterTypeId` against the `MONSTER_TYPES` constant before inserting; unknown types are now rejected.
- **`server/src/routes/heroes.ts`** — `POST /api/heroes` rejects creation with HTTP 409 if a hero of the same type already exists in the campaign, enforcing the `uniqueHeroesOnly` constraint from both packs.
- **`server/src/routes/campaigns.ts`** — Join codes now use `customAlphabet("A-Z0-9", 6)` (nanoid) instead of `nanoid(6).toUpperCase()`. The previous approach could produce codes containing `_` or `-`.

### Bugs Fixed

- **`server/src/routes/campaigns.ts`** — Moved `GET /join/:code` **before** `GET /:id` to prevent Express matching "join" as a campaign ObjectId.
- **`server/src/socket/handlers.ts`** — Monster BP adjustment now applies `Math.min(bodyPointsMax, …)` upper clamp (hero BP already had this; monsters did not).
- **`server/src/socket/handlers.ts`** — `handleSelectHero` now casts `rulesSnapshot` as `EffectiveRules` instead of `any`, and actually uses the `constraints.uniqueHeroesOnly` field to reject duplicate hero type claims.
- **`client/src/components/StatAdjuster.tsx`** — `+2` button was disabled at `current >= max - 1` (too aggressive); corrected to `current >= max`, matching the `+1` button.
- **`client/src/pages/PlayerSheet.tsx`** — Removed dead `spellsAvail` state that read from a `sessionStorage` key (`"heroType"`) that was never written anywhere.
- **`client/src/pages/PlayerSheet.tsx`** — Spell checkboxes were permanently `readOnly` with no handler. They are now interactive: clicking toggles the spell via a new `SELECT_SPELL` socket command, and the UI enforces the per-class limit client-side before the server validates it.

### Architecture & Session Recovery

- **`shared/src/types.ts`** — Added `currentSessionId?: string` to the `Campaign` type and `SelectSpellCommand` to the `SocketCommand` union.
- **`server/src/models/Campaign.ts`** — Added `currentSessionId` field to the Mongoose schema.
- **`server/src/routes/sessions.ts`** — On session creation, `campaign.currentSessionId` is written. New `PATCH /api/sessions/:id/end` endpoint sets `endedAt` and clears `currentSessionId` on the campaign.
- **`client/src/pages/GMDashboard.tsx`** — `loadCampaign` now fetches the session from `campaign.currentSessionId` on mount so the GM can reload the page without losing the active session.
- **`client/src/pages/GMDashboard.tsx`** — A `useEffect` on `session?.id` now calls `joinSession` with the `sessionId` parameter, ensuring the GM's socket is always in the correct `session:{id}` room to receive `SESSION_UPDATED` events (monsters, rooms). Previously the GM never joined the session room and all real-time session updates were silently dropped.
- **`client/src/socket.ts`** — Added `lastJoinParams` tracking and a `socket.on("reconnect")` listener that re-emits the join event, restoring `socket.data` and room membership after a reconnect without a page reload.
- **`server/src/index.ts`** — Join event type extended to include `playerId?: string`.
- **`client/src/pages/PlayerLobby.tsx`** — `joinSession` now passes `playerId` so the server can verify ownership on subsequent socket commands.

### New Feature — GM Hero Inventory Management

- **`server/src/routes/heroes.ts`** — Four new endpoints: `PATCH /api/heroes/:id/gold` (award/deduct gold), `POST /api/heroes/:id/equipment` (add item), `DELETE /api/heroes/:id/equipment/:equipId` (remove item), `POST /api/heroes/:id/consumables` (add consumable).
- **`client/src/pages/GMDashboard.tsx`** — New "Hero Inventory" panel in the Party tab. The GM selects a hero from a dropdown and can award gold, add/remove equipment (with optional ATK/DEF bonuses), and add consumables. Hero state updates immediately from the REST response without a full reload.
- **`client/src/pages/GMDashboard.tsx`** — Added "End Session" button (calls the new end-session endpoint) alongside the existing "Mark Quest Completed" button.

### Code Quality

- **`server/src/utils/docToJson.ts`** _(new file)_ — Extracted shared Mongoose-to-JSON serializer, replacing four identical `docToJson` functions across `campaigns.ts`, `sessions.ts`, `heroes.ts`, and `handlers.ts`.
- **`client/src/pages/GMDashboard.tsx`** — `loadHeroes` now has a `try/catch` so fetch errors are not silently swallowed.
- **`server/src/socket/handlers.ts`** — Removed unused `PartyModel` import and the dead `const { sessionId, role }` destructure at connection time.

---

## [2026-03-01] — Phase 1 dev baseline
**Category:** Infrastructure
Provisioned the initial dev EC2 baseline using the default VPC, SSM (Session Manager), and a restricted security group.
### infra/terraform/envs/dev/main.tf
- Added Phase 1 dev baseline resources: default VPC + subnet selection, EC2 IAM role/instance profile, security group, Amazon Linux 2 AMI, and an EC2 instance.
