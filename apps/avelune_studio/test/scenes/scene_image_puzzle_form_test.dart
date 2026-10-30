import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('Studio canonical publication retains unrelated catalog scenes after reopening', () async {
    final qa = Directory(
      '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/puzzle-authoring',
    );
    await qa.create(recursive: true);
    final root = await qa.createTemp('studio-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final scene = SceneAsset(
      id: 'puzzle',
      name: 'Puzzle',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'open',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openImagePuzzle(
                definition: ImagePuzzleDefinition(
                  puzzleId: 'mosaic',
                  imageResourceId: 'image',
                  rows: 2,
                  columns: 2,
                ),
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'enter',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'open',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final port in ['solved', 'quit'])
            SceneEdge(
              id: port,
              fromNodeId: 'open',
              fromPortId: port,
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
        ],
      ),
    );
    final unrelated = [
      for (var i = 0; i < 128; i++)
        SceneAsset(
          id: 'other-$i',
          name: 'Other $i',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          ),
        ),
    ];
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'puzzle',
      project: ProjectManifest(
        name: 'Puzzle',
        maps: [],
        tilesets: [],
        scenes: [scene, ...unrelated],
      ),
    );
    await Directory('${root.path}/assets').create();
    await File('${root.path}/assets/.pokemap-media.json').writeAsString(
      jsonEncode(
        ProjectMediaCatalog(
          entries: [
            ProjectMediaAsset(
              id: 'image',
              label: 'Mosaïque',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'source',
            ),
          ],
        ).toJson(),
      ),
    );
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Puzzle',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final adapter = LocalMapWorkspaceAdapter();
    await adapter.loadProject(session);
    final changed = SceneAsset.fromJson({
      ...scene.toJson(),
      'name': 'Puzzle guidé',
    });
    final receipt = await LocalSceneAdapter(
      session: session,
      mapAdapter: adapter,
    ).publishScene(base: scene, current: changed);
    expect(receipt.catalog.manifest.scenes, [changed, ...unrelated]);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(session);
    expect(reopened.scenes, [changed, ...unrelated]);
  });
  testWidgets(
    'Studio reopens the complete puzzle with guided image and placement fields',
    (tester) async {
      final definition = ImagePuzzleDefinition(
        puzzleId: 'mosaic',
        imageResourceId: 'image',
        rows: 2,
        columns: 2,
        trayCapacity: 2,
        allowedQuarterTurns: [0, 2],
        fixedPieceIds: [0],
        allowReset: false,
        allowSwap: true,
        initialPieces: [
          ImagePuzzlePiece(pieceId: 0, slot: 0),
          ImagePuzzlePiece(pieceId: 1, slot: 2, quarterTurns: 2),
          ImagePuzzlePiece(pieceId: 2, slot: 4),
          ImagePuzzlePiece(pieceId: 3, slot: 3),
        ],
      );
      SceneNodePayload? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionForm(
                project: const ProjectManifest(
                  name: 'Puzzle',
                  maps: [],
                  tilesets: [],
                ),
                current: SceneActionPayload.interactive(
                  SceneInteractiveCommand.openImagePuzzle(
                    definition: definition,
                  ),
                ),
                loadVisualMedia: () async => ProjectMediaCatalog(
                  entries: [
                    ProjectMediaAsset(
                      id: 'image',
                      label: 'Mosaïque choisie',
                      kind: ProjectMediaKind.image,
                      sourceAssetId: 'image-source',
                    ),
                    ProjectMediaAsset(
                      id: 'sound',
                      label: 'Son exclu',
                      kind: ProjectMediaKind.audio,
                      sourceAssetId: 'sound-source',
                    ),
                  ],
                ),
                onApply: (value) => result = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('puzzle-piece-0-fixed')),
        findsOneWidget,
      );
      final imagePicker = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('puzzle-image')),
      );
      expect(imagePicker.options, {'image': 'Mosaïque choisie'});
      final apply = find.byKey(const ValueKey('puzzle-apply'));
      expect(tester.widget<StudioButton>(apply).onPressed, isNotNull);
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      expect(
        ((result as SceneActionPayload).interactiveCommand
                as SceneOpenImagePuzzleInteractiveCommand)
            .definition,
        definition,
      );
    },
  );
}
