import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final definition = ImagePuzzleDefinition(
    puzzleId: 'mosaic',
    imageResourceId: 'mosaic-image',
    rows: 2,
    columns: 3,
  );
  test('guided puzzle parameters preserve the complete layout and reject hidden identity overrides', () {
    final parameters = {'puzzleId': 'mosaic', 'imageResourceId': 'mosaic-image', 'rows': '2', 'columns': '3', 'trayCapacity': '1', 'layout': jsonEncode({'allowedQuarterTurns': [0, 2], 'fixedPieceIds': [0], 'initialPieces': [for (var id = 0; id < 6; id++) {'pieceId': id, 'slot': id == 1 ? 6 : id, 'quarterTurns': 0}]})};
    final built = buildScenePayloadForNarrativeCommand(commandId: NarrativeCommandIds.openImagePuzzle, parameters: parameters) as SceneActionPayload;
    final puzzle = (built.interactiveCommand as SceneOpenImagePuzzleInteractiveCommand).definition;
    expect(puzzle.allowedQuarterTurns, [0, 2]); expect(puzzle.fixedPieceIds, [0]); expect(puzzle.initialPieces![1].slot, 6);
    expect(() => buildScenePayloadForNarrativeCommand(commandId: NarrativeCommandIds.openImagePuzzle, parameters: {...parameters, 'layout': jsonEncode({'puzzleId': 'hidden-override'})}), throwsFormatException);
  });
  test('image puzzle command has verified solved and quit outcomes', () {
    final wire = {'kind': 'openImagePuzzle', 'definition': definition.toJson()};
    final command = SceneInteractiveCommand.fromJson(wire);
    expect(command.toJson(), wire);
    expect(command.outputPortIds, ['solved', 'quit']);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(
      () => SceneInteractiveCommand.fromJson({...wire, 'extra': true}),
      throwsFormatException,
    );
  });
  test(
    'image puzzle requires a known image from the project media catalog',
    () {
      final command = SceneInteractiveCommand.fromJson({
        'kind': 'openImagePuzzle',
        'definition': definition.toJson(),
      });
      const project = ProjectManifest(name: 'Puzzle', maps: [], tilesets: []);
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
              payload: SceneActionPayload.interactive(command),
            ),
          ],
        ),
      );
      bool invalid(ProjectMediaCatalog? media) =>
          diagnoseSceneAgainstProject(
            scene,
            project,
            presentationMediaCatalog: media,
          ).diagnostics.any(
            (diagnostic) =>
                diagnostic.code ==
                SceneDiagnosticCode.commandUnknownPictureMedia,
          );
      expect(invalid(null), isTrue);
      final media = ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'mosaic-image',
            label: 'Mosaïque',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'mosaic-source',
          ),
        ],
      );
      expect(invalid(media), isFalse);
    },
  );
}
