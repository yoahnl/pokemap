import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:map_core/map_core.dart';

EditableMapDocument borderDocument(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
);

MapBorderDrawingDraft borderDraft(MapData map, ProjectManifest project) =>
    MapBorderDrawingDraft.start(
      mapId: map.id,
      mapSize: map.size,
      blueprintId: 'fence',
      origin: const GridPos(x: 2, y: 5),
      sourceMap: map,
      sourceProject: project,
      featureId: 'test-border',
      seed: BorderSignedInt64.fromInt(17),
    ).addAngle(const GridPos(x: 5, y: 5)).addAngle(const GridPos(x: 5, y: 7));
