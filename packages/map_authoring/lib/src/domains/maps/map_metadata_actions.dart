import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../assets/tileset_actions.dart';
import 'map_lifecycle_adapter.dart';

AuthoringMutationDraft updateMapMetadata(AuthoringPlanningContext context) {
  final parameters = VisualLibraryParameters(context.request.parameters);
  parameters.allow(const {'mapId', 'name'});
  final mapId = parameters.string('mapId');
  final rawName = context.request.parameters['name'];
  if (rawName is! String ||
      rawName.trim().isEmpty ||
      rawName.trim().length > 160) {
    throw MapAuthoringException(
        code: 'map.name_invalid',
        message: 'Map names must contain 1 to 160 nonblank characters.');
  }
  final name = rawName.trim();
  final snapshot = context.snapshot;
  final entry =
      snapshot.manifest.maps.where((map) => map.id == mapId).firstOrNull;
  if (entry == null) {
    throw MapAuthoringException(
        code: 'map.not_found', message: 'The requested map does not exist.');
  }
  final before = snapshot.mapById(mapId);
  if (before == null || before.id != entry.id) {
    throw MapAuthoringException(
        code: 'map.document_missing',
        message:
            'The requested map document is unavailable or has another identity.');
  }
  if (entry.name.trim() == name && before.name.trim() == name) {
    throw MapAuthoringException(
        code: 'map.no_change', message: 'The requested title changes nothing.');
  }
  final updated = before.copyWith(name: name);
  final manifest = snapshot.manifest.copyWith(maps: [
    for (final candidate in snapshot.manifest.maps)
      if (candidate.id == mapId) candidate.copyWith(name: name) else candidate,
  ]);
  ProjectValidator.validate(manifest);
  MapValidator.validate(updated, projectDialogueContext: manifest);
  final map = AuthoringResourceRef(
      kind: 'map',
      id: mapId,
      revision: snapshot.resourceFingerprints['map:$mapId']);
  final project = AuthoringResourceRef(
      kind: 'project',
      id: 'project',
      revision: snapshot.resourceFingerprints['project']);
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
              resource: map,
              storageKey: entry.relativePath,
              beforeBytes: snapshot.resourceBytes('map:$mapId'),
              afterBytes: encodeMapAuthoringDocument(updated)),
          AuthoringResourceChange(
              resource: project,
              storageKey: 'project.json',
              beforeBytes: snapshot.resourceBytes('project'),
              afterBytes: encodeProjectAuthoringDocument(snapshot, manifest)),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: map,
              path: '/name',
              before: before.name,
              after: name),
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: project,
              path: '/maps/$mapId/name',
              before: entry.name,
              after: name),
        ])),
    preview: {
      'operation': 'update_metadata',
      'mapId': mapId,
      'name': name,
      'storageGuarantee': 'recoverable'
    },
    referenceImpact: const {'identityUnchanged': true, 'pathUnchanged': true},
  );
}
