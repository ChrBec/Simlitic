// Shared simulation types. The simulation never touches the DOM or the renderer,
// so it can run headless (tests, dedicated lockstep peers, balancing scripts).

export type Lang = 'de' | 'en';
export type Text = Record<Lang, string>;
export type GoodId = string;
export type TierId = string;
export type Amounts = Record<GoodId, number>;

export interface GoodDef { id: GoodId; name: Text; value: number; color: string; glyph: string }
export interface FertilityDef { id: string; name: Text; color: string }

export interface NeedDef {
  id: string; // good id or service id
  kind: 'basic' | 'luxury' | 'service' | 'service-luxury';
  consumption?: number; // per resident per minute
  residents?: number; // bonus residents when fulfilled
  income: number; // shells per resident per minute when fulfilled
}

export interface TierDef {
  id: TierId; name: Text; age: Text; intro: Text; house: string; baseResidents: number; color: string;
  unlock: { tier: TierId; population: number } | null;
  upgradeCost: Amounts;
  needs: NeedDef[];
}

export interface BuildingDef {
  id: string; name: Text; desc: Text;
  category: 'infrastructure' | 'residence' | 'service' | 'production';
  size: [number, number]; style: string; accent: string;
  unlockTier: TierId; buildable?: boolean;
  cost: Amounts & { shells?: number };
  upkeep: number;
  tier?: TierId;
  workforce?: { tier: TierId; amount: number };
  cycle?: number; inputs?: Amounts; outputs?: Amounts;
  service?: { id: string; radius: number };
  requires?: {
    fertility?: string; deposit?: string; nearWater?: number; nearMountain?: boolean;
    nature?: { kind: 'tree' | 'bush'; radius: number; min: number };
  };
}

export interface ValleyDef {
  id: string; name: Text; size: number; home?: boolean; rival?: string;
  fertilities: string[]; deposits: string[]; water: 'lake' | 'stream' | 'none';
}

export interface RivalDef { id: string; name: Text; color: string; greeting: Text; sells: GoodId[]; buys: GoodId[] }

export enum Terrain { Mountain = 0, Grass = 1, Water = 2, Pass = 3 }
export enum Nature { None = 0, Tree = 1, Bush = 2, Rock = 3 }

export interface Tile {
  t: Terrain;
  v: number; // valley index, -1 for mountain / pass
  n: Nature;
  dep: string | null; // deposit id
  road: boolean;
  b: number; // building id occupying this tile, 0 = none
  pass: number; // pass index for pass tiles, -1 otherwise
}

export interface Valley {
  idx: number; def: string; name: Text;
  cx: number; cy: number;
  owner: string | null; // 'player' | rival id | null
  discovered: boolean;
  fertilities: string[];
  storage: Amounts;
  // derived each tick
  workforce: Record<TierId, { have: number; need: number }>;
  population: Record<TierId, number>;
}

export interface Pass { idx: number; a: number; b: number; tiles: [number, number][]; discovered: boolean }

export interface Building {
  id: number; type: string; x: number; y: number; owner: string; valley: number;
  // production
  progress: number; working: boolean; paused: boolean; productivity: number; status: string;
  nature?: number; // cached share of required trees/bushes around (0..1)
  // residence
  tier?: TierId; residents?: number; needs?: Record<string, number>; // need id -> satisfaction 0..1
  connected: boolean;
}

export interface Route {
  id: number; a: number; b: number; // valley indices
  cargoAB: GoodId[]; cargoBA: GoodId[];
  path: [number, number][];
  pos: number; // index along path (float)
  dir: 1 | -1;
  load: Amounts;
  wait: number;
}

export interface Expedition { pass: number; from: number; timeLeft: number; total: number }

export interface Trader { present: boolean; timer: number; prices: Record<GoodId, number> }

export interface RivalState { id: string; valley: number; contacted: boolean; relation: number; population: number; buildTimer: number }

export interface Notification { id: number; t: number; text: Text; kind: 'info' | 'good' | 'warn' | 'tier' }

export interface Objective { id: string; done: boolean }

export interface GameState {
  version: number;
  seed: number; rng: number; tick: number; time: number; // seconds of game time
  w: number; h: number; tiles: Tile[];
  valleys: Valley[]; passes: Pass[];
  buildings: Record<number, Building>; nextId: number;
  shells: number; income: number; upkeep: number;
  unlockedTiers: TierId[];
  upgradeAllowed: Record<TierId, boolean>;
  routes: Route[]; expedition: Expedition | null;
  trader: Trader; rivals: RivalState[];
  notifications: Notification[]; nextNote: number;
  objectives: Objective[];
  stats: { history: { t: number; shells: number; pop: number }[] };
  dirty: number; // bumped when tiles/buildings change (render cache key)
}
