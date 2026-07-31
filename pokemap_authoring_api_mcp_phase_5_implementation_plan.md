# PokeMap Authoring API — Phase 5 Implementation Plan

> Phase: **5 — Contenu du jeu**
> Lots: **PMCP-040 → PMCP-063**
> Execution: current branch, one verified commit per lot, no push
> Initial Git state: clean at `b44cc91ba feat(authoring): add world graph and map rendering`

## Goal and exit contract

Phase 5 extends the protocol-neutral Authoring API from maps to the content
needed by a playable fangame. Existing `map_core`, `map_gameplay`,
`map_battle`, editor, and runtime rules remain authoritative; the new package
provides typed façades, safe plans, capability truth, and adapter seams without
copying engine logic into `map_authoring`.

The phase is complete only when fresh evidence proves:

- imported assets are content-addressed, MIME-inspected, bounded, reference
  aware, recoverable, and path-safe;
- tilesets, palettes, elements, and semantic presets expose strict contracts
  with atlas, grid, dependency, and map-consumption preflights;
- presentation media, typography, licences, glyphs, contrast, and long-running
  processing expose honest diagnostics and artifact/job handles;
- legacy dialogue/script content and modern Scene/Event/Facts/World Rules are
  authorable through existing pure operations and runtime capability truth;
- Storyline/Scenario migration and cinematic timelines retain identities,
  references, revisions, preflight limitations, and legacy readability;
- Pokémon species, moves, abilities, items, trainers, encounters, shops,
  badges, New Game, saves, player state, battles, and progression are covered
  by typed authoring/sandbox façades;
- gameplay simulations delegate to `map_battle`/`map_gameplay`, use explicit
  seeds and decisions, and never modify a production save;
- every PMCP lot has a positive, negative, guard, and non-regression proof,
  package-scoped analysis/tests, a detailed Evidence Pack, and its own commit.

## Architecture decisions

- `map_authoring` remains pure Dart and depends on `map_core`; gameplay and
  battle behavior crosses explicit ports so package direction remains intact.
- Phase 5 contracts are immutable, JSON-safe, deterministic, path-free on the
  public side, and revision-aware where they produce mutations or previews.
- Existing pure authoring operations in `map_core` are adapted, never forked.
- Asset ingestion separates untrusted source acquisition from project mutation:
  an artifact is inspected and addressed first, then a frozen plan can refer to
  its opaque handle.
- Authoring actions over player state operate on an explicit sandbox copy.
  Production save repositories expose read/probe adapters only.
- A capability is `supported` only when a real runtime consumer is registered;
  syntactically authorable but unconsumed definitions remain `partial` or
  `blocked` with stable diagnostics.

## Verification and review passes

`codex_rule.md` requires independent viewpoints. For each stream, the work uses
these named passes (delegated when safe, local otherwise):

1. **Audit / Architecture** — existing contracts, package boundaries, reports,
   roadmap dependencies, and FG status;
2. **Implementation** — smallest production diff satisfying the lot contract;
3. **Tests** — mandatory RED/GREEN plus negative, guard, and non-regression;
4. **Build / Validation** — focused/full tests, analyzer, formatter, and the
   best package build alternative;
5. **Critique finale** — overclaim, accidental scope, runtime consumption,
   security, determinism, and Git inventory.

## Lot sequence and commits

### Phase 5A — Assets and libraries

- `PMCP-040`: content-addressed artifact/asset store, safe imports, reference
  impact, dedupe, rollback, and undo evidence.
  Commit: `feat(authoring): add secure asset store`
- `PMCP-041`: tilesets, palettes, elements, presets, atlas/grid validation,
  cross-map dependency preflight, and semantic-map compatibility.
  Commit: `feat(authoring): add visual library authoring`
- `PMCP-042`: presentation, video/audio/fonts, media validation, async process
  port, preview, and editor adapter characterization.
  Commit: `feat(authoring): add presentation authoring`

### Phase 5B — Narrative

- `PMCP-050`: dialogue/Yarn/script lifecycle, compile/simulate, outcome guards,
  and loss-aware legacy migration.
  Commit: `feat(authoring): add dialogue and script authoring`
- `PMCP-051`: Scene, Event V2, Facts, World Rules, dependency impact,
  reachability, publication gates, and runtime-consumer truth.
  Commit: `feat(authoring): add modern narrative authoring`
- `PMCP-052`: Storyline lifecycle/progression and planned Scenario migration
  with stable identities and legacy readability.
  Commit: `feat(authoring): add storyline and scenario authoring`
- `PMCP-053`: cinematic stage/timeline/preflight/preview and narrative parity
  gate across editor, API, and runtime.
  Commit: `feat(authoring): add cinematic authoring gate`

### Phase 5C — Game data and mechanics

- `PMCP-060`: generic catalogs, species/forms, learnsets/evolutions/media,
  explicit-network import preview, batch validation, and lossless round-trip.
  Commit: `feat(authoring): add pokemon catalog authoring`
- `PMCP-061`: moves/abilities/items and campaign trainers, encounters, shops,
  badges, characters, New Game, and runtime-support diagnostics.
  Commit: `feat(authoring): add campaign content authoring`
- `PMCP-062`: save inspection/migration/diff and sandbox-only party/PC/bag,
  shop/heal/PC service operations with production isolation.
  Commit: `feat(authoring): add sandbox player state authoring`
- `PMCP-063`: deterministic battle simulation, trace/outcome/write-back,
  progression decisions, rewards/capture, and runtime consumption proof.
  Commit: `feat(authoring): add battle progression authoring`

## Mechanics roadmap scope

Phase 5 consumes existing mechanics rather than silently closing unrelated
gameplay gaps. The relevant families are `FG-010–016`, `FG-020–030`,
`FG-040–053`, `FG-060–079`, `FG-080–094`, `FG-100–108`, `FG-120–129`, and
`FG-140–147`. Each lot Evidence Pack will state whether a touched FG item stays
`TODO`, `PARTIAL`, `BLOCKED`, or can merely be proposed `DONE`; this plan does
not edit the mechanics roadmap.

## Final phase validation

Run from each changed package, at minimum:

```bash
cd packages/map_authoring && dart test && dart analyze
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
```

Runtime smoke checks required by gameplay/battle changes:

```bash
cd packages/map_runtime && \
  flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && \
  flutter test test/phase_a_golden_slice_launch_test.dart
```

No roadmap status is changed without a separate explicit request. Every commit
must stage only its lot, pass `git diff --cached --check`, and leave unrelated
work untouched.
