import type { Quest } from "../types";
import { BASE_QUESTS } from "./base/quests/index";
import { DREAD_MOON_QUESTS } from "./dread_moon/quests/index";

export const QUESTS: Quest[] = [...BASE_QUESTS, ...DREAD_MOON_QUESTS];
