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
  parameters.allow(const {'mapId', 'name', 'role', 'isIndoor'});
  final mapId = parameters.string('mapId');
  final values = context.request.parameters;
  final hasName = values.containsKey('name');
  final hasRole = values.containsKey('role');
  final hasIndoor = values.containsKey('isIndoor');
  if (!hasName && !hasRole && !hasIndoor) {
    throw MapAuthoringException(
        code: 'map.metadata_empty',
        message: 'At least one map metadata field is required.');
  }
  final rawName = values['name'];
  if (hasName &&
      (rawName is! String ||
          rawName.trim().isEmpty ||
          rawName.trim().length > 160)) {
    throw MapAuthoringException(
        code: 'map.name_invalid',
        message: 'Map names must contain 1 to 160 nonblank characters.');
  }
  final name = hasName ? (rawName! as String).trim() : null;
  final rawRole = values['role'];
  final requestedRole = hasRole
      ? MapRole.values.where((role) => role.name == rawRole).firstOrNull
      : null;
  if (hasRole && requestedRole == null) {
    throw MapAuthoringException(
        code: 'map.role_invalid',
        message: 'The requested map role is unsupported.');
  }
  final rawIndoor = values['isIndoor'];
  if (hasIndoor && rawIndoor is! bool) {
    throw MapAuthoringException(
        code: 'map.indoor_invalid',
        message: 'The indoor map setting must be a boolean.');
  }
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
  var role = requestedRole ?? entry.role;
  var isIndoor = hasIndoor ? rawIndoor! as bool : before.mapMetadata.isIndoor;
  if (hasRole && !hasIndoor) {
    if (role == MapRole.interior) isIndoor = true;
    if (role == MapRole.exterior) isIndoor = false;
  }
  if (!hasRole &&
      hasIndoor &&
      (role == MapRole.interior || role == MapRole.exterior)) {
    role = isIndoor ? MapRole.interior : MapRole.exterior;
  }
  if ((hasRole || hasIndoor) &&
      ((role == MapRole.interior && !isIndoor) ||
          (role == MapRole.exterior && isIndoor))) {
    throw MapAuthoringException(
        code: 'map.metadata_inconsistent',
        message:
            'Interior and exterior map roles must match the indoor setting.',
        details: {'role': role.name, 'isIndoor': isIndoor});
  }
  final nameChanged =
      name != null && (entry.name.trim() != name || before.name.trim() != name);
  if (!nameChanged &&
      entry.role == role &&
      before.mapMetadata.isIndoor == isIndoor) {
    throw MapAuthoringException(
        code: 'map.no_change',
        message: 'The requested metadata changes nothing.');
  }
  final updated = before.copyWith(
      name: name ?? before.name,
      mapMetadata: before.mapMetadata.copyWith(isIndoor: isIndoor));
  final manifest = snapshot.manifest.copyWith(maps: [
    for (final candidate in snapshot.manifest.maps)
      if (candidate.id == mapId)
        candidate.copyWith(name: name ?? candidate.name, role: role)
      else
        candidate,
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
  final mapChanged =
      before.name != updated.name || before.mapMetadata.isIndoor != isIndoor;
  final projectChanged =
      entry.name != (name ?? entry.name) || entry.role != role;
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
        changes: [
          if (mapChanged)
            AuthoringResourceChange(
                resource: map,
                storageKey: entry.relativePath,
                beforeBytes: snapshot.resourceBytes('map:$mapId'),
                afterBytes: encodeMapAuthoringDocument(updated)),
          if (projectChanged)
            AuthoringResourceChange(
                resource: project,
                storageKey: 'project.json',
                beforeBytes: snapshot.resourceBytes('project'),
                afterBytes: encodeProjectAuthoringDocument(snapshot, manifest)),
        ],
        diff: AuthoringDiff([
          if (before.name != updated.name)
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.replace,
                resource: map,
                path: '/name',
                before: before.name,
                after: updated.name),
          if (entry.name != (name ?? entry.name))
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.replace,
                resource: project,
                path: '/maps/$mapId/name',
                before: entry.name,
                after: name),
          if (entry.role != role)
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.replace,
                resource: project,
                path: '/maps/$mapId/role',
                before: entry.role.name,
                after: role.name),
          if (before.mapMetadata.isIndoor != isIndoor)
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.replace,
                resource: map,
                path: '/mapMetadata/isIndoor',
                before: before.mapMetadata.isIndoor,
                after: isIndoor),
        ])),
    preview: {
      'operation': 'update_metadata',
      'mapId': mapId,
      'name': updated.name,
      'role': role.name,
      'isIndoor': isIndoor,
      'storageGuarantee': 'recoverable'
    },
    referenceImpact: const {'identityUnchanged': true, 'pathUnchanged': true},
  );
}
