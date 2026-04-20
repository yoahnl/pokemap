import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

BattleStatsSnapshot _stats() {
  return const BattleStatsSnapshot(
    attack: 60,
    defense: 60,
    specialAttack: 60,
    specialDefense: 60,
    speed: 60,
  );
}

BattleMoveData _tackle() {
  return const BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
    power: 40,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    moves: <BattleMoveData>[_tackle()],
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: true,
      trainerId: 'trainer',
    ),
  );
}

const String _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGOMmnbnPwMDAwMTiABhACpmAs+3EdpKAAAAAElFTkSuQmCC';
const String _paddedSpritePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAALElEQVR4nGNgGAWDDjDikvgfEPAfr8YNG7DqZaKGq5DBqIEjwcBRMAoYSAcAopsEECjFJ6AAAAAASUVORK5CYII=';

Future<String> _writeTinyPng({
  required Directory root,
  required String relativePath,
}) async {
  final file = File('${root.path}/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(base64Decode(_tinyPngBase64));
  return file.path;
}

Future<void> _writePokemonMedia({
  required Directory root,
  required String speciesId,
  required String frontRelativePath,
  required String backRelativePath,
}) async {
  final file = File('${root.path}/data/pokemon/media/$speciesId.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(<String, Object?>{
      'defaultFormId': 'base',
      'variants': <String, Object?>{
        'base': <String, Object?>{
          'frontStatic': frontRelativePath,
          'backStatic': backRelativePath,
        },
      },
    }),
  );
}

ProjectManifest _manifest() {
  return const ProjectManifest(
    name: 'battle_pokemon_sprite_resolver_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattlePokemonSpriteResolver', () {
    test('chooses front for enemy and back for player', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'battle_sprite_resolver_',
      );
      await _writeTinyPng(
        root: projectRoot,
        relativePath: 'assets/pokemon/sprites/bulbasaur/front.png',
      );
      await _writeTinyPng(
        root: projectRoot,
        relativePath: 'assets/pokemon/sprites/bulbasaur/back.png',
      );
      await _writePokemonMedia(
        root: projectRoot,
        speciesId: 'bulbasaur',
        frontRelativePath: 'assets/pokemon/sprites/bulbasaur/front.png',
        backRelativePath: 'assets/pokemon/sprites/bulbasaur/back.png',
      );

      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: projectRoot.path,
      );

      final enemySpec = await resolver.resolve(
        speciesId: 'bulbasaur',
        isPlayerSide: false,
      );
      final playerSpec = await resolver.resolve(
        speciesId: 'bulbasaur',
        isPlayerSide: true,
      );

      expect(enemySpec.facing, BattleCombatantSpriteFacing.front);
      expect(enemySpec.explicitImageAbsolutePath, endsWith('/front.png'));
      expect(playerSpec.facing, BattleCombatantSpriteFacing.back);
      expect(playerSpec.explicitImageAbsolutePath, endsWith('/back.png'));
    });
  });

  group('BattleSceneCombatantComponent', () {
    test('loads an explicit sprite image when one is resolved', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'battle_combatant_component_',
      );
      final spritePath = await _writeTinyPng(
        root: projectRoot,
        relativePath: 'assets/pokemon/sprites/charmander/back.png',
      );

      final component = BattleSceneCombatantComponent(
        position: Vector2.zero(),
        size: Vector2(240, 160),
        isPlayerSide: true,
        speciesLabel: 'charmander',
        initialSpriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitImageAbsolutePath: spritePath,
        ),
      );

      await component.onLoad();

      expect(component.hasResolvedExplicitSprite, isTrue);
      expect(component.currentSpriteSourcePath, spritePath);
    });

    test('keeps the silhouette fallback when the sprite is missing', () async {
      final component = BattleSceneCombatantComponent(
        position: Vector2.zero(),
        size: Vector2(240, 160),
        isPlayerSide: false,
        speciesLabel: 'gastly',
        initialSpriteSpec: const BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.front,
          explicitImageAbsolutePath: '/tmp/does_not_exist_gastly_front.png',
        ),
      );

      await component.onLoad();

      expect(component.hasResolvedExplicitSprite, isFalse);
      expect(component.didExplicitSpriteLoadFail, isTrue);
    });

    test('renders a padded explicit sprite at a large visible size', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'battle_combatant_padded_sprite_',
      );
      final spritePath = await _writeRawPng(
        root: projectRoot,
        relativePath: 'assets/pokemon/sprites/squirtle/back_padded.png',
        base64Png: _paddedSpritePngBase64,
      );

      final component = BattleSceneCombatantComponent(
        position: Vector2.zero(),
        size: Vector2(240, 160),
        isPlayerSide: true,
        speciesLabel: 'squirtle',
        initialSpriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitImageAbsolutePath: spritePath,
        ),
      );

      await component.onLoad();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      component.render(canvas);
      final rendered = await recorder.endRecording().toImage(240, 160);
      final byteData = await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(byteData, isNotNull);

      final bounds = _opaqueBoundsFromRgba(
        rgba: byteData!.buffer.asUint8List(),
        width: 240,
        height: 120,
      );

      expect(bounds.width, greaterThan(90));
      expect(bounds.height, greaterThan(90));
    });
  });

  test('BattleOverlayComponent refreshes player sprite after a switch',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'battle_overlay_sprite_refresh_',
    );
    await _writeTinyPng(
      root: projectRoot,
      relativePath: 'assets/pokemon/sprites/bulbasaur/back.png',
    );
    await _writeTinyPng(
      root: projectRoot,
      relativePath: 'assets/pokemon/sprites/bulbasaur/front.png',
    );
    await _writeTinyPng(
      root: projectRoot,
      relativePath: 'assets/pokemon/sprites/ivysaur/back.png',
    );
    await _writeTinyPng(
      root: projectRoot,
      relativePath: 'assets/pokemon/sprites/ivysaur/front.png',
    );
    await _writeTinyPng(
      root: projectRoot,
      relativePath: 'assets/pokemon/sprites/pikachu/front.png',
    );
    await _writeTinyPng(
      root: projectRoot,
      relativePath: 'assets/pokemon/sprites/pikachu/back.png',
    );
    await _writePokemonMedia(
      root: projectRoot,
      speciesId: 'bulbasaur',
      frontRelativePath: 'assets/pokemon/sprites/bulbasaur/front.png',
      backRelativePath: 'assets/pokemon/sprites/bulbasaur/back.png',
    );
    await _writePokemonMedia(
      root: projectRoot,
      speciesId: 'ivysaur',
      frontRelativePath: 'assets/pokemon/sprites/ivysaur/front.png',
      backRelativePath: 'assets/pokemon/sprites/ivysaur/back.png',
    );
    await _writePokemonMedia(
      root: projectRoot,
      speciesId: 'pikachu',
      frontRelativePath: 'assets/pokemon/sprites/pikachu/front.png',
      backRelativePath: 'assets/pokemon/sprites/pikachu/back.png',
    );

    final resolver = BattlePokemonSpriteResolver(
      manifest: _manifest(),
      projectRootDirectory: projectRoot.path,
    );

    final initialSession = _session(
      player: _combatant(
        speciesId: 'bulbasaur',
        lineupIndex: 0,
      ),
      playerReserve: <BattleCombatantData>[
        _combatant(
          speciesId: 'ivysaur',
          lineupIndex: 1,
        ),
      ],
      enemy: _combatant(
        speciesId: 'pikachu',
        lineupIndex: 0,
      ),
    );

    final overlay = BattleOverlayComponent(
      session: initialSession,
      viewportSize: Vector2(960, 540),
      spriteResolver: resolver,
      onPlayerChoice: (_) {},
    );

    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();

    final initialPlayerCombatant = overlay.children
        .whereType<BattleSceneCombatantComponent>()
        .firstWhere((component) => component.belongsToPlayerSide);
    expect(
      initialPlayerCombatant.currentSpriteSourcePath,
      endsWith('/bulbasaur/back.png'),
    );

    final switchedSession = _session(
      player: _combatant(
        speciesId: 'ivysaur',
        lineupIndex: 1,
      ),
      enemy: _combatant(
        speciesId: 'pikachu',
        lineupIndex: 0,
      ),
    );

    overlay.updateState(switchedSession);
    await overlay.waitForPendingVisualSync();

    final refreshedPlayerCombatant = overlay.children
        .whereType<BattleSceneCombatantComponent>()
        .firstWhere((component) => component.belongsToPlayerSide);
    expect(refreshedPlayerCombatant.currentSpeciesLabel, 'ivysaur');
    expect(
      refreshedPlayerCombatant.currentSpriteSourcePath,
      endsWith('/ivysaur/back.png'),
    );
  });
}

Future<String> _writeRawPng({
  required Directory root,
  required String relativePath,
  required String base64Png,
}) async {
  final file = File('${root.path}/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(base64Decode(base64Png));
  return file.path;
}

ui.Rect _opaqueBoundsFromRgba({
  required Uint8List rgba,
  required int width,
  required int height,
}) {
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = rgba[((y * width) + x) * 4 + 3];
      if (alpha == 0) {
        continue;
      }
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) {
    return ui.Rect.zero;
  }
  return ui.Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    (maxX + 1).toDouble(),
    (maxY + 1).toDouble(),
  );
}
