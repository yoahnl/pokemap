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
