import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'guided puzzle builder reloads the complete definition and catalog image',
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
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionBuilder(
                initialPayload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.openImagePuzzle(
                    definition: definition,
                  ),
                ),
                project: const ProjectManifest(
                  name: 'Puzzle',
                  maps: [],
                  tilesets: [],
                ),
                pickerOptions: const {
                  NarrativeCommandParameterKind.imageMediaReference: [
                    SceneActionPickerOption(
                      id: 'image',
                      label: 'Mosaïque choisie',
                    ),
                  ],
                },
                onSubmit: (payload) => result = payload,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Mosaïque choisie'), findsWidgets);
      expect(
        find.byKey(const ValueKey('puzzle-piece-0-fixed')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('puzzle-piece-1-slot')), findsOneWidget);
      final button = find.byKey(const ValueKey('scene-action-submit'));
      expect(tester.widget<PokeMapButton>(button).onPressed, isNotNull);
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(
        ((result as SceneActionPayload).interactiveCommand
                as SceneOpenImagePuzzleInteractiveCommand)
            .definition,
        definition,
      );
    },
  );
}
