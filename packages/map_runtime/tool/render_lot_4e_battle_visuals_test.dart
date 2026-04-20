// ignore_for_file: invalid_use_of_visible_for_testing_member, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';

BattleStatsSnapshot _stats() {
  return const BattleStatsSnapshot(
    attack: 48,
    defense: 43,
    specialAttack: 52,
    specialDefense: 45,
    speed: 65,
  );
}

BattleMoveData _move({
  required String id,
  required String name,
  String type = 'normal',
  BattleMoveCategory category = BattleMoveCategory.physical,
  int power = 40,
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: power,
    type: type,
    category: category,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  required int level,
  required int maxHp,
  int? currentHp,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    moves: moves,
  );
}

BattleSession _session() {
  return createBattleSession(
    BattleSetup(
      playerPokemon: _combatant(
        speciesId: 'squirtle',
        lineupIndex: 0,
        level: 7,
        maxHp: 23,
        currentHp: 19,
        moves: <BattleMoveData>[
          _move(id: 'tail_whip', name: 'Tail Whip', power: 0, category: BattleMoveCategory.status),
          _move(id: 'water_gun', name: 'Water Gun', type: 'water', category: BattleMoveCategory.special),
          _move(id: 'withdraw', name: 'Withdraw', type: 'water', category: BattleMoveCategory.status, power: 0),
        ],
      ),
      enemyPokemon: _combatant(
        speciesId: 'charmander',
        lineupIndex: 0,
        level: 12,
        maxHp: 29,
        currentHp: 29,
        moves: <BattleMoveData>[
          _move(id: 'scratch', name: 'Scratch'),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

Future<ProjectManifest> _loadGoldenManifest() async {
  final file = File(
    '/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json',
  );
  final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(decoded);
}

Future<void> _loadDescendantTree(
  Component parent,
  Set<Component> loaded,
) async {
  for (final child in parent.children.toList(growable: false)) {
    if (loaded.add(child)) {
      await child.onLoad();
    }
    await _loadDescendantTree(child, loaded);
  }
}

Future<void> _renderCapture({
  required ui.Size viewport,
  required String outputPath,
  required BattlePokemonSpriteResolver spriteResolver,
}) async {
  final session = _session();
  final overlay = BattleOverlayComponent(
    session: session,
    viewportSize: Vector2(viewport.width, viewport.height),
    backgroundSpec: const BattleBackgroundSpec(
      key: BattleBackgroundKey.wildOutdoor,
    ),
    spriteResolver: spriteResolver,
    onPlayerChoice: (_) {},
  );

  await overlay.onLoad();
  final loaded = <Component>{};
  await _loadDescendantTree(overlay, loaded);
  overlay.updateState(session);
  await overlay.waitForPendingVisualSync();
  await _loadDescendantTree(overlay, loaded);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  overlay.renderTree(canvas);
  final image = await recorder.endRecording().toImage(
        viewport.width.ceil(),
        viewport.height.ceil(),
      );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Impossible d’extraire la capture PNG.');
  }

  final file = File(outputPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders lot 4f portrait hardening captures', () async {
    final manifest = await _loadGoldenManifest();
    final spriteResolver = BattlePokemonSpriteResolver(
      manifest: manifest,
      projectRootDirectory:
          '/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice',
    );
    final captures = <ui.Size>[
      const ui.Size(390, 844),
      const ui.Size(430, 932),
      const ui.Size(480, 854),
    ];

    for (final viewport in captures) {
      final path =
          '/Users/karim/Project/pokemonProject/reports/visual/lot-4f/battle-${viewport.width.toInt()}x${viewport.height.toInt()}.png';
      print('rendering $path');
      await _renderCapture(
        viewport: viewport,
        outputPath: path,
        spriteResolver: spriteResolver,
      );
      expect(File(path).existsSync(), isTrue);
    }
  });
}
