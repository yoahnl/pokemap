import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

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
      'la préchauffe demande les planches des capacités des deux camps '
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
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();

    await overlay.precacheBattleMoveEffects();

    expect(
      requestedAssetKeys.length,
      greaterThanOrEqualTo(2),
      reason: 'vine_whip, tackle et thunderbolt portent des animations de la '
          'référence : leurs planches sont demandées AVANT le premier coup',
    );
  });

  test(
      'la collecte des sons couvre les systèmes du tour et les timings des '
      'animations du combat', () async {
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
    );
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();

    final seNames = await overlay.collectBattleSeNames();

    expect(
      seNames,
      containsAll(<String>['hit', 'hitplus', 'hitlow', 'down', 'level_up']),
      reason: 'les impacts selon l’efficacité, le K.O. et le jingle de '
          'niveau sont toujours préchauffés',
    );
    expect(
      seNames.length,
      greaterThan(5),
      reason: 'les timings sonores des animations des capacités du combat '
          's’ajoutent aux sons système',
    );
  });
}
