import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:path/path.dart' as p;

import 'game_export/game_export_test_fixture.dart';

void main() {
  test(
    'CHS-052 authors, reopens, exports and relocates the complete golden slice',
    () async {
      final root = await createAuthorProject(
        name: 'Character Studio Golden Slice',
      );
      final moved = await Directory.systemTemp.createTemp(
        'character-studio-golden-moved-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
        if (await moved.exists()) await moved.delete(recursive: true);
      });
      await _prepareNarrativeFixture(root);
      final harness = await _CharacterStudioGoldenHarness.create(root);
      addTearDown(harness.dispose);

      final portrait = File(p.join(root.path, 'elia-surprise.png'));
      final animation = File(p.join(root.path, 'elia-saluer.png'));
      await portrait.writeAsBytes(onePixelPng, flush: true);
      await animation.writeAsBytes(_png(width: 64, height: 64), flush: true);
      final portraitArtifact = await harness.mutations.stageArtifactFile(
        sourcePath: portrait.path,
        declaredMediaType: 'image/png',
      );
      final animationArtifact = await harness.mutations.stageArtifactFile(
        sourcePath: animation.path,
        declaredMediaType: 'image/png',
      );

      await harness.apply(
        'characterStudio.portraitState.create',
        <String, Object?>{'displayName': 'Surprise'},
      );
      await harness.apply('characterStudio.character.create', <String, Object?>{
        'name': 'Élia',
        'tilesetId': 'characters',
        'frameWidth': 1,
        'frameHeight': 1,
        'tags': <String>['héroïne'],
      });
      await harness.apply(
        'characterStudio.character.setDefault',
        <String, Object?>{'characterId': 'elia'},
      );
      await harness.apply('characterStudio.asset.import', <String, Object?>{
        'artifactHandle': portraitArtifact.reference.handle,
        'assetId': 'elia-surprise',
        'logicalPath': 'assets/characters/elia/surprise.png',
        'mediaKind': 'portrait',
      });
      await harness
          .apply('characterStudio.character.portrait.assign', <String, Object?>{
            'characterId': 'elia',
            'portraitStateId': 'surprise',
            'assetId': 'elia-surprise',
            'fitMode': 'contain',
          });
      await harness.apply('characterStudio.asset.import', <String, Object?>{
        'artifactHandle': animationArtifact.reference.handle,
        'assetId': 'elia-saluer',
        'logicalPath': 'assets/characters/elia/saluer.png',
        'mediaKind': 'spriteSheet',
      });
      await harness.apply(
        'characterStudio.animationDefinition.create',
        <String, Object?>{'displayName': 'Saluer', 'mode': 'directional'},
      );
      for (final direction in EntityFacing.values) {
        await harness.apply(
          'characterStudio.animationClip.upsert',
          <String, Object?>{
            'characterId': 'elia',
            'kind': 'system',
            'state': 'base',
            'direction': direction.name,
            'sourceAssetId': 'elia-saluer',
            'loop': true,
            'frames': <Object?>[_frame(direction).toJson()],
          },
        );
        await harness.apply(
          'characterStudio.animationClip.upsert',
          <String, Object?>{
            'characterId': 'elia',
            'kind': 'custom',
            'definitionId': 'saluer',
            'direction': direction.name,
            'sourceAssetId': 'elia-saluer',
            'loop': false,
            'frames': <Object?>[_frame(direction).toJson()],
          },
        );
      }
      await harness
          .apply('cinematic.character_animation.upsert', <String, Object?>{
            'cinematicId': 'cine_saluer',
            'label': 'Élia salue le joueur',
            'runtimeCommand': CharacterCustomAnimationRuntimeCommand(
              actorId: 'hero',
              definitionId: 'saluer',
              direction: EntityFacing.south,
            ).toJson(),
          });

      await harness.reopen();
      final query = await harness.readApi.query(
        harness.project,
        AuthoringQueryRequest(
          resourceKind: 'characterStudioCharacter',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );
      expect(query['items'], hasLength(1));
      final reopened = await _readManifest(root);
      final elia = reopened.characters.single;
      expect(reopened.version, ProjectVersion.v6);
      expect(reopened.settings.defaultPlayerCharacterId, 'elia');
      expect(
        reopened.characterStudioCatalog.portraitStates.single.id,
        'surprise',
      );
      expect(
        reopened.characterStudioCatalog.customAnimationDefinitions.single.id,
        'saluer',
      );
      expect(elia.portraits.single.portraitStateId, 'surprise');
      expect(elia.animations, hasLength(4));
      expect(elia.customAnimations, hasLength(4));
      expect(
        elia.customAnimations.map((clip) => clip.direction).toSet(),
        EntityFacing.values.toSet(),
      );
      final command = cinematicCharacterCustomAnimationCommandOf(
        reopened.cinematics.single.timeline.steps.last,
      );
      expect(command?.definitionId, 'saluer');
      expect(command?.direction, EntityFacing.south);

      final artifact = await const GamePackageExportService().build(
        projectRoot: root,
        profile: neutralExportProfile(
          gameId: 'games.pokemap.characterstudiogolden',
          title: 'Character Studio Golden Slice',
          version: '1.0.0',
        ),
      );
      expect(artifact.certification.isCertified, isTrue);
      expect(artifact.compiledDialogueCount, 1);
      expect(
        artifact.inspection.payloadPaths,
        contains('project/$assetCatalogStorageKey'),
      );

      final projection = await const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile(
          gameId: 'games.pokemap.characterstudiogolden',
          title: 'Character Studio Golden Slice',
          version: '1.0.0',
        ),
      );
      await _materializeRuntimeProject(projection, moved);
      final relocated = await _readManifest(moved);
      final compiled = const RuntimeDialogueDocumentCodec().decodeUtf8(
        await File(
          p.join(moved.path, 'dialogues', 'dialogue.intro.json'),
        ).readAsBytes(),
      );
      final line = compiled.nodes.single.steps
          .whereType<RuntimeDialogueLine>()
          .first;
      expect(line.characterId, 'elia');
      expect(line.portraitStateId, 'surprise');
      expect(relocated.characters.single.customAnimations, hasLength(4));
      final resolver = CharacterStudioMediaResolver(
        source: const FileCharacterStudioMediaSource(),
      );
      expect(
        await resolver.resolve(
          CharacterStudioMediaRequest(
            projectRootPath: moved.path,
            assetId: 'elia-surprise',
            projectRevision: 'relocated-v1',
          ),
        ),
        onePixelPng,
      );
      expect(
        await resolver.resolve(
          CharacterStudioMediaRequest(
            projectRootPath: moved.path,
            assetId: 'elia-saluer',
            projectRevision: 'relocated-v1',
          ),
        ),
        _png(width: 64, height: 64),
      );
      expect(
        projection.payloadFiles.values
            .map((bytes) => utf8.decode(bytes, allowMalformed: true))
            .join(),
        isNot(contains(root.path)),
      );
    },
  );
}

final class _CharacterStudioGoldenHarness {
  _CharacterStudioGoldenHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.workspace,
    required this.project,
  });

  static Future<_CharacterStudioGoldenHarness> create(Directory root) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: LocalArtifactStore(
        allowedSourceRoots: <String>[root.path],
        maximumArtifactBytes: 1024 * 1024,
      ),
    );
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    return _CharacterStudioGoldenHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      workspace: workspace,
      project: project,
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  WorkspaceHandle workspace;
  ProjectHandle project;
  var _operation = 0;

  Future<void> apply(String actionId, Map<String, Object?> parameters) async {
    final index = _operation++;
    final snapshot = await snapshots.load(project);
    final plan = await mutations.planMutation(
      project,
      AuthoringRequest(
        requestId: 'golden-$index',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'golden-idempotency-$index',
      ),
    );
    await mutations.applyMutation(
      project,
      planId: plan.plan.planId,
      operationId: 'golden-operation-$index',
    );
  }

  Future<void> reopen() async {
    await mutations.detachWorkspace(workspace);
    await readApi.close(workspace);
    final opened = await readApi.open(root.path);
    workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(workspace);
    await readApi.close(workspace);
  }
}

Future<void> _prepareNarrativeFixture(Directory root) async {
  final manifest = await _readManifest(root);
  final prepared = manifest.copyWith(
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Personnages',
        relativePath: 'assets/icon.png',
      ),
    ],
    cinematics: <CinematicAsset>[
      CinematicAsset(
        id: 'cine_saluer',
        title: 'Élia salue le joueur',
        requiredActors: <CinematicActorRef>[CinematicActorRef(actorId: 'hero')],
        stageContext: CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'hero',
              kind: CinematicActorBindingKind.player,
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'intro_wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
            ),
          ],
        ),
      ),
    ],
  );
  await File(
    p.join(root.path, 'project.json'),
  ).writeAsString(jsonEncode(prepared.toJson()), flush: true);
  await File(p.join(root.path, 'dialogues', 'intro.yarn')).writeAsString('''
title: Start
---
<<portrait elia surprise>>
Élia: Attends… tu as vu ça ?
===
''', flush: true);
}

CharacterAnimationFrame _frame(EntityFacing direction) {
  final index = EntityFacing.values.indexOf(direction);
  return CharacterAnimationFrame(
    source: TilesetSourceRect(x: index * 16, y: 0, width: 16, height: 16),
    durationMs: 120,
  );
}

Future<ProjectManifest> _readManifest(Directory root) async =>
    ProjectManifest.fromJson(
      jsonDecode(await File(p.join(root.path, 'project.json')).readAsString())
          as Map<String, dynamic>,
    );

Future<void> _materializeRuntimeProject(
  RuntimeProjectProjection projection,
  Directory targetRoot,
) async {
  for (final entry in projection.payloadFiles.entries) {
    if (!entry.key.startsWith('project/')) continue;
    final target = File(
      p.join(targetRoot.path, entry.key.substring('project/'.length)),
    );
    await target.parent.create(recursive: true);
    await target.writeAsBytes(entry.value, flush: true);
  }
}

List<int> _png({required int width, required int height}) {
  final bytes = List<int>.filled(24, 0);
  bytes.setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.setRange(12, 16, const <int>[73, 72, 68, 82]);
  bytes.setRange(16, 20, _uint32(width));
  bytes.setRange(20, 24, _uint32(height));
  return bytes;
}

List<int> _uint32(int value) => <int>[
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];
