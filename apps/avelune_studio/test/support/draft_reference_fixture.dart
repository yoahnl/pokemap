import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

class DraftReferenceProject {
  DraftReferenceProject._(this.directory, this.maps);

  final Directory directory;
  final MapWorkspaceController maps;
  final ruleTargets = <MapDraftReference>[];

  static Future<DraftReferenceProject> create() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_draft_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    final maps = MapWorkspaceController(
      ProjectSession(
        sessionId: directory.path,
        name: 'Brouillons',
        directoryPath: directory.path,
      ),
      LocalMapWorkspaceAdapter(),
    );
    await maps.initialize();
    return DraftReferenceProject._(directory, maps);
  }

  MapDraftReferenceSources sources() =>
      MapDraftReferenceSources(ruleTargets: [...ruleTargets]);

  void targetEntity(String mapId, String entityId) => ruleTargets.add((
    mapId: mapId,
    kind: MapDraftReferenceKind.entity,
    id: entityId,
  ));

  Future<void> activate(String mapId) => maps.activate(
    maps.project!.maps.firstWhere((entry) => entry.id == mapId),
  );

  Future<MapEntity> signOn(String mapId) async {
    await activate(mapId);
    return MapEntityEditingCommands(
      maps.active!,
      maps.project!,
    ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
  }

  Future<void> dispose() async {
    maps.dispose();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
