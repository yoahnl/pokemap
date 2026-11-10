import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_healing_display_draft.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _entity = MapEntity(
  id: 'healing',
  name: 'Boules',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 2, y: 2),
  blocksMovement: false,
  properties: {'source': 'preserved'},
);
ProjectManifest _project() => workspaceProject.copyWith(
  tilesets: [
    for (var sheet = 1; sheet <= 2; sheet++)
      ProjectTilesetEntry(
        id: 'sheet-$sheet',
        name: 'Sheet',
        relativePath: 'sheet-$sheet.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'sheet-$sheet',
          pixelWidth: 256,
          pixelHeight: 192,
          tileWidth: 64,
          tileHeight: 48,
        ),
      ),
  ],
  elements: [
    for (var n = 1; n <= 6; n++)
      ProjectElementEntry(
        id: 'balls-$n',
        name: 'Boules $n',
        tilesetId: 'sheet-${n <= 3 ? 1 : 2}',
        categoryId: 'props',
        frames: [
          for (var x = 0; x < 4; x++)
            TilesetVisualFrame(
              source: TilesetSourceRect(x: x, y: (n - 1) % 3 + 1),
              durationMs: 125,
            ),
        ],
      ),
  ],
);
void main() {
  test(
    'six native healing variants preserve undo redo and serialized reopen',
    () {
      final original = workspaceMap('a').copyWith(entities: [_entity]);
      final project = _project();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: original, revision: 'base', mapId: 'a'),
      );
      final draft = MapHealingDisplayDraft(original, project, _entity);
      expect(draft.canConfigure, isTrue);
      expect(draft.candidates, hasLength(6));
      for (var n = 1; n <= 6; n++) {
        draft.variants[n - 1] = 'balls-$n';
        if (n == 2) {
          draft.variants[n - 1] = 'balls-1';
          expect(draft.valid, isFalse);
          expect(draft.value, isNull);
          expect(document.current, same(original));
          draft.variants[n - 1] = 'balls-$n';
        }
      }
      expect(draft.valid, isTrue);
      final commands = MapEntityEditingCommands(document, project);
      commands.setHealingDisplay(_entity.id, draft.value);
      final expected = MapEntityHealingDisplayData(
        variantElementIds: [for (var n = 1; n <= 6; n++) 'balls-$n'],
      );
      expect(document.current.entities.single.healingDisplay, expected);
      expect(
        document.current.entities.single.copyWith(healingDisplay: null),
        _entity,
      );
      expect(
        MapData.fromJson(document.current.toJson())
            .entities
            .single
            .healingDisplay,
        expected,
      );
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current, original);
      document.restore(redo: true);
      expect(document.current.entities.single.healingDisplay, expected);
      commands.setHealingDisplay(_entity.id, null);
      expect(document.current, original);
    },
  );

  for (final mode in ['blocking', 'wide', 'collision', 'visual', 'spatial']) {
    test('healing authoring refuses $mode target', () {
      var entity = _entity;
      var map = workspaceMap('a');
      if (mode == 'blocking') entity = entity.copyWith(blocksMovement: true);
      if (mode == 'wide') {
        entity = entity.copyWith(size: const GridSize(width: 2, height: 1));
      }
      if (mode == 'collision') {
        entity = entity.copyWith(properties: {'collision.width': '1'});
      }
      if (mode == 'visual') {
        entity = entity.copyWith(
          editorVisual: const MapEntityEditorVisual(elementId: 'balls-1'),
        );
      }
      if (mode == 'spatial') {
        map = map.copyWith(
          version: ProjectVersion.v9,
          spatialScene: MapSpatialScene(
            width: map.size.width,
            depth: map.size.height,
          ),
        );
      }
      map = map.copyWith(entities: [entity]);
      expect(
        MapHealingDisplayDraft(map, _project(), entity).canConfigure,
        isFalse,
      );
      expect(map.entities.single.healingDisplay, isNull);
    });
  }

  test('healing candidates require six matching native geometries and unique sources', () {
    final project = _project();
    final map = workspaceMap('a').copyWith(entities: [_entity]);
    final tooFew = project.copyWith(
      elements: project.elements.take(5).toList(),
    );
    expect(MapHealingDisplayDraft(map, tooFew, _entity).candidates, isEmpty);
    final duplicate = project.copyWith(
      elements: [...project.elements, project.elements.first],
    );
    expect(
      MapHealingDisplayDraft(
        map,
        duplicate,
        _entity,
      ).geometry(project.elements.first),
      isNull,
    );
    final invalidFrames = project.elements.first.copyWith(
      frames: [
        const TilesetVisualFrame(source: TilesetSourceRect(x: 100, y: 100)),
      ],
    );
    final invalid = project.copyWith(
      elements: [invalidFrames, ...project.elements.skip(1)],
    );
    expect(MapHealingDisplayDraft(map, invalid, _entity).candidates, isEmpty);
  });
  test(
    'catalogue refresh preserves choices and rejects removed native resources',
    () {
      final project = _project();
      final map = workspaceMap('a').copyWith(entities: [_entity]);
      final draft = MapHealingDisplayDraft(map, project, _entity);
      for (var n = 1; n <= 6; n++) {
        draft.variants[n - 1] = 'balls-$n';
      }
      expect(draft.valid, isTrue);
      final choices = [...draft.variants];
      draft.updateContext(
        map,
        project.copyWith(elements: project.elements.skip(1).toList()),
      );
      expect(draft.variants, choices);
      expect(draft.valid, isFalse);
      expect(draft.value, isNull);
      draft.updateContext(map, project);
      expect(draft.valid, isTrue);
      expect(draft.value!.variantElementIds, choices);
    },
  );
}
