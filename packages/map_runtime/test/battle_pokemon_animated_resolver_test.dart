import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

late Directory qaDirectory;
var createdQaDirectory = false;

Future<Directory> _project() async {
  final project = await qaDirectory.createTemp('project-');
  addTearDown(() => project.delete(recursive: true));
  return project;
}

Future<void> _writeBytes(Directory root, String path, List<int> bytes) async {
  final file = File('${root.path}/$path');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}

Future<void> _writeMedia(
  Directory root, {
  required String species,
  required Map<String, Object?> variant,
  int? schemaVersion,
}) async {
  await _writeBytes(
    root,
    'data/pokemon/media/$species.json',
    utf8.encode(
      jsonEncode({
      'schemaVersion': ?schemaVersion,
        'speciesId': species,
        'defaultFormId': 'base',
        'variants': {'base': variant},
      }),
    ),
  );
}

List<int> _twoFrameGif() {
  final red = img.Image(width: 2, height: 2);
  final blue = img.Image(width: 2, height: 2);
  img.fill(red, color: img.ColorRgb8(255, 0, 0));
  img.fill(blue, color: img.ColorRgb8(0, 0, 255));
  final encoder = img.GifEncoder(
    repeat: 0,
    dither: img.DitherKernel.none,
    quantizerType: img.QuantizerType.octree,
  );
  encoder.addFrame(red, duration: 10);
  encoder.addFrame(blue, duration: 10);
  return encoder.finish()!;
}

BattlePokemonSpriteResolver _resolver(Directory root) =>
    BattlePokemonSpriteResolver(
      manifest: const ProjectManifest(name: 'GIF test', maps: [], tilesets: []),
      projectRootDirectory: root.path,
    );

BattleCombatantData _combatant(String speciesId) => BattleCombatantData(
  speciesId: speciesId,
  level: 5,
  maxHp: 20,
  stats: const BattleStatsSnapshot(
    attack: 10,
    defense: 10,
    specialAttack: 10,
    specialDefense: 10,
    speed: 10,
  ),
  moves: const [
    BattleMoveData(
      id: 'tackle',
      name: 'Tackle',
      power: 40,
      type: 'normal',
      category: BattleMoveCategory.physical,
      target: BattleMoveTarget.opponent,
    ),
  ],
);

Future<List<int>> _renderedCenter(
  BattleSceneCombatantComponent component,
) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    component.size.x.ceil(),
    component.size.y.ceil(),
  );
  try {
    final center =
        component.currentRenderedSpriteRect.center -
        ui.Offset(component.position.x, component.position.y);
    final x = center.dx.floor();
    final y = center.dy.floor();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final offset = (y * image.width + x) * 4;
    return bytes!.buffer.asUint8List().sublist(offset, offset + 4);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final supplied = Platform.environment['AVELUNE_QA_ROOT'];
    qaDirectory = Directory(
      supplied ??
          (Platform.isMacOS
              ? '${Platform.environment['HOME']}/Library/Caches/AveluneQA/battle-gif-resolver-tests'
              : Directory.systemTemp.path),
    );
    if (!await qaDirectory.exists()) {
      await qaDirectory.create(recursive: true);
      createdQaDirectory = true;
    }
  });

  tearDownAll(() async {
    if (createdQaDirectory) await qaDirectory.delete();
  });

  test(
    'resolves v2 face and back GIFs independently of static images',
    () async {
      final root = await _project();
      await _writeBytes(root, 'assets/front.gif', _twoFrameGif());
      await _writeBytes(root, 'assets/back.gif', _twoFrameGif());
      await _writeMedia(
        root,
        species: 'oshawott',
        schemaVersion: 2,
        variant: {
          'frontAnimated': 'assets/front.gif',
          'backAnimated': 'assets/back.gif',
          'frontStatic': 'assets/front.png',
        },
      );

      final resolver = _resolver(root);
      final enemy = await resolver.resolve(
        speciesId: 'oshawott',
        isPlayerSide: false,
      );
      final player = await resolver.resolve(
        speciesId: 'oshawott',
        isPlayerSide: true,
      );

      expect(enemy.explicitImageAbsolutePath, '${root.path}/assets/front.png');
      expect(
        enemy.explicitAnimatedImageAbsolutePath,
        '${root.path}/assets/front.gif',
      );
      expect(player.explicitImageAbsolutePath, isNull);
      expect(
        player.explicitAnimatedImageAbsolutePath,
        '${root.path}/assets/back.gif',
      );
      expect(resolver.debugActualMediaReadCount, 1);
    },
  );

  test(
    'keeps legacy static media without activating unknown animated fields',
    () async {
      final root = await _project();
      await _writeBytes(root, 'assets/front.gif', _twoFrameGif());
      for (final version in [null, 1]) {
        final species = version == null ? 'unversioned' : 'legacy';
        await _writeMedia(
          root,
          species: species,
          schemaVersion: version,
          variant: {
            'frontAnimated': 'assets/front.gif',
            'frontStatic': 'assets/front.png',
          },
        );
        final spec = await _resolver(root)
            .resolve(speciesId: species, isPlayerSide: false);
        expect(spec.explicitImageAbsolutePath, '${root.path}/assets/front.png');
        expect(spec.explicitAnimatedImageAbsolutePath, isNull);
      }
    },
  );

  test(
    'rejects unsafe or missing GIF paths while preserving static fallback',
    () async {
      final root = await _project();
      for (final (index, path) in [
        '../outside.gif',
        'https://example.org/front.gif',
        '/outside.gif',
        'assets/missing.gif',
      ].indexed) {
        final species = 'unsafe-$index';
        await _writeMedia(
          root,
          species: species,
          schemaVersion: 2,
          variant: {'frontAnimated': path, 'frontStatic': 'assets/front.png'},
        );
        final spec = await _resolver(root)
            .resolve(speciesId: species, isPlayerSide: false);
        expect(spec.explicitAnimatedImageAbsolutePath, isNull, reason: path);
        expect(spec.explicitImageAbsolutePath, '${root.path}/assets/front.png');
      }
    },
  );

  test(
    'rejects a GIF link outside the project',
    () async {
      final root = await _project();
      final outside = await qaDirectory.createTemp('outside-');
      addTearDown(() => outside.delete(recursive: true));
      final gif = File('${outside.path}/front.gif');
      await gif.writeAsBytes(_twoFrameGif());
      await Directory('${root.path}/assets').create();
      await Link('${root.path}/assets/front.gif').create(gif.path);
      await _writeMedia(
        root,
        species: 'oshawott',
        schemaVersion: 2,
        variant: {
          'frontAnimated': 'assets/front.gif',
          'frontStatic': 'assets/front.png',
        },
      );

      final spec = await _resolver(root)
          .resolve(speciesId: 'oshawott', isPlayerSide: false);
      expect(spec.explicitAnimatedImageAbsolutePath, isNull);
      expect(spec.explicitImageAbsolutePath, '${root.path}/assets/front.png');
    },
    skip: Platform.isWindows
        ? 'Symbolic links can require elevated privileges.'
        : false,
  );

  test('renders the static fallback when a resolved GIF is corrupt', () async {
    final root = await _project();
    final green = img.Image(width: 2, height: 2);
    img.fill(green, color: img.ColorRgb8(0, 255, 0));
    await _writeBytes(root, 'assets/front.png', img.encodePng(green));
    await _writeBytes(root, 'assets/front.gif', [1, 2, 3]);
    await _writeMedia(
      root,
      species: 'oshawott',
      schemaVersion: 2,
      variant: {
        'frontAnimated': 'assets/front.gif',
        'frontStatic': 'assets/front.png',
      },
    );
    final spec = await _resolver(root)
        .resolve(speciesId: 'oshawott', isPlayerSide: false);
    expect(
      spec.explicitAnimatedImageAbsolutePath,
      '${root.path}/assets/front.gif',
    );
    final combatant = BattleSceneCombatantComponent(
      sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 40, 40),
      scenePlatformRect: const ui.Rect.fromLTWH(0, 40, 40, 10),
      sceneFootAnchor: const ui.Offset(20, 40),
      spriteFootXRatio: 0.5,
      isPlayerSide: false,
      speciesLabel: 'oshawott',
      initialSpriteSpec: spec,
    );
    addTearDown(combatant.onRemove);
    await combatant.onLoad();
    combatant.onMount();
    await combatant.sync(speciesLabel: 'oshawott', spriteSpec: spec);

    expect(combatant.currentSpriteSourcePath, '${root.path}/assets/front.png');
    expect(await _renderedCenter(combatant), [0, 255, 0, 255]);
  });

  testWidgets(
    'renders changing v2 GIF frames through the actual battle overlay',
    (tester) async {
      final root = await tester.runAsync(_project);
      await tester.runAsync(() async {
        await _writeBytes(root!, 'assets/front.gif', _twoFrameGif());
        await _writeBytes(root, 'assets/back.gif', _twoFrameGif());
        await _writeMedia(
          root,
          species: 'oshawott',
          schemaVersion: 2,
          variant: {
            'frontAnimated': 'assets/front.gif',
            'backAnimated': 'assets/back.gif',
          },
        );
      });
      final session = createBattleSession(
        BattleSetup.pokeMapBetaV1ForTest(
          playerPokemon: _combatant('oshawott'),
          enemyPokemon: _combatant('oshawott'),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );
      final overlay = BattleOverlayComponent(
        session: session,
        viewportSize: Vector2(960, 540),
        spriteResolver: _resolver(root!),
        onPlayerChoice: (_) {},
      );
      final game = FlameGame()..world.add(overlay);
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 960,
              height: 540,
              child: GameWidget(game: game),
            ),
          ),
        );
        for (var i = 0; i < 80; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          if (overlay.debugEnemyCombatant?.currentSpriteSourcePath?.endsWith(
                    '/front.gif',
                  ) ==
                  true &&
              overlay.debugPlayerCombatant?.currentSpriteSourcePath?.endsWith(
                    '/back.gif',
                  ) ==
                  true) {
            break;
          }
        }
        final enemy = overlay.debugEnemyCombatant!;
        final player = overlay.debugPlayerCombatant!;
        expect(enemy.currentSpriteSourcePath, '${root.path}/assets/front.gif');
        expect(player.currentSpriteSourcePath, '${root.path}/assets/back.gif');
        game.pauseEngine();
        for (final combatant in [enemy, player]) {
          combatant.renderedBy3DStage = false;
          final first = await tester.runAsync(() => _renderedCenter(combatant));
          combatant.update(.1);
          final second = await tester.runAsync(
            () => _renderedCenter(combatant),
          );
          expect(
            [first, second],
            containsAll([
              [255, 0, 0, 255],
              [0, 0, 255, 255],
            ]),
          );
        }
      } finally {
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
