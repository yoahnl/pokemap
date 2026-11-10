import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
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
