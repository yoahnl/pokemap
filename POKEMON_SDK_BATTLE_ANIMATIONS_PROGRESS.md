# Pokemon SDK Battle Animations Progress

## Status

This branch hard-resets the battle animation runtime from the old Showdown FX
folder to a Pokemon SDK-inspired asset and recipe pipeline.

- Branch: `feature/pokemon-sdk-battle-animations-reset`
- Source assets: `/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/graphics/animations`
- Runtime destination: `packages/map_runtime/assets/battle_animations/`
- Imported PNGs: `180`
- Catalog entries: `235` including compatibility aliases that now point to SDK assets
- Direct move visual routes: `663`
- RMXP animation specs generated from SDK data: `874`
- RMXP move mappings: `652` target entries (`615` non-null), `243` user entries, `672` unique moves with at least one exact RMXP animation
- Visual source report: `952` unique normalized SDK/runtime move ids, `18` exact Ruby verified routes, `654` exact RMXP verified routes, `90` adapted routes, `190` SDK-family fallback routes, `0` needs-retune routes
- RMXP placement audit: `230` exact RMXP `position == 3` phases, `220` `sdkStage`, `5` `projectileLine`, `1` `targetImpact`, `4` `attackerCast`, `9` critical anchors verified, `0` critical placement reviews
- Legacy runtime FX folder: `packages/map_runtime/assets/fx/` removed from runtime asset loading

## Implemented

- Added `packages/map_runtime/tool/import_pokemon_sdk_battle_animations.py`.
- Added `packages/map_runtime/tool/import_pokemon_sdk_rmxp_animations.py`.
- Added `packages/map_runtime/tool/battle_animation_visual_source_report.dart`.
- Added generated RMXP catalog:
  - `BattleSdkRmxpAnimationCatalog`
  - `BattleSdkMoveIdCatalog`
  - `RmxpAnimationSpec`
  - `RmxpAnimationFrameSpec`
  - `RmxpAnimationCellSpec`
  - `RmxpAnimationTimingSpec`
- Replaced `BattleFxCatalog` with typed SDK asset metadata:
  - `singleImage`
  - `spriteSheet`
  - `statusSheet`
  - `weatherParticle`
- Added sprite-sheet metadata fields:
  - `frameWidth`
  - `frameHeight`
  - `frameCount`
  - `columns`
  - `rows`
  - `originX`
  - `originY`
  - `defaultScale`
- Changed `packages/map_runtime/pubspec.yaml` to declare `assets/battle_animations/`.
- Added SDK presentation steps:
  - `AnimationGroupStep`
  - `PlaySpriteSheetFxStep`
  - `SpriteSheetOnCombatantStep`
  - `PlaySdkParticleSequenceStep`
  - `ParticleBurstStep`
  - `WeatherParticleStep`
  - `SceneTintStep`
  - `CombatantToneStep`
  - `CombatantCompressStep`
  - `CombatantEllipseStep`
  - `CameraFocusStep`
  - `BattleCameraMoveStep`
  - `BattleCameraResetStep`
  - `PlayRmxpAnimationStep`
  - `SdkFallingParticlesStep`
  - `SdkRadiusParticleStep`
  - `SdkScalarParticleStep`
  - `SdkParticleZoomStep`
- Added explicit SDK frame sequencing and per-frame durations for sprite sheets.
- Added `BattleFxSpriteSheetComponent` for frame-by-frame Flame playback.
- Added `BattleRmxpAnimationComponent` for RPG Maker XP animation playback:
  - 192x192 cells
  - 5-column sheet pattern decoding
  - 0.05s frame cadence
  - opacity, angle, mirror and blend type support
  - cell `15` combatant transform support with cleanup
  - Pokémon/scene flash timing hooks
- Extended `BattleFxLayerComponent` to play:
  - regular sprite FX
  - sprite sheets
  - combatant-anchored sprite sheets
  - per-particle SDK sequences with individual delay, offset, scale X/Y, opacity, rotation and tint
  - particle bursts
  - tinted particles
  - weather particles
  - scene tint/screen flash
- Extended `BattleFxLayerComponent` with SDK pattern primitives for falling particles, radius particles, scalar particles, and particle zoom.
- Added `BattleCameraRig` as a presentation-only combat scene camera with focus, move, center, reset, and cancel-safe cleanup.
- Extended `BattleAnimationRunner` and `BattleOverlayComponent` so SDK steps are executed in the real battle overlay.
- Reworked `BattleAnimationRunner` group scheduling so nested `sequence` groups dispatch children over time instead of firing every child immediately.
- Kept `BattleMoveVisualResolver` as the public entry point, but active recipe IDs now use SDK naming.
- The canonical `PokemonMoveSourceRefs.showdownMoveId` field is still read because it is the existing canonical move-id contract, but it now resolves in this order: exact Ruby override, exact RMXP mapping, SDK family fallback, semantic fallback.

## Status Categories

### Exact SDK

These recipes are the strictest ports in the current branch. They now preserve the important SDK playback semantics we can support today: source sheet metadata, explicit frame order, per-frame timing where needed, target/user anchoring, user ellipse, target compression, tone/tint, parallel FX groups, and cleanup.

Current status label: `exact Ruby verified` for the 18 Ruby-scripted moves below.

The following moves now resolve to exact SDK recipe IDs and use imported SDK sheet/particle assets where available:

- `acidarmor` -> `sdkExactAcidArmor`
- `acrobatics` -> `sdkExactAcrobatics`
- `aerialace` -> `sdkExactAerialAce`
- `airslash` -> `sdkExactAirSlash`
- `aquaring` -> `sdkExactAquaRing`
- `aquatail` -> `sdkExactAquaTail`
- `assurance` -> `sdkExactAssurance`
- `astonish` -> `sdkExactAstonish`
- `avalanche` -> `sdkExactAvalanche`
- `karatechop` -> `sdkExactKarateChop`
- `leechseed` -> `sdkExactLeechSeed`
- `poisonpowder` -> `sdkExactPoisonPowder`
- `recover` -> `sdkExactRecover`
- `sleeppowder` -> `sdkExactSleepPowder`
- `stunspore` -> `sdkExactStunSpore`
- `tailwhip` -> `sdkExactTailWhip`
- `thunderwave` -> `sdkExactThunderWave`
- `vinewhip` -> `sdkExactVineWhip`

### Exact RMXP

These moves use Pokémon SDK RPG Maker animation data instead of invented SDK-family recipes. The runtime generates a static Dart snapshot from:

Current status label: `exact RMXP verified` for mapped moves that resolve through the generated RMXP catalog.

- `/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/Data/Animations.rxdata.yml`
- `/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/Data/PSP_MTAU.dat`
- `/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/Data/PSP_MTAT.dat`
- `/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/Data/Studio/moves`

Current coverage:

- `874` RMXP animations are available.
- `672` unique SDK move ids have at least one exact RMXP user/target animation.
- `swift` is now exact RMXP: move id `129`, target animation `129`, `F/METEORE`, sheet `025_support02`.
- `thundershock` is now exact RMXP: move id `84`, target animation `84`, `N/ECLAIR`, sheet `017_thunder01`.
- `shockwave` is now exact RMXP: move id `351`, user animation `351`, target animation `351`.
- `electroball` is now exact RMXP: move id `486`, target animation `676`.

### SDK Family

These moves remain family/adapted only when no exact Ruby override and no exact RMXP mapping exists, or when the current runtime intentionally keeps a native presentation:

Current status label: `SDK family fallback`.

- Native barrier overlays still cover `protect`, guard/screen-style moves, and similar effects.
- Semantic fallbacks still cover custom/local moves that are absent from SDK move data.
- Older bespoke SDK-family recipes remain as fallback art direction, not as claims of exact parity.

### Adapted

These are deliberate runtime adaptations where SDK has a broader Ruby/viewport/audio system than the current Flutter/Flame battle scene:

Current status label: `adapted` for SDK-local moves where the local SDK data does not provide a Ruby/RMXP animation path.

- `needs visual retune` is currently `0`; known SDK-local moves without Ruby/RMXP playback are now classified as `adapted` instead of pretending to be exact.
- `10000000voltthunderbolt` now routes through `s10000000voltthunderbolt` and uses the adapted thunderbolt finisher route, not `triattack`.
- The `*2` Z-move numeric variants route to their adapted base visuals instead of falling through to missing visuals.
- Aliases that reuse an exact Ruby recipe no longer claim exact Ruby status unless their source move is one of the 18 Ruby-scripted moves; examples such as `electrify`, `razorwind`, and `synthesis` now keep their RMXP status.
- Aliases into adapted Z/Max/signature routes inherit the adapted status; examples include `maxlightning`, `maxphantasm`, `gmaxvinelash`, `gmaxdepletion`, `maxstrike`, and `poltergeist`.
- Native barrier overlays (`protect`, guard/screen-style moves) remain Flame-native instead of PNG-only effects.
- Weather and persistent ambience use runtime scene tint/particles rather than a full Ruby viewport stack.
- Camera focus is now a presentation-only battle-scene rig; it moves/zooms backdrop, battlers, and FX without moving the Flutter command UI, with reset on completion/cancel/resync. It is still not a full Ruby viewport clone.
- Audio `se_play` calls are documented by omission and remain out of scope for this pass.

## Current Parity Pass

- Added `BattleMoveVisualSource.adapted` for honest SDK-local-but-not-exact routes.
- Added an explicit `adaptedSDKMoveIds` set covering the 37 SDK Studio ids without RMXP playback, the 19 numeric Z-retunes, and the 10M Volt Thunderbolt compatibility route.
- Added an explicit `exactRubySDKMoveIds` set so only the 18 Ruby script source moves can report `exact Ruby verified`.
- Fixed the visual report so it counts unique normalized move ids, reports duplicate aliases separately, and no longer inflates exact Ruby counts with underscore aliases such as `aqua_tail`, `thunder_wave`, and `vine_whip`.
- Fixed the visual report and resolver so alias targets propagate adapted status, while aliases into Ruby recipes do not overclaim exactness.
- Moved `aciddownpour2`, `alloutpummeling2`, `blackholeeclipse2`, `bloomdoom2`, `breakneckblitz2`, `continentalcrush2`, `corkscrewcrash2`, `devastatingdrake2`, `gigavolthavoc2`, `hydrovortex2`, `infernooverdrive2`, `neverendingnightmare2`, `savagespinout2`, `shatteredpsyche2`, `subzeroslammer2`, `supersonicskystrike2`, `tectonicrage2`, `twinkletackle2`, and `s10000000voltthunderbolt` out of `needs visual retune`.
- Added RMXP hue rendering via an RGSS-like hue color matrix, wired into `BattleRmxpAnimationComponent`.
- Hardened RMXP flash timing handling so Pokémon/scene flashes and hide/show timing restore visual state after completion.
- Corrected RMXP reverse-coordinate playback so enemy-side `position == 3` screen animations mirror both axes like `RPG::Sprite.animation_set_sprites`; `watergun` now keeps SDK move id `55` and travels down-left when reversed instead of visually firing from the wrong side.
- Mapped RMXP `blendType: 2` to alpha-safe normal composition for now instead of Flutter `BlendMode.modulate`, preventing the black 192x192 cell artifact seen on `megapunch`; a custom subtract shader remains the future pixel-perfect path.
- Added targeted regressions proving `watergun` and `megapunch` stay exact RMXP routes with their SDK animation ids.
- Bounded RMXP screen-position playback to the combat viewport above the command panel. This fixes effects such as `megapunch` rendering near the bottom UI because `RPG::Sprite` screen coordinates were previously scaled against the full overlay height.
- Retired the broad RMXP `position == 3` reprojection rule. Only explicitly audited projectile policies now use attacker -> defender mapping; all other `position == 3` phases fall back to SDK stage space unless reviewed.
- Added SDK primitive particle steps for the Ruby patterns that were still too generic:
  - `SdkFallingParticlesStep`
  - `SdkRadiusParticleStep`
  - `SdkScalarParticleStep`
  - `SdkParticleZoomStep`
- Reworked `leechseed` again so seed jets use scalar SDK particles and seed growth uses the zoom primitive inside a parallel group.
- Reworked `poisonpowder`, `sleeppowder`, and `stunspore` to use the falling-particle primitive instead of a hand-built particle sequence.
- Reworked `recover` to use radius/zoom primitives around `circle_blurry_m_2` and `star_4_ring_l`.
- Reworked `karatechop` to use scalar hand motion, target compression, and falling impact particles.
- Replaced the earlier SDK-lite camera fields with `BattleCameraRig`, including explicit camera move/reset steps.
- Added the visual source reporting tool and surfaced current exact/fallback/retune counters.
- Added an explicit RMXP placement model so `PlayRmxpAnimationStep` now carries `RmxpPlacementSpec` instead of letting `BattleRmxpAnimationComponent` guess how to place an animation.
- Added `RmxpMovePlacementCatalog` with audited policies for critical attacks:
  - `megapunch` -> `targetImpact`
  - `swift`, `dragonbreath`, `watergun`, `stringshot`, `electroball` -> `projectileLine`
  - `thundershock`, `thunderbolt`, `shockwave` -> `targetImpact`
- Reworked RMXP playback around placement policies:
  - `sdkStage` preserves SDK viewport/stage coordinates.
  - `targetImpact` anchors impact animations such as `megapunch` on the defender.
  - `projectileLine` is opt-in for real source -> target attacks such as `watergun`, `stringshot`, `dragonbreath`, and `swift`.
  - user phases default to `attackerCast`.
- Extended `BattleVisualAnchor` with semantic anchors for body, mouth, hand, foot, defender impact, and stage top/center/bottom.
- Made battle visual anchors camera-neutral: newly spawned FX resolve against unshifted battler/stage coordinates, then the battle camera transforms the whole scene once.
- Fixed combatant sprite-sheet FX so enemy/user-side animations no longer force a fake `player -> enemy` context.
- Extended the visual source report with RMXP placement counts, critical-anchor verification, and a `needs placement review` guard for critical moves.
- Fixed sprite-sheet playback so SDK recipes can repeat arbitrary source frames instead of relying on naive sequential `row = frame ~/ columns` playback.
- Corrected SDK catalogue metadata for repeated-frame sheets:
  - `acid_armor`: 4 source frames, recipe sequence `[0, 1, 2, 3, 0, 1, 2, 3]`.
  - `aqua_ring`: 3 source frames, recipe sequence `[0, 1, 2, 0, 1, 2, 0, 1, 2]`.
  - `thunder_02`: 10 source frames laid out as 5 columns x 2 rows; `thunderwave` still plays `[1, 0]` repeated five times.
- Added SDK combatant primitives for tone, compression and ellipse motion.
- Reworked `tailwhip` to use the SDK-style user ellipse instead of a generic stat-down overlay.
- Reworked powder moves to use tinted `circle_blurry_m_2` particles plus target tone/compression.
- Reworked `recover` to use `circle_blurry_m_2` and `star_4_ring_l` instead of generic stars.
- Reworked `karatechop` toward the SDK falling-hand/compression/particle structure instead of a generic hit shake.
- Added `PlaySdkParticleSequenceStep` and `BattleSdkParticleComponent` so Ruby-exact recipes can describe individual SDK particles instead of falling back to one circular burst.
- Reworked `leechseed` so seed jets and growth run in a parallel group instead of the old serial "all seeds, wait, then growth" approximation.
- Reworked `poisonpowder`, `sleeppowder`, `stunspore`, `recover`, and `karatechop` so their critical particles no longer use `ParticleBurstStep`.
- Added a battle camera rig to `BattleOverlayComponent`; it applies temporary offset/zoom to backdrop, battlers, and FX only, then resets on completion/cancel/resync.
- Updated tests so `swift` and `thundershock` prove exact RMXP routing instead of corrected-but-generic SDK families.
- Added generated RMXP data so `swift`, `thundershock`, `shockwave`, and `electroball` now resolve to exact RMXP instead of SDK-family approximations.
- Added `PlayRmxpAnimationStep` and a Flame renderer for RMXP cells/timings.
- Added resolver state fields for exact RMXP metadata:
  - `sdkNumericMoveId`
  - `rmxpUserAnimationId`
  - `rmxpTargetAnimationId`
  - `visualSource`

## Parity Strategy

- Exact Ruby overrides always win over RMXP mappings.
- Exact RMXP mappings win over SDK-family recipes.
- SDK-family recipes now exist as fallback only when SDK has no RMXP animation for that move id.
- Old Showdown effect IDs such as `fireball`, `impact`, `shadowball`, `wisp`, and slash/bite aliases are preserved only as catalog aliases, and now point to SDK-imported PNGs under `assets/battle_animations/`.
- New active recipe IDs are SDK-oriented; tests assert no recipe enum starts with `showdown`.
- Raw barrier-style moves remain native Flame overlays instead of PNG lookups.

## Verification Added

- SDK catalog tests verify package keys, metadata, asset existence, and no runtime asset key points to `assets/fx/`.
- Bundle cache tests verify SDK package asset loading, prewarm de-duplication, cache reuse, and clear behavior.
- Animation plan tests verify SDK step asset aggregation.
- FX layer tests verify sprite FX, screen flashes, barriers, persistent ambience, tinted particles, explicit SDK frame sequences, and SDK sprite-sheet cleanup.
- FX layer tests verify per-particle SDK sequences, SDK falling/radius/scalar/zoom primitives, distinct particle delays, independent scale X/Y, tint, and cleanup.
- Recipe tests verify every required FX id exists in `BattleFxCatalog`, including new sprite-sheet and particle steps.
- Recipe tests verify `leechseed` uses a parallel jets/growth structure, powders use SDK falling particles, `recover` uses radius/zoom primitives, and `karatechop` uses scalar/falling primitives instead of generic bursts.
- Catalog tests verify the 18 exact SDK Ruby ports resolve to exact SDK recipes.
- Catalog tests verify declared sprite-sheet source rectangles stay inside PNG bounds.
- Runner tests verify sequence/parallel groups and the SDK combatant/camera primitives are dispatched.
- RMXP catalog tests verify the full `874` animation import, move mapping counts, sample ids, and asset presence.
- RMXP component tests verify frame cadence, 192px source rects, 5-column decoding, opacity, angle, mirror, blend type, active hue filtering, flash timing, and cell `15` cleanup.
- FX layer tests verify RMXP animations mount and are cleaned up after completion.
- Runner tests verify RMXP steps dispatch as accent phases and nested sequence groups dispatch children over time.
- Resolver/planner tests verify existing timeline, HP tween, switch, field, and fallback behavior still works.
- Overlay tests verify the battle camera moves the combat scene without moving the command panel and resets after the active plan.

## Known Gaps

- Audio calls from the Ruby scripts are documented by omission and not ported in this pass.
- The 18 exact scripts are manually adapted, not generated by a Ruby parser.
- RMXP hue now applies an RGSS-like color matrix, but full RPG Maker hue-shift rendering is not yet proven pixel-perfect.
- RMXP audio `se` metadata is parsed and preserved, but not played.
- Moves absent from SDK Studio/move data still route through semantic SDK-family fallbacks.
- `battle_move_visual_recipe_library.dart` is still physically large; the public facade is stable, but the exact/family recipe split remains a cleanup task.
- The old `SHOWDOWN_BATTLE_ANIMATIONS_PROGRESS.md` remains as an archive document only; runtime loading no longer uses `assets/fx/`.
