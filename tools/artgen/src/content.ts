// Loads the data-driven game content. Everything that defines *what* the game is
// (goods, tiers, buildings, valleys) lives in /content as JSON and can be edited
// or modded without touching code.
import goodsJson from '../../../content/goods.json';
import tiersJson from '../../../content/tiers.json';
import buildingsJson from '../../../content/buildings.json';
import fertilitiesJson from '../../../content/fertilities.json';
import valleysJson from '../../../content/valleys.json';
import rivalsJson from '../../../content/rivals.json';
import type { BuildingDef, FertilityDef, GoodDef, RivalDef, TierDef, ValleyDef } from './types';

export const GOODS = goodsJson as GoodDef[];
export const TIERS = tiersJson as TierDef[];
export const BUILDINGS = buildingsJson as BuildingDef[];
export const FERTILITIES = fertilitiesJson as FertilityDef[];
export const VALLEYS = valleysJson as ValleyDef[];
export const RIVALS = rivalsJson as RivalDef[];

const byId = <T extends { id: string }>(list: T[]) => Object.fromEntries(list.map((x) => [x.id, x])) as Record<string, T>;

export const GOOD = byId(GOODS);
export const TIER = byId(TIERS);
export const BUILDING = byId(BUILDINGS);
export const FERTILITY = byId(FERTILITIES);
export const VALLEY = byId(VALLEYS);
export const RIVAL = byId(RIVALS);

export const tierIndex = (id: string) => TIERS.findIndex((t) => t.id === id);
export const nextTier = (id: string): TierDef | undefined => TIERS[tierIndex(id) + 1];
export const houseTier = (houseId: string) => TIERS.find((t) => t.house === houseId);

/** Service ids provided by service buildings, e.g. "fireplace" -> fireplace building. */
export const SERVICE_IDS = new Set(BUILDINGS.filter((b) => b.service).map((b) => b.service!.id));
export const isServiceNeed = (needId: string) => SERVICE_IDS.has(needId);

/** Names for service needs (they are not goods). */
export function needName(needId: string): { de: string; en: string } {
  if (GOOD[needId]) return GOOD[needId].name;
  const b = BUILDINGS.find((x) => x.service?.id === needId);
  return b ? b.name : { de: needId, en: needId };
}
