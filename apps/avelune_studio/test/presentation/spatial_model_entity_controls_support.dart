import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:map_core/map_core.dart';

EditableMapDocument entityDocument(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, mapId: map.id, revision: 'initial'),
);
