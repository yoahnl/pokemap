import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_character_gesture.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _preset = ProjectSmartTilePreset(
  id: 'grass',
  name: 'Herbe',
  usage: SmartTileUsage.terrain,
  topology: SmartTileTopology.uniform,
  templateHint: SmartTileTemplateHint.simple,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'grass',
  allowedMaterialIds: ['grass'],
);

void main() {
  for (final dimension in ProjectDimension.values) {
    group(dimension.name, () {
      late ProjectManifest project;
      late EditableMapDocument document;
      late MapWorkspaceEditingState state;

      setUp(() {
        project = ProjectManifest(
          version: dimension == ProjectDimension.threeD
              ? ProjectVersion.v9
              : ProjectVersion.v8,
          name: 'Sessions',
          settings: ProjectSettings(
            dimension: dimension,
            spatialCamera: dimension == ProjectDimension.threeD
                ? SpatialCameraProfile()
                : null,
          ),
          tilesets: const [],
          maps: const [
            ProjectMapEntry(
              id: 'map',
              name: 'Carte',
              relativePath: 'maps/map.json',
            ),
          ],
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: [
              ProjectSmartTileMaterial(
                id: 'grass',
                name: 'Herbe',
                connectionGroupId: 'grass',
              ),
            ],
            presets: [_preset],
          ),
        );
        final map = MapData(
          version: dimension == ProjectDimension.threeD
              ? ProjectVersion.v9
              : ProjectVersion.v8,
          id: 'map',
          name: 'Carte',
          size: const GridSize(width: 6, height: 5),
          spatialScene: dimension == ProjectDimension.threeD
              ? MapSpatialScene(width: 6, depth: 5)
              : null,
        );
        document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'saved'),
        );
        state = MapWorkspaceEditingState();
      });

      test('selection keeps map identity without changing history', () {
        final marker = MapEntityEditingCommands(
          document,
          project,
        ).place(MapEntityKind.sign, const GridPos(x: 1, y: 1));
        final source = document.current;
        final count = document.undoCount;

        state.select(document, MapSelectionFamily.marker, marker.id);

        expect(state.selectedFor('map', MapSelectionFamily.marker), marker.id);
        expect(
          state.selectedFor('other-map', MapSelectionFamily.marker),
          isNull,
        );
        expect(state.selectedFor('map', MapSelectionFamily.decor), isNull);
        expect(document.current, same(source));
        expect(document.undoCount, count);
        state.clearSelection(document);
        expect(state.target, isNull);
        expect(document.current, same(source));
      });

      test('entity gesture previews and commits once without a widget', () {
        final marker = MapEntityEditingCommands(
          document,
          project,
        ).place(MapEntityKind.sign, const GridPos(x: 1, y: 1));
        final source = document.current;
        final count = document.undoCount;
        final gesture = MapCharacterGesture.start(
          document: document,
          project: project,
          view: state,
          origin: marker.pos,
        )!;

        gesture.move(const GridPos(x: 4, y: 2));

        expect(document.current, same(source));
        expect(gesture.preview.entities.single.pos, const GridPos(x: 4, y: 2));
        gesture.commit();
        expect(document.current.entities.single.pos, const GridPos(x: 4, y: 2));
        expect(document.undoCount, count + 1);
        document.restore(redo: false);
        expect(document.current, source);
      });

      test('terrain session interpolates and preserves one undo entry', () {
        final source = document.current;
        state
          ..terrain = _preset
          ..tool = StudioMapTool.terrain;
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: state,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 1, y: 2),
        )!;

        stroke.paint(const GridPos(x: 4, y: 2));

        expect(document.current, same(source));
        final preview = stroke.materialize(validate: false);
        expect(
          smartTileSemanticCells(
            preview.layers.whereType<SmartTileLayer>().single,
          ).where((value) => value != 0),
          hasLength(4),
        );
        document.commit(stroke.commit());
        expect(document.undoCount, 1);
        expect(document.current.spatialScene, source.spatialScene);
        document.restore(redo: false);
        expect(document.current, source);
      });

      test('out of bounds gesture leaves the document untouched', () {
        final source = document.current;
        state
          ..terrain = _preset
          ..tool = StudioMapTool.terrain;

        expect(
          MapCanvasStroke.start(
            map: source,
            project: project,
            view: state,
            commands: MapEditingCommands(document, project),
            origin: const GridPos(x: -1, y: 2),
          ),
          isNull,
        );
        expect(
          MapCharacterGesture.start(
            document: document,
            project: project,
            view: state,
            origin: const GridPos(x: 6, y: 2),
          ),
          isNull,
        );
        expect(document.current, same(source));
        expect(document.undoCount, 0);
        expect(document.dirty, isFalse);
      });
    });
  }
}
