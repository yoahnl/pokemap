# Showdown Battle Animations Progress

Date: `2026-04-23`
Branch/worktree: `feature/showdown-battle-animations-v1`

## Goal

Porter un système d'animations de combat inspiré directement de Pokemon Showdown vers `map_runtime`, sans recopier le moteur web/jQuery brut, en gardant:

- `map_battle` comme source de vérité métier
- `BattleTurnResult.timeline` comme source de vérité narrative
- `map_runtime` comme couche de planification, résolution visuelle, exécution Flame et publication Flutter

## What Was Implemented

### Runtime animation infrastructure

- Added a canonical FX catalog in `packages/map_runtime/lib/src/presentation/flame/battle_fx_catalog.dart`
- Added a package-asset FX cache in `packages/map_runtime/lib/src/presentation/flame/battle_fx_bundle_cache.dart`
- Added move-to-recipe mapping in `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_catalog.dart`
- Added canonical resolution from `RuntimeMoveCatalog` in `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`
- Added a pure animation DSL in `packages/map_runtime/lib/src/presentation/flame/battle_animation_plan.dart`
- Added pure Showdown-inspired recipe composition in `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_recipe_library.dart`
- Added a timeline-first planner in `packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart`
- Added a runtime animation runner in `packages/map_runtime/lib/src/presentation/flame/battle_animation_runner.dart`
- Added Flame FX execution layers in `packages/map_runtime/lib/src/presentation/flame/battle_fx_layer_component.dart` and `packages/map_runtime/lib/src/presentation/flame/battle_fx_sprite_component.dart`
- Extended battler presentation motions in `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`

### Overlay / Flutter-first integration

- Extended the shared battle presentation state carried by `BattleOverlayComponent`
- Reworked the battle overlay so animation planning and execution run from the new pipeline instead of the old damage-only path
- Kept `battle_turn_presentation.dart` as compatibility/fallback while migrating the main path
- Added Flutter HUD tween support in `packages/map_runtime/lib/src/presentation/flutter/battle_command_overlay_snapshot.dart`
- Made `packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart` animate HP locally from snapshot tween fields
- Preserved synchronized behavior between Flame scene animation and Flutter command overlay state

### Switch / narrative fixes

- Removed the old structural hole where visible-combatant changes could silently skip presentation
- Added explicit switch choreography handling through the new planner/runner pipeline
- Kept object-heal / HP tween presentation alive in the new model

## Custom Direct Move Recipes Added

### Core v1 groundwork

- `tackle`
- `scratch`
- `quickattack`
- `aerialace`
- `closecombat`
- `thunderbolt`
- `chargebeam`
- `shadowball`
- `darkpulse`
- `aurasphere`
- `bubblebeam`
- `fireblast`
- `blizzard`
- `dazzlinggleam`
- `calmmind`
- `swordsdance`
- `agility`
- `bulkup`
- `charm`
- `confuseray`
- `growl`
- `thunderwave`
- `protect`
- `reflect`
- `lightscreen`
- `mist`
- `auroraveil`
- `safeguard`
- `quickguard`
- `wideguard`
- `tailwind`
- `raindance`
- `sandstorm`
- `trickroom`
- `stealthrock`
- `spikes`

### Fast contact / impact families

- `aquajet`
- `extremespeed`
- `machpunch`
- `doublekick`
- `dualwingbeat`
- `bonemerang`
- `spark`
- `wildcharge`
- `flareblitz`
- `accelerock`
- `wickedblow`
- `doublehit`

### Physical / slash / claw / bite / heavy strike families

- `crunch`
- `poisonjab`
- `nightslash`
- `gigaimpact`
- `powerwhip`
- `crabhammer`
- `smartstrike`
- `megahorn`
- `dragonclaw`
- `psychocut`
- `playrough`
- `leafblade`
- `xscissor`
- `firefang`
- `icefang`
- `thunderfang`

### Projectile / beam / pulse / field pressure families

- `flamethrower`
- `icebeam`
- `psychic`
- `moonblast`
- `earthquake`
- `energyball`
- `rockslide`
- `discharge`
- `waterpulse`
- `powergem`
- `heatwave`
- `muddywater`
- `earthpower`
- `bugbuzz`
- `surf`
- `hydropump`
- `airslash`
- `dracometeor`

### Utility / sound / status exchange / pressure families

- `hypervoice`
- `flashcannon`
- `dragonpulse`
- `sludgebomb`
- `magicalleaf`
- `electroweb`
- `bulletseed`
- `slam`
- `spore`
- `painsplit`
- `skillswap`

### Guard / psychic / ghost / heal extension wave

- `burningbulwark`
- `banefulbunker`
- `storedpower`
- `psychoboost`
- `psyshock`
- `hex`
- `willowisp`
- `lifedew`

### Impact / kick / chop / projectile extension wave

- `bodyslam`
- `highjumpkick`
- `karatechop`
- `drillrun`
- `gunkshot`
- `mudshot`
- `electroball`
- `rockblast`

### Sweeping wave / storm / beam extension wave

- `whirlwind`
- `freezedry`
- `magmastorm`
- `originpulse`
- `psybeam`
- `aeroblast`
- `roaroftime`
- `revelationdance`

### Recovery / restoration extension wave

- `aromatherapy`
- `rest`
- `ingrain`
- `morningsun`
- `shoreup`

### Drain / siphon / life-steal extension wave

- `absorb`
- `megadrain`
- `gigadrain`
- `leechlife`
- `hornleech`
- `paraboliccharge`
- `drainingkiss`
- `oblivionwing`
- `leechseed`

### Beam / cannon / star / meteor extension wave

- `hyperbeam`
- `signalbeam`
- `fleurcannon`
- `armorcannon`
- `steelbeam`
- `beakblast`
- `twinbeam`
- `spikecannon`
- `terastarstorm`
- `meteormash`

### Punch / kick burst extension wave

- `shadowpunch`
- `focuspunch`
- `drainpunch`
- `dynamicpunch`
- `cometpunch`
- `megapunch`
- `poweruppunch`
- `dizzypunch`
- `jetpunch`
- `firepunch`
- `icepunch`
- `thunderpunch`
- `blazekick`
- `thunderouskick`
- `tropkick`

### Poison / toxic control extension wave

- `toxic`
- `toxicspikes`
- `poisongas`
- `smog`
- `clearsmog`
- `poisonfang`
- `crosspoison`
- `direclaw`

### Dance / flight / spin / storm / burst families

- `quiverdance`
- `victorydance`
- `dragondance`
- `featherdance`
- `focusblast`
- `uturn`
- `rapidspin`
- `gyroball`
- `flipturn`
- `mortalspin`
- `icespinner`
- `voltswitch`
- `shockwave`
- `explosion`
- `populationbomb`
- `aircutter`
- `hurricane`

### Weather / terrain / support / beam / lightning families

- `sunnyday`
- `hail`
- `electricterrain`
- `grassyterrain`
- `mistyterrain`
- `followme`
- `kinesis`
- `solarbeam`
- `thunder`

### Signature / delayed projectile extension wave

- `doomdesire`
- `seedflare`
- `icywind`
- `weatherball`
- `scald`
- `triattack`
- `clangingscales`
- `flameburst`
- `steameruption`
- `watersport`

### Additional direct Showdown coverage routed to seeded custom families

- `bravebird`
- `acrobatics`
- `flyingpress`
- `steelwing`
- `wingattack`
- `fly`
- `skyattack`
- `dragonbreath`
- `snowscape`
- `chillyreception`
- `magicroom`
- `wonderroom`
- `afteryou`
- `babydolleyes`
- `faketears`
- `tearfullook`
- `foresight`
- `sketch`
- `doodle`
- `odorsleuth`
- `playnice`
- `tailwhip`
- `leer`
- `snatch`
- `junglehealing`
- `technoblast`
- `flail`
- `facade`
- `furyattack`
- `flamecharge`
- `leafstorm`
- `zapcannon`
- `sludgewave`
- `meteorbeam`
- `detect`
- `kingsshield`
- `spikyshield`
- `endure`
- `magiccoat`
- `craftyshield`
- `matblock`
- `powertrip`
- `psychicnoise`
- `prismaticlaser`
- `psystrike`
- `nightshade`
- `ominouswind`
- `blackholeeclipse`
- `neverendingnightmare`
- `moongeistbeam`
- `astralbarrage`
- `soulstealing7starstrike`
- `healpulse`
- `aquaring`
- `softboiled`
- `moonlight`
- `lunarblessing`
- `revivalblessing`
- `recover`
- `roost`
- `healorder`
- `healbell`
- `refresh`
- `swallow`
- `milkdrink`
- `strengthsap`
- `blastburn`
- `chloroblast`
- `simplebeam`
- `magnetbomb`
- `maxstarfall`
- `focusenergy`
- `harden`
- `defensecurl`
- `irondefense`
- `cottonguard`
- `defendorder`
- `barrier`
- `howl`
- `meditate`
- `sharpen`
- `charge`
- `luckychant`
- `rockpolish`
- `autotomize`
- `shiftgear`
- `magnetrise`
- `minimize`
- `growth`
- `tailglow`
- `cosmicpower`
- `geomancy`
- `flowershield`
- `laserfocus`
- `honeclaws`
- `chargeup`
- `gearup`
- `heavyslam`
- `bodypress`
- `dragonhammer`
- `jumpkick`
- `lowkick`
- `circlethrow`
- `axekick`
- `megakick`
- `forcepalm`
- `brickbreak`
- `throatchop`
- `stormthrow`
- `vitalthrow`
- `hyperdrill`
- `sludge`
- `acid`
- `acidspray`
- `belch`
- `venomdrench`
- `mudbomb`
- `mudslap`
- `thundershock`
- `smackdown`
- `gust`
- `silverwind`
- `twister`
- `frostbreath`
- `glaciate`
- `fierydance`
- `inferno`
- `hydrovortex`
- `maxgeyser`
- `gmaxcannonade`
- `gmaxhydrosnipe`
- `psywave`
- `expandingforce`
- `terablastflying`
- `eternabeam`
- `pollenpuff`

### Direct recipe count

- Direct recipe mappings: `637`
- Direct custom recipes: `637`
- Remaining direct non-custom mappings: `0`

### Latest fidelity pass

The latest polish wave promoted the last two direct generic holdouts into
dedicated Showdown-style recipes and tightened two bespoke outliers:

- `slash` now uses a dedicated fast-dash `slashattack`-style cut instead of the generic slash fallback
- `hiddenpower` now radiates eight attacker-side `electroball` bursts like the Showdown source pattern
- `watershuriken` now mixes three attacker-side `waterwisp` blooms with three `icicle` volleys into the target lane
- `present` now keeps the single linear `iceball` projectile shape with the longer Showdown-like travel time and no extra target flash
- `payday` now keeps the six-hit `electroball` fan with tighter Showdown-like stagger timing

### Roots wave

The current roots wave expanded into three large fidelity catch-up passes:

- a first pass over `status / sound / contact / trap` roots that were best served by existing custom families
- a second pass over `setup / signature / terrain / launcher` roots
- a third pass over `signature finishers / torques / Z-move-style variants`

The result is that the catalogue now covers the full tracked Showdown move-animation source graph with direct + alias paths, after a last bespoke wave for the remaining outliers.

## Showdown Alias Coverage Added

### Existing alias batches wired during the port

- `bubble -> bubblebeam`
- `sparklingaria -> bubble`
- `electrify -> thunderwave`
- `nightdaze -> darkpulse`
- `comeuppance -> darkpulse`
- `retaliate -> closecombat`
- `superpower -> closecombat`
- `submission -> closecombat`
- `fairywind -> dazzlinggleam`
- `strangesteam -> dazzlinggleam`
- `meteorassault -> aurasphere`
- `workup -> bulkup`
- `tidyup -> workup`
- `coaching -> workup`
- `filletaway -> workup`
- `waterfall -> aquajet`
- `surgingstrikes -> aquajet`
- `bulletpunch -> machpunch`
- `rollingkick -> doublekick`
- `triplekick -> doublekick`
- `suckerpunch -> quickattack`
- `astonish -> quickattack`
- `rollout -> quickattack`
- `boltbeak -> spark`
- `volttackle -> wildcharge`
- `zingzap -> wildcharge`
- `doubleshock -> wildcharge`
- `heatcrash -> flareblitz`
- `darkestlariat -> flareblitz`
- `nuzzle -> spark`
- `doubleslap -> doublehit`
- `dualchop -> doublehit`
- `lashout -> nightslash`
- `ceaselessedge -> nightslash`
- `kowtowcleave -> nightslash`
- `jawlock -> crunch`
- `mysticalfire -> flamethrower`
- `firepledge -> flamethrower`
- `ember -> flamethrower`
- `incinerate -> flamethrower`
- `aurorabeam -> icebeam`
- `appleacid -> energyball`
- `gravapple -> energyball`
- `poisonsting -> poisonjab`
- `poisontail -> poisonjab`
- `shellsidearmphysical -> poisonjab`
- `magnitude -> earthquake`
- `fissure -> earthquake`
- `landswrath -> earthquake`
- `rocktomb -> rockslide`
- `headsmash -> gigaimpact`
- `headcharge -> gigaimpact`
- `takedown -> gigaimpact`
- `dragonrush -> gigaimpact`
- `lastresort -> gigaimpact`
- `horndrill -> gigaimpact`
- `trumpcard -> gigaimpact`
- `doubleedge -> gigaimpact`
- `breakneckblitz -> gigaimpact`
- `ragingbull -> gigaimpact`
- `vinewhip -> powerwhip`
- `grassyglide -> powerwhip`
- `trailblaze -> powerwhip`
- `branchpoke -> vinewhip`
- `aquatail -> crabhammer`
- `liquidation -> crabhammer`
- `aurawheel -> discharge`
- `overdrive -> discharge`
- `risingvoltage -> discharge`
- `behemothblade -> smartstrike`
- `behemothbash -> smartstrike`
- `hornattack -> megahorn`
- `lunge -> megahorn`
- `skittersmack -> megahorn`
- `breakingswipe -> dragonclaw`
- `psyblade -> psychocut`
- `chillingwater -> waterpulse`
- `snipeshot -> waterpulse`
- `mountaingale -> powergem`
- `terablastrock -> powergem`
- `burningjealousy -> heatwave`
- `paleowave -> muddywater`
- `scorchingsands -> earthpower`
- `terablastground -> earthpower`
- `terablastbug -> bugbuzz`
- `extrasensory -> psychic`
- `confusion -> psychic`
- `shatteredpsyche -> psychic`
- `maximumpsybreaker -> psychic`

### New alias batch added in the latest wave

- `hydrocannon -> hydropump`
- `terablastwater -> hydropump`
- `razorwind -> airslash`
- `terablaststellar -> dracometeor`

### New alias batch added in the current wave

- `chatter -> hypervoice`
- `echoedvoice -> hypervoice`
- `relicsong -> hypervoice`
- `uproar -> hypervoice`
- `mirrorshot -> flashcannon`
- `mirrorcoat -> flashcannon`
- `metalburst -> flashcannon`
- `terablaststeel -> flashcannon`
- `devastatingdrake -> dragonpulse`
- `dynamaxcannon -> dragonpulse`
- `terablastdragon -> dragonpulse`
- `venoshock -> sludgebomb`
- `shellsidearmspecial -> sludgebomb`
- `terablastpoison -> sludgebomb`
- `razorleaf -> magicalleaf`
- `grasspledge -> magicalleaf`
- `drumbeating -> magicalleaf`
- `snaptrap -> magicalleaf`
- `spiderweb -> electroweb`
- `stringshot -> electroweb`
- `toxicthread -> electroweb`
- `savagespinout -> electroweb`
- `pinmissile -> bulletseed`
- `attackorder -> bulletseed`
- `fellstinger -> bulletseed`
- `strugglebug -> bulletseed`
- `infestation -> bulletseed`
- `beatup -> slam`
- `counter -> slam`
- `payback -> slam`
- `revenge -> slam`
- `rockclimb -> slam`
- `sleeppowder -> spore`
- `poisonpowder -> spore`
- `stunspore -> spore`
- `powder -> spore`
- `cottonspore -> spore`
- `magicpowder -> spore`
- `decorate -> spore`
- `psychoshift -> painsplit`
- `helpinghand -> painsplit`
- `entrainment -> painsplit`
- `roleplay -> painsplit`
- `psychup -> painsplit`
- `destinybond -> painsplit`
- `reflecttype -> painsplit`
- `guardsplit -> skillswap`
- `powersplit -> skillswap`
- `guardswap -> skillswap`
- `heartswap -> skillswap`
- `powerswap -> skillswap`
- `speedswap -> skillswap`
- `courtchange -> skillswap`
- `powershift -> skillswap`

### New alias batch added in the newest wave

- `selfdestruct -> explosion`
- `mindblown -> explosion`
- `mistyexplosion -> explosion`
- `drillpeck -> bravebird`
- `peck -> bravebird`
- `pluck -> bravebird`
- `bleakwindstorm -> hurricane`
- `dragonenergy -> dragonbreath`

### New alias batch added in the current wave

- `gmaxfinale -> maxstarfall`
- `gmaxsmite -> maxstarfall`

### New alias batch added in the poison / toxic control wave

- `gastroacid -> toxic`
- `corrosivegas -> poisongas`

### New alias batch added in the signature / delayed projectile wave

- `futuresight -> doomdesire`
- `powdersnow -> icywind`
- `purify -> weatherball`
- `10000000voltthunderbolt -> triattack`
- `dragondarts -> dragonbreath`
- `pyroball -> flameburst`
- `scaleshot -> clangingscales`
- `terablast -> scald`
- `terablastgrass -> seedflare`
- `hydrosteam -> steameruption`
- `watergun -> watersport`

### New alias batch added in the punch / kick burst wave

- `wringout -> forcepalm`

### Alias count

- Alias mappings: `300`

## Coverage Snapshot

- Showdown unique move ids in `battle-animations-moves.ts`: `932`
- Moves covered by a real custom animation path in our runtime: `932`
- Coverage: `100.0%`
- Remaining to reach Showdown move-animation parity: `0`
- Direct Showdown source ids left uncovered once direct + alias catalog paths are counted: `0`
- Final bespoke parity wave added dedicated or adapted custom recipes for:
  - `splash`
  - `celebrate`
  - `orderup`
  - `heartstamp`
  - `matchagotcha`
  - `present`
  - `payday`
- Follow-up fidelity wave promoted or tightened:
  - `slash`
  - `hiddenpower`
  - `watershuriken`
  - `present`
  - `payday`
- Utility fidelity support wave promoted stand-in routings to bespoke recipes for:
  - `taunt`
  - `instruct`
  - `quash`
  - `swagger`
  - `encore`
  - `babydolleyes`
- Order Up fidelity pass now uses a real Tatsugiri sprite asset through the shared FX catalog and mirrors the Showdown `rise -> hold` silhouette instead of the old shell placeholder
- Timing/staging fidelity seam added:
  - `SpawnFxStep` now supports `startDelaySeconds` and `playAsAccent` for staggered accent volleys without blocking the whole phase
  - `doomdesire` now matches a cleaner double dark-screen pulse instead of the older pseudo-charge approximation
  - `painsplit` now stages its wisp exchange in two beats instead of a flat simultaneous burst
  - `skillswap` now uses staggered cross-lane accent wisps with under/over arcs
  - `matchagotcha` now opens with a denser delayed energyball volley before the drain bloom
  - `BattleOverlayComponent` now guards async prewarm / visual-sync work with a presentation generation token so an older turn cannot overwrite a newer one
  - `BattleAnimationRunner` now consumes leftover frame time across consecutive phases instead of stretching animations after a long frame spike

## Important Files Touched

### Flame / runtime

- `packages/map_runtime/assets/fx/tatsugiri.png`
- `packages/map_runtime/lib/src/presentation/flame/battle_fx_catalog.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_fx_bundle_cache.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_catalog.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_animation_plan.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_recipe_library.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_fx_layer_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_fx_sprite_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_animation_runner.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart`

### Flutter overlay / HUD

- `packages/map_runtime/lib/src/presentation/flutter/battle_command_overlay_snapshot.dart`
- `packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart`

### Tests

- `packages/map_runtime/test/battle_fx_catalog_test.dart`
- `packages/map_runtime/test/battle_fx_bundle_cache_test.dart`
- `packages/map_runtime/test/battle_move_visual_catalog_test.dart`
- `packages/map_runtime/test/battle_move_visual_resolver_test.dart`
- `packages/map_runtime/test/battle_animation_plan_test.dart`
- `packages/map_runtime/test/battle_move_visual_recipe_library_test.dart`
- `packages/map_runtime/test/battle_move_visual_seeded_recipes_test.dart`
- `packages/map_runtime/test/battle_turn_animation_planner_test.dart`
- `packages/map_runtime/test/battle_animation_runner_test.dart`
- `packages/map_runtime/test/battle_fx_layer_component_test.dart`
- `packages/map_runtime/test/battle_scene_combatant_component_animation_test.dart`
- `packages/map_runtime/test/battle_turn_presentation_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/battle_mobile_command_overlay_test.dart`

## Verification

The intended verification path for this branch is:

```bash
cd packages/map_runtime
flutter test \
  test/battle_mobile_command_overlay_test.dart \
  test/battle_fx_catalog_test.dart \
  test/battle_fx_bundle_cache_test.dart \
  test/battle_move_visual_catalog_test.dart \
  test/battle_move_visual_resolver_test.dart \
  test/battle_animation_plan_test.dart \
  test/battle_move_visual_recipe_library_test.dart \
  test/battle_move_visual_seeded_recipes_test.dart \
  test/battle_turn_animation_planner_test.dart \
  test/battle_turn_presentation_test.dart \
  test/battle_animation_runner_test.dart \
  test/battle_fx_layer_component_test.dart \
  test/battle_scene_combatant_component_animation_test.dart \
  test/battle_overlay_component_test.dart
```

## Remaining High-Value Gaps

- Deeper fidelity for several utility/status moves that now have dedicated local recipes but are still intentionally native-Flame approximations
- More exact timing / staging parity for Showdown signatures that are represented by the right family but not yet by a pixel-perfect 1:1 sequence
- Visual tuning and polish passes now that the catalogue gap is closed at `932 / 932`
