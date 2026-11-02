import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_presentation.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

import 'support/load_flame_component.dart';

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
    BattleSetup.pokeMapBetaV1ForTest(
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

BattleSceneCombatantComponent _combatantComponent({
  required bool isPlayerSide,
  required String speciesLabel,
  required BattleCombatantSpriteSpec spriteSpec,
}) {
  final footAnchor = ui.Offset(
    isPlayerSide ? 107 : 98,
    isPlayerSide ? 140 : 104,
  );
  final spriteWidth = isPlayerSide ? 182.0 : 132.0;
  final spriteHeight = isPlayerSide ? 132.0 : 94.0;
  return BattleSceneCombatantComponent(
    sceneSpriteRect: ui.Rect.fromLTWH(
      footAnchor.dx - (spriteWidth / 2),
      footAnchor.dy - spriteHeight,
      spriteWidth,
      spriteHeight,
    ),
    scenePlatformRect: ui.Rect.fromLTWH(
      isPlayerSide ? 44 : 52,
      isPlayerSide ? 136 : 100,
      isPlayerSide ? 126 : 92,
      isPlayerSide ? 20 : 16,
    ),
    sceneFootAnchor: footAnchor,
    spriteFootXRatio: isPlayerSide ? 0.68 : 0.5,
    isPlayerSide: isPlayerSide,
    speciesLabel: speciesLabel,
    initialSpriteSpec: spriteSpec,
  );
}

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
    test(
      'resolves shared canonical media with each species own form',
      () async {
        final root = await _sharedMediaProject('canonical');
        final resolver = BattlePokemonSpriteResolver(
          manifest: _manifest(),
          projectRootDirectory: root.path,
        );
        for (final form in ['a', 'b']) {
          for (final player in [false, true]) {
            for (final shiny in [false, true]) {
              final facing = player ? 'back' : 'front';
              final suffix = shiny ? '-shiny' : '';
              final spec = await resolver.resolve(
                speciesId: 'letter-$form',
                isPlayerSide: player,
                visualIdentity: RuntimeBattleVisualIdentity(
                  speciesId: 'letter-$form',
                  formId: form,
                  genderId: null,
                  isShiny: shiny,
                ),
              );
              expect(
                spec.explicitImageAbsolutePath,
                '${root.path}/assets/$form-$facing$suffix.png',
              );
            }
          }
          final ordinary = await resolver.resolve(
            speciesId: 'letter-$form',
            isPlayerSide: false,
          );
          expect(
            ordinary.explicitImageAbsolutePath,
            '${root.path}/assets/$form-front.png',
          );
          expect(
            await resolver.resolveCry('letter-$form'),
            '${root.path}/assets/$form.wav',
          );
        }
        expect(resolver.debugActualMediaReadCount, 2);
      },
    );

    test('preserves species fallback and legacy media references', () async {
      final root = await _sharedMediaProject('legacy');
      for (final entry in {
        'legacy': {'spriteSetRef': 'shared', 'cryRef': 'shared'},
        'fallback': <String, Object?>{},
      }.entries) {
        await File('${root.path}/data/pokemon/species/${entry.key}.json')
            .writeAsString(
              jsonEncode({'schemaVersion': 1, 'id': entry.key, ...entry.value}),
            );
      }
      await _writePokemonMedia(
        root: root,
        speciesId: 'fallback',
        frontRelativePath: 'assets/a-front.png',
        backRelativePath: 'assets/a-back.png',
      );
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: root.path,
      );
      for (final species in ['legacy', 'fallback']) {
        expect(
          (await resolver.resolve(
            speciesId: species,
            isPlayerSide: false,
          )).explicitImageAbsolutePath,
          '${root.path}/assets/a-front.png',
        );
      }
    });

    test(
      'rejects unsafe media references without using same-species media',
      () async {
        final root = await _sharedMediaProject('unsafe');
        for (final reference in [
          '../shared',
          '/shared',
          r'..\shared',
          'file:///shared',
          'shared/nested',
        ]) {
          await File('${root.path}/data/pokemon/species/letter-a.json')
              .writeAsString(
                jsonEncode({
                  'schemaVersion': 1,
                  'id': 'letter-a',
                  'refs': {'media': reference},
                }),
              );
          await _writePokemonMedia(
            root: root,
            speciesId: 'letter-a',
            frontRelativePath: 'assets/a-front.png',
            backRelativePath: 'assets/a-back.png',
          );
          final resolver = BattlePokemonSpriteResolver(
            manifest: _manifest(),
            projectRootDirectory: root.path,
          );
          expect(
            (await resolver.resolve(
              speciesId: 'letter-a',
              isPlayerSide: false,
            )).explicitImageAbsolutePath,
            isNull,
            reason: reference,
          );
        }
      },
    );

    test('preserves malformed media errors for canonical references', () async {
      final root = await _sharedMediaProject('malformed');
      await File('${root.path}/data/pokemon/media/shared.json')
          .writeAsString('{');
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: root.path,
      );
      await expectLater(
        resolver.resolve(speciesId: 'letter-b', isPlayerSide: false),
        throwsFormatException,
      );
    });

    test(
      'keeps authored media default when species form has no variant',
      () async {
        final root = await _sharedMediaProject('default');
        final media = File('${root.path}/data/pokemon/media/shared.json');
        final document =
            jsonDecode(await media.readAsString()) as Map<String, dynamic>;
        document['defaultFormId'] = 'b';
        await media.writeAsString(jsonEncode(document));
        await File('${root.path}/data/pokemon/species/letter-a.json')
            .writeAsString(
              jsonEncode({
                'schemaVersion': 1,
                'id': 'letter-a',
                'refs': {'media': 'shared'},
                'forms': {'formId': 'missing'},
              }),
            );
        final resolver = BattlePokemonSpriteResolver(
          manifest: _manifest(),
          projectRootDirectory: root.path,
        );
        expect(
          (await resolver.resolve(
            speciesId: 'letter-a',
            isPlayerSide: false,
          )).explicitImageAbsolutePath,
          '${root.path}/assets/b-front.png',
        );
      },
    );

    test('rejects a referenced media symlink outside the project', () async {
      final root = await _sharedMediaProject('symlink');
      final media = File('${root.path}/data/pokemon/media/shared.json');
      final outside = File('${root.path}-outside.json');
      await outside.writeAsString(await media.readAsString());
      addTearDown(() => outside.delete());
      await media.delete();
      await Link(media.path).create(outside.path);
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: root.path,
      );
      expect(
        (await resolver.resolve(
          speciesId: 'letter-a',
          isPlayerSide: false,
        )).explicitImageAbsolutePath,
        isNull,
      );
    });

    test('resolves authored cries and shares the media read with sprites', () async {
      final root = await Directory.systemTemp.createTemp('battle-cry-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/data/pokemon/media/rattata.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'defaultFormId': 'base', 'variants': {'base': {
        'cry': 'assets/audio/pokemon/rattata/cry.wav', 'frontStatic': 'assets/front.png',
      }}}));
      final resolver = BattlePokemonSpriteResolver(manifest: _manifest(), projectRootDirectory: root.path);
      expect(await resolver.resolveCry('rattata'), '${root.path}/assets/audio/pokemon/rattata/cry.wav');
      await resolver.resolve(speciesId: 'rattata', isPlayerSide: false);
      expect(resolver.debugActualMediaReadCount, 1);
      await file.writeAsString(jsonEncode({'defaultFormId': 'base', 'variants': {'base': {'cry': '../outside.wav'}}}));
      final unsafe = BattlePokemonSpriteResolver(manifest: _manifest(), projectRootDirectory: root.path);
      expect(await unsafe.resolveCry('rattata'), isNull);
      expect(await unsafe.resolveCry('../rattata'), isNull);
    });
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

      final component = _combatantComponent(
        isPlayerSide: true,
        speciesLabel: 'charmander',
        spriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitImageAbsolutePath: spritePath,
        ),
      );

      await component.onLoad();

      expect(component.hasResolvedExplicitSprite, isTrue);
      expect(component.currentSpriteSourcePath, spritePath);
    });

    test('keeps the silhouette fallback when the sprite is missing', () async {
      final component = _combatantComponent(
        isPlayerSide: false,
        speciesLabel: 'gastly',
        spriteSpec: const BattleCombatantSpriteSpec(
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

      final component = _combatantComponent(
        isPlayerSide: true,
        speciesLabel: 'squirtle',
        spriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitImageAbsolutePath: spritePath,
        ),
      );

      await component.onLoad();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      component.render(canvas);
      final rendered = await recorder.endRecording().toImage(
            component.size.x.ceil(),
            component.size.y.ceil(),
          );
      final byteData = await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(byteData, isNotNull);

      final bounds = _opaqueBoundsFromRgba(
        rgba: byteData!.buffer.asUint8List(),
        width: component.size.x.ceil(),
        height: component.size.y.ceil(),
      );

      expect(bounds.width, greaterThan(90));
      expect(bounds.height, greaterThan(90));
      expect(
        component.currentRenderedSpriteRect.bottom,
        closeTo(component.currentFootAnchor.dy, 0.01),
      );
    });

    test('preserves sprite aspect ratio and bottom foot alignment', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'battle_combatant_ratio_',
      );
      final spritePath = await _writeTinyPng(
        root: projectRoot,
        relativePath: 'assets/pokemon/sprites/charmander/front.png',
      );

      final component = _combatantComponent(
        isPlayerSide: false,
        speciesLabel: 'charmander',
        spriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.front,
          explicitImageAbsolutePath: spritePath,
        ),
      );

      await component.onLoad();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      component.render(canvas);
      final rendered = await recorder.endRecording().toImage(
            component.size.x.ceil(),
            component.size.y.ceil(),
          );
      final byteData = await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(byteData, isNotNull);

      final bounds = _opaqueBoundsFromRgba(
        rgba: byteData!.buffer.asUint8List(),
        width: component.size.x.ceil(),
        height: component.size.y.ceil(),
      );

      final renderedAspectRatio = bounds.width / bounds.height;
      expect(renderedAspectRatio, greaterThanOrEqualTo(0.8));
      expect(renderedAspectRatio, lessThanOrEqualTo(1.2));
      expect(
        component.currentSpriteRect.bottom,
        closeTo(component.currentFootAnchor.dy, 0.01),
      );
    });

    test('keeps sprite and platform centered on the same foot anchor',
        () async {
      final component = _combatantComponent(
        isPlayerSide: true,
        speciesLabel: 'squirtle',
        spriteSpec: const BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
        ),
      );

      await component.onLoad();

      expect(
        component.currentPlatformRect.center.dx,
        closeTo(component.currentFootAnchor.dx, 0.01),
      );
      expect(
        component.currentSpriteRect.bottom,
        closeTo(component.currentFootAnchor.dy, 0.01),
      );
    });

    test('keeps the fallback silhouette anchored on the same foot point',
        () async {
      final component = _combatantComponent(
        isPlayerSide: true,
        speciesLabel: 'missingno',
        spriteSpec: const BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitImageAbsolutePath: '/tmp/does_not_exist_missingno_back.png',
        ),
      );

      await component.onLoad();

      expect(
        component.currentRenderedSpriteRect.bottom,
        closeTo(component.currentFootAnchor.dy, 0.01),
      );
      expect(component.currentRenderedSpriteRect.width, greaterThan(0));
      expect(component.currentRenderedSpriteRect.height, greaterThan(0));
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

    await loadFlameComponent(overlay);
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

Future<Directory> _sharedMediaProject(String name) async {
  final root = await Directory.systemTemp.createTemp(
    'battle_shared_media_$name',
  );
  addTearDown(() => root.delete(recursive: true));
  final variants = <String, Object?>{};
  for (final form in ['a', 'b']) {
    final species = File('${root.path}/data/pokemon/species/letter-$form.json');
    await species.parent.create(recursive: true);
    await species.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'id': 'letter-$form',
        'refs': {'media': 'shared'},
        'forms': {'formId': form},
      }),
    );
    final variant = <String, Object?>{'cry': 'assets/$form.wav'};
    for (final facing in ['front', 'back']) {
      for (final shiny in [false, true]) {
        final path = 'assets/$form-$facing${shiny ? '-shiny' : ''}.png';
        await _writeTinyPng(root: root, relativePath: path);
        variant['$facing${shiny ? 'Shiny' : ''}Static'] = path;
      }
    }
    variants[form] = variant;
  }
  final media = File('${root.path}/data/pokemon/media/shared.json');
  await media.parent.create(recursive: true);
  await media.writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'defaultFormId': 'a',
      'variants': variants,
    }),
  );
  return root;
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
