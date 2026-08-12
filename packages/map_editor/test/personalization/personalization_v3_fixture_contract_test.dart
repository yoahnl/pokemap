import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = Directory(
    p.join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'golden_personalization_v3',
    ),
  );

  test('acceptance project owns all six scenes and their real context', () {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(File(p.join(root.path, 'project.json')).readAsStringSync())
          as Map<String, dynamic>,
    );
    expect(() => ProjectValidator.validate(manifest), returnsNormally);
    final scenes =
        (manifest.globalProperties['personalizationAcceptanceScenes']
                as List<Object?>)
            .cast<String>();

    expect(scenes, <String>[
      'globalStyle',
      'title',
      'intro',
      'pause',
      'dialogue',
      'battle',
    ]);
    expect(manifest.maps.single.id, 'vermeil_village');
    expect(manifest.dialogues.single.id, 'welcome_leo');
    expect(manifest.characters.single.id, 'leo');
    expect(
      manifest.characters.single.portraits.single.assetId,
      'portrait-leo-happy',
    );
    expect(manifest.encounterTables.single.id, 'vermeil_grass');
    expect(manifest.presentation?.schemaVersion, 10);
    expect(
      manifest.presentation?.battle?.commandLayout,
      ProjectBattleCommandLayout.radial,
    );
    expect(
      manifest.presentation?.battle?.effectiveCommands.map(
        (command) => command.id,
      ),
      <ProjectBattleCommandId>[
        ProjectBattleCommandId.run,
        ProjectBattleCommandId.fight,
        ProjectBattleCommandId.party,
        ProjectBattleCommandId.bag,
      ],
    );
    expect(
      manifest.presentation?.battle?.moves.shape,
      ProjectWindowShape.rounded,
    );
    expect(
      manifest.presentation?.battle?.target.shape,
      ProjectWindowShape.capsule,
    );
    expect(
      manifest.presentation?.battle?.message.shape,
      ProjectWindowShape.cutCorner,
    );
    expect(
      manifest.presentation?.pause?.actions
          ?.firstWhere((action) => action.id == ProjectPauseActionId.pokedex)
          .label,
      'Carnet de route',
    );
    expect(manifest.presentation?.intro, isNotNull);
  });

  test('acceptance map and dialogue decode into playable project models', () {
    final map = MapData.fromJson(
      jsonDecode(
            File(
              p.join(root.path, 'maps', 'vermeil_village.json'),
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final source = File(
      p.join(root.path, 'dialogues', 'welcome_leo.yarn'),
    ).readAsStringSync();
    final dialogue = const YarnDialogueCompiler().compile(source);
    final firstLine = dialogue.nodes.single.steps.first as RuntimeDialogueLine;

    expect(map.entities.map((entity) => entity.id), contains('npc_leo'));
    expect(
      map.gameplayZones.map((zone) => zone.id),
      contains('vermeil_grass_zone'),
    );
    expect(firstLine.characterId, 'leo');
    expect(firstLine.portraitStateId, 'happy');
    expect(firstLine.text, contains('Bienvenue à Vermeil'));
  });

  test('acceptance media and readable capture font are versioned', () async {
    final requiredFiles = <String>[
      'assets/presentation/icon.png',
      'assets/presentation/cover.png',
      'assets/presentation/hero.png',
      'assets/presentation/title-loop.mp4',
      'assets/presentation/intro/poster.png',
      'assets/presentation/intro/intro.mp4',
      'assets/presentation/intro/captions.vtt',
      'assets/presentation/fonts/display.ttf',
      'assets/presentation/fonts/display-license.txt',
      'assets/characters/leo-happy.png',
      'assets/battle/battle-clearing.png',
      'assets/maps/vermeil-village-stage.png',
      'assets/.pokemap-assets.json',
    ];

    for (final relativePath in requiredFiles) {
      expect(
        File(p.join(root.path, relativePath)).lengthSync(),
        greaterThan(8),
        reason: relativePath,
      );
    }
    expect(
      File(
        p.join(root.path, 'assets', 'presentation', 'fonts', 'display.ttf'),
      ).readAsBytesSync().take(4),
      <int>[0, 1, 0, 0],
    );
    final imageMinimums = <String, ui.Size>{
      'assets/presentation/icon.png': const ui.Size(128, 128),
      'assets/presentation/cover.png': const ui.Size(960, 540),
      'assets/presentation/hero.png': const ui.Size(960, 540),
      'assets/presentation/intro/poster.png': const ui.Size(960, 540),
      'assets/characters/leo-happy.png': const ui.Size(512, 512),
      'assets/battle/battle-clearing.png': const ui.Size(960, 540),
      'assets/maps/vermeil-village-stage.png': const ui.Size(960, 540),
    };
    for (final entry in imageMinimums.entries) {
      final size = await _imageSize(File(p.join(root.path, entry.key)));
      expect(
        size.width,
        greaterThanOrEqualTo(entry.value.width),
        reason: entry.key,
      );
      expect(
        size.height,
        greaterThanOrEqualTo(entry.value.height),
        reason: entry.key,
      );
    }
    expect(
      File(
        p.join(root.path, 'assets', 'presentation', 'intro', 'intro.mp4'),
      ).lengthSync(),
      greaterThan(50000),
    );
    expect(
      File(
        p.join(root.path, 'assets', 'presentation', 'title-loop.mp4'),
      ).lengthSync(),
      greaterThan(50000),
    );
  });

  test('acceptance map owns a rendered backdrop and battle scene', () {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(File(p.join(root.path, 'project.json')).readAsStringSync())
          as Map<String, dynamic>,
    );
    final map = MapData.fromJson(
      jsonDecode(
            File(
              p.join(root.path, 'maps', 'vermeil_village.json'),
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final stageTileset = manifest.tilesets.singleWhere(
      (tileset) => tileset.id == 'vermeil-stage',
    );
    final encounterZone = map.gameplayZones.singleWhere(
      (zone) => zone.id == 'vermeil_grass_zone',
    );

    expect(stageTileset.source, isNotNull);
    expect(map.layers.whereType<TileLayer>(), isNotEmpty);
    expect(map.layers.whereType<TileLayer>().single.cells, <int>[1]);
    expect(
      encounterZone.encounter?.battleBackgroundRelativePath,
      'assets/battle/battle-clearing.png',
    );
  });

  test('acceptance presentation passes the real export preflight', () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(File(p.join(root.path, 'project.json')).readAsStringSync())
          as Map<String, dynamic>,
    );
    final profile = manifest.presentation!;
    final result = await const FileSystemProjectPresentationPreflight().inspect(
      projectRoot: root,
      profile: profile,
    );

    expect(result.report.issues, isEmpty);
    expect(result.checkedAssetCount, 8);

    final missingIcon = await const FileSystemProjectPresentationPreflight()
        .inspect(
          projectRoot: root,
          profile: profile.copyWith(
            branding: profile.branding.copyWith(
              iconPath: 'assets/presentation/missing-icon.png',
            ),
          ),
        );

    expect(
      missingIcon.report.issues
          .firstWhere((issue) => issue.code == 'presentationAssetMissing')
          .path,
      r'$.presentation.branding.iconPath',
    );
  });
}

Future<ui.Size> _imageSize(File file) async {
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  final frame = await codec.getNextFrame();
  final size = ui.Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
  frame.image.dispose();
  codec.dispose();
  return size;
}
