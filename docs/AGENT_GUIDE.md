# AI Developer Agent Guide
## HeroQuest Companion App (V6)

This guide instructs AI development agents how to work inside this repository.

Agents must **read these documents before making code changes**.

Priority order:

1. docs/architecture/V6_MIGRATION_PLAN.md
2. docs/architecture/GAME_STATE_MODEL.md
3. docs/architecture/GEAR_RULES_AND_CATALOG_AUDIT.md
4. docs/architecture/EXPANSION_PLUGIN_ARCHITECTURE.md
5. docs/architecture/DREAD_MOON_V6_IMPLEMENTATION.md

These documents define:

- the V6 system architecture
- the canonical game state model
- equipment legality rules
- the expansion plugin system
- the Dread Moon mechanics implementation

---

# Project Philosophy

This project is a **HeroQuest Companion App**.

It is **not a full tabletop simulator**.

The app:
- tracks hero sheets
- tracks monsters and rooms
- tracks equipment and consumables
- tracks expansion mechanics

The app **does not enforce every tabletop rule automatically**.

It provides **state tracking and rule reminders**.

---

# Critical Architecture Rules

## 1. Server Authoritative State

All gameplay state must be controlled by the server.

Clients may:
- request actions
- display state

Clients must **never be trusted as the source of truth**.

---

## 2. Single Mutation Pipeline

All state mutations must use **SocketCommand**.

Do NOT add REST endpoints that mutate gameplay state.

Allowed mutation flow:

Client → SocketCommand → Server Validation → DB Update → state_update broadcast

---

## 3. Pack Rules Engine

Expansions are enabled via PackDefinition.

Never hardcode expansion logic in the UI.

Use:

```
rules.enabledSystems
```

Example:

```
if (!rules.enabledSystems.includes("alchemy")) return null
```

---

# Gameplay Engine Rules

## Combat Dice

HeroQuest dice faces:

- skull
- whiteShield
- blackShield

Rules:

- heroes attack with skulls
- heroes defend with white shields
- monsters defend with black shields

Dice logic must live in:

```
shared/src/engine/dice.ts
```

Never implement dice logic in UI components.

---

# Equipment Rules

Equipment legality must be validated **server-side**.

Examples:

Wizard restrictions:
- cannot wear armor
- cannot use large weapons

Two-handed weapons:
- prevent shield usage

Disguise restrictions (Dread Moon):
- only small weapons allowed
- only helmets/bracers allowed
- spells forbidden

All logic defined in:

```
docs/architecture/GEAR_RULES_AND_CATALOG_AUDIT.md
```

---

# Expansion System

Expansions are modular packs.

Supported packs:

- BASE
- DREAD_MOON

Future packs:

- FROZEN_HORROR
- MAGE_OF_THE_MIRROR
- OGRE_HORDE

Agents must implement expansions by:

1. creating pack definition
2. adding system flags
3. implementing handlers
4. conditionally rendering UI

Never modify core systems for a single expansion.

---

# Code Organization (V6)

```
app
 ├ shared
 │   ├ types
 │   ├ engine
 │   ├ data
 │   └ packs
 │
 ├ server
 │   ├ socket
 │   ├ models
 │   └ services
 │
 └ client
     ├ store
     ├ components
     └ pages
```

---

# Security Rules

Agents must enforce:

- authenticated socket connections
- hero ownership validation
- GM-only commands

No client may modify another player's hero.

---

# Development Priorities

Agents should implement changes in this order:

1. Combat dice engine
2. Equipment legality validation
3. Socket mutation pipeline
4. Pack rules engine
5. Dread Moon expansion mechanics

---

# Testing Expectations

Before finishing work, verify:

- multiplayer sessions sync correctly
- hero BP/MP changes broadcast properly
- equipment validation prevents illegal states
- expansion systems appear only when enabled

---

# Final Reminder

Agents must follow the architecture documents.

If code conflicts with architecture docs:

**the documentation takes precedence.**
