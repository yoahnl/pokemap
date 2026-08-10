import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/load_dialogue_content.dart';
import 'package:map_runtime/src/application/resolve_dialogue.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'CHS-052 runtime shows Surprise, plays Saluer and restores Base',
    () async {
      final fixture = await _GoldenRuntimeFixture.create();
      addTearDown(fixture.dispose);
      final reopened = ProjectManifest.fromJson(
        jsonDecode(await fixture.projectFile.readAsString())
            as Map<String, dynamic>,
      );
      final dialogue = await loadDialogueContent(
        ResolvedDialogue(
          absoluteFilePath: fixture.dialogueFile.path,
          dialogueId: 'dialogue.intro',
          startNode: 'Start',
        ),
      );
      final line = dialogue!.state as DialogueShowingLine;
      final portraits = DialoguePortraitResolver(
        manifest: reopened,
        projectRootDirectory: fixture.root.path,
      );

      await portraits.preload(dialogue);
      final portrait = portraits.resolve(
        characterId: line.characterId!,
        portraitStateId: line.portraitStateId!,
      );

      expect(line.text, 'Élia: Attends… tu as vu ça ?');
      expect(portrait?.characterName, 'Élia');
      expect(portrait?.portraitStateName, 'Surprise');
      expect(portrait?.absoluteFilePath, fixture.portraitBlob.path);

      final command = cinematicCharacterCustomAnimationCommandOf(
        reopened.cinematics.single.timeline.steps.single,
      )!;
      final actor = _GoldenRuntimeActor(
        root: fixture.root,
        catalog: fixture.catalog,
        character: reopened.characters.single,
      );
      final controller = CharacterCustomAnimationRuntimeController(
        manifest: reopened,
        actorLookup: (actorId) => actorId == actor.actorId ? actor : null,
      );

      final completion = controller.play(command);
      expect(controller.isActorPlaying('hero'), isTrue);
      expect(actor.playedClip?.definitionId, 'saluer');
      expect(actor.playedClip?.direction, EntityFacing.south);
      controller.update(const Duration(milliseconds: 119));
      expect(controller.isActorPlaying('hero'), isTrue);
      controller.update(const Duration(milliseconds: 1));

      expect(
        (await completion).status,
        CharacterCustomAnimationRuntimeStatus.completed,
      );
      expect(controller.isActorPlaying('hero'), isFalse);
      expect(actor.restoredFacing, EntityFacing.south);
      expect(actor.restoredClip?.state, CharacterAnimationState.idle);
      expect(actor.restoredClip?.direction, EntityFacing.south);
    },
  );
}

final class _GoldenRuntimeActor
    implements CharacterCustomAnimationRuntimeActor {
  _GoldenRuntimeActor({
    required this.root,
    required this.catalog,
    required this.character,
  });

  final Directory root;
  final AssetCatalog catalog;

  @override
  final ProjectCharacterEntry character;

  CharacterCustomAnimationClip? playedClip;
  CharacterAnimation? restoredClip;
  EntityFacing? restoredFacing;

  @override
  String get actorId => 'hero';

  @override
  EntityFacing get facing => EntityFacing.south;

  @override
  bool canPlayCustomAnimation(CharacterCustomAnimationClip clip) {
    final record = catalog.find(clip.sourceAssetId);
    return record != null &&
        File(p.join(root.path, assetBlobStorageKey(record.artifact)))
            .existsSync();
  }

  @override
  void playCustomAnimation(CharacterCustomAnimationClip clip) {
    playedClip = clip;
  }

  @override
  void restoreBase(EntityFacing facing) {
    restoredFacing = facing;
    restoredClip = character.animations.singleWhere(
      (clip) =>
          clip.state == CharacterAnimationState.idle &&
          clip.direction == facing,
    );
  }
}

final class _GoldenRuntimeFixture {
  const _GoldenRuntimeFixture({
    required this.root,
    required this.projectFile,
    required this.dialogueFile,
    required this.portraitBlob,
    required this.catalog,
  });

  final Directory root;
  final File projectFile;
  final File dialogueFile;
  final File portraitBlob;
  final AssetCatalog catalog;

  static Future<_GoldenRuntimeFixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'character-studio-golden-runtime-',
    );
    final portraitBytes = _png(width: 64, height: 64, marker: 1);
    final animationBytes = _png(width: 64, height: 64, marker: 2);
    final portraitArtifact = ContentArtifactRef.fromBytes(
      portraitBytes,
      mediaType: 'image/png',
    );
    final animationArtifact = ContentArtifactRef.fromBytes(
      animationBytes,
      mediaType: 'image/png',
    );
    final catalog = AssetCatalog(
      records: <AssetRecord>[
        AssetRecord(
          id: 'elia-surprise',
          logicalPath: 'assets/characters/elia/surprise.png',
          artifact: portraitArtifact,
          tags: const <String>[
            'character-studio',
            'character-studio:portrait',
          ],
        ),
        AssetRecord(
          id: 'elia-saluer',
          logicalPath: 'assets/characters/elia/saluer.png',
          artifact: animationArtifact,
          tags: const <String>[
            'character-studio',
            'character-studio:spriteSheet',
          ],
        ),
      ],
    );
    final character = ProjectCharacterEntry(
      id: 'elia',
      name: 'Élia',
      tilesetId: 'characters',
      portraits: const <CharacterPortraitVariant>[
        CharacterPortraitVariant(
          portraitStateId: 'surprise',
          assetId: 'elia-surprise',
          fitMode: CharacterPortraitFitMode.contain,
        ),
      ],
      animations: <CharacterAnimation>[
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: direction,
            sourceAssetId: 'elia-saluer',
            frames: <CharacterAnimationFrame>[_frame(direction)],
          ),
      ],
      customAnimations: <CharacterCustomAnimationClip>[
        for (final direction in EntityFacing.values)
          CharacterCustomAnimationClip(
            definitionId: 'saluer',
            direction: direction,
            sourceAssetId: 'elia-saluer',
            frames: <CharacterAnimationFrame>[_frame(direction)],
            loop: false,
          ),
      ],
    );
    final command = CharacterCustomAnimationRuntimeCommand(
      actorId: 'hero',
      definitionId: 'saluer',
      direction: EntityFacing.south,
    );
    final manifest = ProjectManifest(
      name: 'Character Studio Golden Runtime',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'characters',
          name: 'Personnages',
          relativePath: 'assets/characters.png',
        ),
      ],
      dialogues: const <ProjectDialogueEntry>[
        ProjectDialogueEntry(
          id: 'dialogue.intro',
          name: 'Introduction',
          relativePath: 'dialogues/dialogue.intro.json',
          defaultStartNode: 'Start',
        ),
      ],
      characterStudioCatalog: const ProjectCharacterStudioCatalog(
        portraitStates: <CharacterPortraitStateDefinition>[
          CharacterPortraitStateDefinition(
            id: 'surprise',
            displayName: 'Surprise',
          ),
        ],
        customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
          CharacterCustomAnimationDefinition(
            id: 'saluer',
            displayName: 'Saluer',
            mode: CharacterCustomAnimationMode.directional,
          ),
        ],
      ),
      characters: <ProjectCharacterEntry>[character],
      settings: const ProjectSettings(defaultPlayerCharacterId: 'elia'),
      cinematics: <CinematicAsset>[
        CinematicAsset(
          id: 'cine_saluer',
          title: 'Élia salue le joueur',
          requiredActors: <CinematicActorRef>[
            CinematicActorRef(actorId: 'hero'),
          ],
          timeline: CinematicTimeline(
            steps: <CinematicTimelineStep>[
              buildCinematicCharacterCustomAnimationStep(
                id: 'saluer_step',
                command: command,
              ),
            ],
          ),
        ),
      ],
    );
    final projectFile = File(p.join(root.path, 'project.json'));
    await projectFile.writeAsString(jsonEncode(manifest.toJson()), flush: true);
    final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(jsonEncode(catalog.toJson()), flush: true);
    final portraitBlob = await _writeBlob(
      root,
      portraitArtifact,
      portraitBytes,
    );
    await _writeBlob(root, animationArtifact, animationBytes);
    final dialogueFile = File(
      p.join(root.path, 'dialogues', 'dialogue.intro.json'),
    );
    await dialogueFile.parent.create(recursive: true);
    final dialogue = const YarnDialogueCompiler().compile('''
title: Start
---
<<portrait elia surprise>>
Élia: Attends… tu as vu ça ?
===
''');
    await dialogueFile.writeAsBytes(
      const RuntimeDialogueDocumentCodec().encodeUtf8(dialogue),
      flush: true,
    );
    return _GoldenRuntimeFixture(
      root: root,
      projectFile: projectFile,
      dialogueFile: dialogueFile,
      portraitBlob: portraitBlob,
      catalog: catalog,
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

CharacterAnimationFrame _frame(EntityFacing direction) {
  final index = EntityFacing.values.indexOf(direction);
  return CharacterAnimationFrame(
    source: TilesetSourceRect(x: index * 16, y: 0, width: 16, height: 16),
    durationMs: 120,
  );
}

Future<File> _writeBlob(
  Directory root,
  ContentArtifactRef artifact,
  List<int> bytes,
) async {
  final file = File(p.join(root.path, assetBlobStorageKey(artifact)));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

List<int> _png({
  required int width,
  required int height,
  required int marker,
}) {
  final bytes = List<int>.filled(25, 0);
  bytes.setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.setRange(12, 16, const <int>[73, 72, 68, 82]);
  bytes.setRange(16, 20, _uint32(width));
  bytes.setRange(20, 24, _uint32(height));
  bytes[24] = marker;
  return bytes;
}

List<int> _uint32(int value) => <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
