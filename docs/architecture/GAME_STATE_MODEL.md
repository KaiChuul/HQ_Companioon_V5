# HeroQuest Companion App
## Game State Model (Campaign → Session → Party → Hero → Monster)

This document describes the **authoritative game state model** used by the HQ Companion App and how that state moves through the system.

It is intended for:
- developers onboarding to the codebase
- AI dev agents implementing V6 changes
- reviewers validating expansion support

This is a **state-tracking model** (not a full tabletop simulator).

---

# 1) High-Level Concepts

## Campaign
A long-lived container for:
- party roster
- hero sheets (persistent)
- quest log (progress)
- enabled packs (Base + expansions)

## Session
A single live play instance for:
- current quest
- revealed rooms / map state
- active monsters and their health/status
- per-quest flags and counters

A campaign can have multiple sessions over time.

## Party
A shared resource bucket and roster-level state:
- shared reputation tokens (Dread Moon)
- mercenaries (Dread Moon)
- party gold policies (optional)
- unlocked features (mercenaries unlocked per quest notes)

## Hero
A persistent character sheet:
- Body/Mind points
- equipped gear
- inventory and consumables
- spells and spell usage
- status effects (shock, disguised, etc.)

## Monster
A per-session entity:
- stats template (type)
- instance state (HP, statuses, location/room association)
- spell usage per quest (for monsters that cast)

---

# 2) Entity Relationship Diagram (Text)

```
Campaign (1)
  ├── Party (1)
  │     ├── Heroes (1..N)   (persistent sheets)
  │     ├── Mercenaries (0..N)  (persistent if hired via reputation token)
  │     └── ReputationTokens (0..∞)
  │
  ├── Sessions (0..N)
  │     ├── Quest (1)
  │     ├── RoomState (0..N)
  │     ├── MonsterInstances (0..N)
  │     └── SessionFlags (0..N)
  │
  └── QuestLog (0..N)
```

---

# 3) Canonical Data Shapes (V6 Target)

Below are **canonical interfaces**. Adapt to your exact Mongoose/DB schema, but keep the logical shape stable.

## 3.1 Campaign

```ts
export type Campaign = {
  id: string;
  name: string;
  joinCode: string;

  enabledPacks: PackId[];              // ["BASE","DREAD_MOON",...]
  questLog: QuestLogEntry[];           // completed quests, dates, rewards

  partyId: string;                     // reference
  activeSessionId?: string | null;     // currently running session (optional)
};
```

## 3.2 Party

```ts
export type Party = {
  id: string;
  campaignId: string;

  heroIds: string[];                   // roster
  sharedGold?: number;                 // optional feature

  // Dread Moon systems
  reputationTokens: number;
  unlockedMercenaryTypes: MercenaryTypeId[];
  mercenaries: MercenaryInstance[];    // persistent hire model
};
```

## 3.3 Hero

```ts
export type Hero = {
  id: string;
  campaignId: string;
  ownerPlayerId?: string | null;       // for auth + ownership

  classId: HeroClassId;                // barbarian, dwarf, elf, wizard, knight
  name: string;

  maxBodyPoints: number;
  bodyPoints: number;
  maxMindPoints: number;
  mindPoints: number;

  gold: number;

  equipment: EquipmentState;           // equipped slots
  inventory: InventoryItem[];          // unequipped items
  consumables: ConsumableItem[];       // potions/tools with counts/uses
  artifacts: ArtifactItem[];           // separate from armory items

  spellState?: SpellState;             // base spells + scrolls

  statusFlags: HeroStatusFlags;        // shock, disguised, etc.

  // Dread Moon
  alchemy?: AlchemyState;
};
```

### HeroStatusFlags

```ts
export type HeroStatusFlags = {
  isDead?: boolean;
  isInShock?: boolean;                 // mind shock
  isDisguised?: boolean;               // Dread Moon
  disguiseBrokenReason?: string;

  // future expansion flags go here (always optional)
};
```

### EquipmentState

```ts
export type EquipmentState = {
  weaponMain?: string | null;          // itemId
  weaponOff?: string | null;           // shield or offhand
  armorBody?: string | null;           // chain/plate
  armorHead?: string | null;           // helmet
};
```

## 3.4 Session

```ts
export type Session = {
  id: string;
  campaignId: string;

  questId: string;                     // link to quest data
  rulesSnapshot: EffectiveRules;       // resolved at session start (packs + quest flags)

  roomStates: Record<string, RoomState>;
  monsterInstances: MonsterInstance[];

  // per-quest counters / toggles
  sessionFlags: Record<string, boolean | number | string>;
};
```

### RoomState

```ts
export type RoomState = {
  roomId: string;
  revealed: boolean;
  searchedTreasure?: boolean;           // optional tracking
  searchedTraps?: boolean;              // optional tracking
  searchedSecrets?: boolean;            // optional tracking

  // quest-specific
  tags?: string[];                      // "hideout", "plaza", "waterway"
};
```

## 3.5 Monster Templates vs Instances

Templates belong to game data (`shared/src/data/monsters.ts`).

```ts
export type MonsterType = {
  id: string;                           // "goblin", "dread_wraith", etc.
  name: string;

  attackDice: number;
  defendDice: number;
  bodyPoints: number;
  mindPoints?: number;

  tags?: MonsterTag[];                  // "undead", "ethereal", "large", etc.
  spellsKnown?: string[];               // for Dread Moon spellcasters
};
```

Instances live in Session state:

```ts
export type MonsterInstance = {
  id: string;
  typeId: string;

  bodyPoints: number;
  mindPoints?: number;

  roomId?: string | null;               // association to revealed area
  isAlive: boolean;

  statusFlags: MonsterStatusFlags;

  // optional: per-quest spell usage tracking
  spellsUsed?: Record<string, number>;  // spellId -> timesUsed
};
```

### MonsterStatusFlags

```ts
export type MonsterStatusFlags = {
  isEthereal?: boolean;
  isSmokeBombed?: boolean;

  // future statuses here
};
```

---

# 4) Rules Layer (EffectiveRules)

Effective rules are resolved once per session and cached as `rulesSnapshot`.

```ts
export type EffectiveRules = {
  allowedHeroes: HeroClassId[];
  enabledSystems: EnabledSystem[];

  // system toggles expanded into booleans for convenience
  disguises: boolean;
  reputationTokens: boolean;
  mercenaries: boolean;
  alchemy: boolean;
  mindShock: boolean;

  // future flags
  etherealMonsters?: boolean;
  undergroundMarket?: boolean;
  hideouts?: boolean;
};
```

Resolution inputs:
- campaign.enabledPacks
- pack default rules
- quest.flags overriding pack defaults

Output:
- rulesSnapshot used by server validation + client rendering

---

# 5) Event Flow (Authoritative Sync)

The system is server-authoritative.

## 5.1 Command → Handler → DB → Broadcast

```
Client emits SocketCommand
  ↓
Server validates auth + rulesSnapshot
  ↓
Server updates MongoDB
  ↓
Server emits state_update to session/campaign room
  ↓
Clients update stores
```

## 5.2 Read vs Write Paths (V6 Requirement)
- **Reads** may use REST or socket snapshot fetch.
- **Writes** must use SocketCommand only.

---

# 6) Minimal State Update Contract

To prevent overfetch and keep the UI responsive, V6 should broadcast small patches.

Recommended `state_update` payload shape:

```ts
type StateUpdate =
  | { kind: "HERO_UPDATED"; hero: Hero }
  | { kind: "PARTY_UPDATED"; party: Party }
  | { kind: "SESSION_UPDATED"; session: Session }
  | { kind: "MONSTER_UPDATED"; sessionId: string; monster: MonsterInstance }
  | { kind: "ROOM_UPDATED"; sessionId: string; roomState: RoomState };
```

Clients:
- apply patch to local store
- do not refetch full objects unless necessary

---

# 7) Expansion-Specific State (Dread Moon)

Dread Moon adds:

## Party
- reputationTokens
- mercenaries + unlocked types

## Hero
- isDisguised (+ reason)
- alchemy inventory
- shock status is core but used heavily

## Session
- hideout flags
- plaza/waterway tags in room state (quest data)

---

# 8) Common Pitfalls (What To Avoid)

- Mixing artifact-like items into armory items without a clear category
- Allowing REST endpoints to mutate hero state (bypasses auth + rules)
- Encoding quest text or copyrighted content into quest data
- Hardcoding expansion checks in UI instead of checking enabledSystems

---

# 9) Implementation Checklist for Agents

When implementing V6 changes, agents should ensure:

- [ ] All state mutations are socket commands
- [ ] EffectiveRules is computed once per session and stored in rulesSnapshot
- [ ] Equipment legality is validated server-side
- [ ] Mind shock overrides equipment bonuses when calculating dice reminders
- [ ] Expansion systems are gated via enabledSystems (no hardcoded pack checks)

---

# Appendix: “What Is Persisted Where?”

- Campaign: long-lived progression + enabled packs
- Party: shared resources + roster-level expansion state
- Hero: persistent character sheets
- Session: quest-specific state (rooms + monsters + per-quest counters)
- MonsterInstances: always session-scoped (unless you intentionally persist between sessions)

This separation is the key to making expansions modular without breaking base gameplay.
