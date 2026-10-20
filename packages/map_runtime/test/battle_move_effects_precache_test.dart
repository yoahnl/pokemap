import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_stat_aura_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

import 'support/load_flame_component.dart';

// BETA-BAT-018 : le premier usage d'une capacité décodait ses planches à la
// demande et gelait la scène ~3 s. La préchauffe se joue sous le noir de la
// pré-transition : les planches d'animation ET les sons des capacités des
// deux camps sont demandés aux caches AVANT le reveal.

const _stats = BattleStatsSnapshot(
  attack: 40,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

Future<ui.Image> _tinyImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  return recorder.endRecording().toImage(2, 2);
}

BattleSession _session() {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'sproutle',
        level: 10,
        maxHp: 30,
        currentHp: 30,
        stats: _stats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'vine_whip', name: 'Fouet Lianes', power: 45),
          BattleMoveData(id: 'tackle', name: 'Charge', power: 40),
        ],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'sparkitten',
        level: 6,
        maxHp: 21,
        currentHp: 21,
        stats: _stats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'thunderbolt', name: 'Tonnerre', power: 90),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'sequential stat auras reload their atlases within the resident budget',
    () async {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
      final budget = RuntimeResourceBudget();
      final cache = BattleFxBundleCache(resourceBudget: budget);
      final initial = _session();
      final overlay = BattleOverlayComponent(
        session: initial,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
        fxBundleCache: cache,
        resourceBudget: budget,
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      for (
        var tick = 0;
        tick < 2000 && overlay.debugStatSheetCount < 2;
        tick++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(overlay.debugStatSheetCount, 2);
      final world = await budget.acquire(
        residentBytes:
            budget.profile.maximumResidentBytes - budget.residentBytes - 65536,
      );
      world.commit();
      addTearDown(() {
        overlay.onRemove();
        cache.dispose();
        world.release();
        budget.dispose();
      });
      overlay.updateState(
        initial.applyChoice(const PlayerBattleChoiceFight(0)),
      );
      await overlay.waitForPendingVisualSync();
      expect(overlay.debugStatSheetCount, 0);
      Future<BattleStatAuraComponent> showAura(int amount) async {
        overlay.updateState(
          initial.withRuntimeDisplayState(
            currentTurn: BattleTurnResult(
              playerAction: const BattleActionNone(),
              enemyAction: const BattleActionNone(),
              executions: const [],
              timeline: [
                BattleTurnStatStageEvent(
                  side: BattleSideId.player,
                  stat: BattleStatId.attack,
                  amount: amount,
                  currentStage: amount,
                ),
              ],
            ),
          ),
        );
        await overlay.waitForPendingVisualSync();
        for (
          var tick = 0;
          tick < 2000 &&
              overlay.children.whereType<BattleStatAuraComponent>().isEmpty;
          tick++
        ) {
          overlay.updateTree(.025);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(
          overlay.children.whereType<BattleStatAuraComponent>(),
          isNotEmpty,
          reason: 'The $amount aura must render after its atlas was evicted',
        );
        return overlay.children.whereType<BattleStatAuraComponent>().single;
      }

      final up = await showAura(1);
      for (
        var tick = 0;
        tick < 300 &&
            overlay.children.whereType<BattleStatAuraComponent>().isNotEmpty;
        tick++
      ) {
        overlay.updateTree(.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(overlay.children.whereType<BattleStatAuraComponent>(), isEmpty);
      expect(up.sheet.debugDisposed, isFalse);
      final down = await showAura(-1);
      expect(up.sheet.debugDisposed, isTrue);
      expect(down.sheet.debugDisposed, isFalse);
      expect(
        budget.residentBytes,
        lessThanOrEqualTo(budget.profile.maximumResidentBytes),
      );
    },
  );

  for (final activeAura in [false, true]) {
    test(
      'unused warm stat atlases yield residency with activeAura=$activeAura',
      () async {
        await BattleSdkRmxpAnimationCatalog.ensureLoaded();
        final budget = RuntimeResourceBudget();
        final cache = BattleFxBundleCache(resourceBudget: budget);
        final initial = _session();
        final overlay = BattleOverlayComponent(
          session: initial,
          viewportSize: Vector2(960, 540),
          onPlayerChoice: (_) {},
          fxBundleCache: cache,
          resourceBudget: budget,
        );
        await loadFlameComponent(overlay);
        await overlay.waitForPendingVisualSync();
        for (
          var tick = 0;
          tick < 2000 && overlay.debugStatSheetCount < 2;
          tick++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(overlay.debugStatSheetCount, 2);
        ui.Image? activeSheet;
        if (activeAura) {
          overlay.updateState(
            initial.withRuntimeDisplayState(
              currentTurn: const BattleTurnResult(
                playerAction: BattleActionNone(),
                enemyAction: BattleActionNone(),
                executions: [],
                timeline: [
                  BattleTurnStatStageEvent(
                    side: BattleSideId.player,
                    stat: BattleStatId.attack,
                    amount: -1,
                    currentStage: -1,
                  ),
                ],
              ),
            ),
          );
          await overlay.waitForPendingVisualSync();
          for (
            var tick = 0;
            tick < 120 &&
                overlay.children.whereType<BattleStatAuraComponent>().isEmpty;
            tick++
          ) {
            overlay.updateTree(.05);
            await Future<void>.delayed(Duration.zero);
          }
          activeSheet = overlay.children
              .whereType<BattleStatAuraComponent>()
              .single
              .sheet;
          expect(activeSheet.debugDisposed, isFalse);
        }
        final world = await budget.acquire(
          residentBytes:
              budget.profile.maximumResidentBytes -
              budget.residentBytes -
              65536,
        );
        world.commit();
        addTearDown(() {
          overlay.onRemove();
          cache.dispose();
          world.release();
          budget.dispose();
        });
        overlay.updateState(
          initial.applyChoice(const PlayerBattleChoiceFight(0)),
        );
        await expectLater(overlay.waitForPendingVisualSync(), completes);
        expect(overlay.debugStatSheetCount, activeAura ? 1 : 0);
        if (activeSheet != null) expect(activeSheet.debugDisposed, isFalse);
        expect(
          budget.residentBytes,
          lessThanOrEqualTo(budget.profile.maximumResidentBytes),
        );
      },
    );
  }

  test(
    'obsolete prewarmed sheets cannot exhaust the next real turn budget',
    () async {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
      final initial = _session();
      final next = initial.applyChoice(const PlayerBattleChoiceFight(0));
      final catalog = RuntimeMoveCatalog.fromEntries(
        const <String, PokemonMove>{},
      );
      final plan = BattleTurnAnimationPlanner().build(
        previousSession: initial,
        newSession: next,
        moveCatalog: catalog,
        resolver: BattleMoveVisualResolver(catalog),
      );
      final required = {
        for (final id in plan.requiredFxIds)
          BattleFxCatalog.require(id).assetKey: BattleFxCatalog.require(id),
      };
      expect(required, isNotEmpty);
      final obsolete = ['nail_1', '022_darkness01']
          .map(BattleFxCatalog.require)
          .firstWhere((spec) => !required.containsKey(spec.assetKey));
      final requiredBytes = required.values.fold<int>(
        0,
        (total, spec) => total + spec.width * spec.height * 4,
      );
      final obsoleteBytes = obsolete.width * obsolete.height * 4;
      final budget = RuntimeResourceBudget();
      final cache = BattleFxBundleCache(resourceBudget: budget);
      final overlay = BattleOverlayComponent(
        session: initial,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
        fxBundleCache: cache,
        resourceBudget: budget,
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      for (
        var tick = 0;
        tick < 2000 && overlay.debugStatSheetCount < 2;
        tick++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(overlay.debugStatSheetCount, 2);
      final heldBytes =
          budget.profile.maximumResidentBytes -
          budget.residentBytes -
          math.max(requiredBytes, obsoleteBytes).toInt() -
          65536;
      expect(heldBytes, greaterThan(0));
      final world = await budget.acquire(residentBytes: heldBytes);
      world.commit();
      addTearDown(() {
        overlay.onRemove();
        cache.dispose();
        world.release();
        budget.dispose();
      });
      await cache.prewarm([obsolete.effectId]);
      overlay.updateState(next);
      await expectLater(overlay.waitForPendingVisualSync(), completes);
      expect(
        budget.residentBytes,
        lessThanOrEqualTo(budget.profile.maximumResidentBytes),
      );
    },
  );

  test('la préchauffe demande les planches des capacités des deux camps '
      'au cache, et un échec individuel reste silencieux', () async {
    final requestedAssetKeys = <String>[];
    final cache = BattleFxBundleCache(
      imageLoader: (assetKey) async {
        requestedAssetKeys.add(assetKey);
        if (requestedAssetKeys.length == 1) {
          throw StateError('première planche illisible — le filet tient');
        }
        return _tinyImage();
      },
    );
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
      fxBundleCache: cache,
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();

    await overlay.precacheBattleMoveEffects();

    expect(
      requestedAssetKeys.length,
      greaterThanOrEqualTo(2),
      reason:
          'vine_whip, tackle et thunderbolt portent des animations de la '
          'référence : leurs planches sont demandées AVANT le premier coup',
    );
  });

  test('la collecte des sons couvre les systèmes du tour et les timings des '
      'animations du combat', () async {
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();

    final seNames = await overlay.collectBattleSeNames();

    expect(
      seNames,
      containsAll(<String>['hit', 'hitplus', 'hitlow', 'down', 'level_up']),
      reason:
          'les impacts selon l’efficacité, le K.O. et le jingle de '
          'niveau sont toujours préchauffés',
    );
    expect(
      seNames.length,
      greaterThan(5),
      reason:
          'les timings sonores des animations des capacités du combat '
          's’ajoutent aux sons système',
    );
  });
}
