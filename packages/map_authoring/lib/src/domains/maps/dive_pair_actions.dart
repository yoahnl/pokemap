import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';

final class DivePairActions {
  const DivePairActions();
  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final id in [
      'gameplay_zone.dive.link_pair_apply',
      'gameplay_zone.dive.unlink_pair_apply'
    ])
      AuthoringActionDescriptor(
          id: id,
          version: 1,
          summary: id.contains('.unlink')
              ? 'Unlink a recoverable Dive pair'
              : 'Link two prepared Dive endpoints',
          inputSchemaId: 'schema.$id.input.v1',
          outputSchemaId: 'schema.map.inter_map_mutation.output.v1',
          riskLevel: AuthoringRiskLevel.medium,
          resourceKinds: const [
            'map'
          ],
          requiredPermissions: const [
            AuthoringPermission.projectWrite
          ],
          guarantees: const [
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable
          ],
          extensions: {
            'multiFileGuarantee': 'recoverable',
            'mapMode': '2d',
            'parameters': id.contains('.unlink')
                ? ['mapId', 'zoneId']
                : ['mapId', 'zoneId', 'targetMapId', 'targetZoneId'],
            'endpointShape': '1x1',
            'spawnIdentity': 'MapEntity.id',
            'oppositeRoles': true,
            'consumesPp': false
          }),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final unlink =
        planning.request.actionId == 'gameplay_zone.dive.unlink_pair_apply';
    if (!unlink &&
        planning.request.actionId != 'gameplay_zone.dive.link_pair_apply') {
      throw semanticFailure(
          'dive.unsupported_action', 'Unsupported Dive action.');
    }
    final context = SemanticMapActionContext.read(planning,
        allowedParameters:
            unlink ? {'zoneId'} : {'zoneId', 'targetMapId', 'targetZoneId'});
    final source = context.map;
    final sourceZone = _endpoint(source, context.parameters.string('zoneId'));
    final a = sourceZone.fieldAction!.dive!;
    final targetMapId =
        unlink ? a.link?.mapId : context.parameters.string('targetMapId');
    final targetZoneId =
        unlink ? a.link?.zoneId : context.parameters.string('targetZoneId');
    final target =
        targetMapId == null ? null : planning.snapshot.mapById(targetMapId);
    if (target == null || targetZoneId == null || target.id == source.id) {
      throw semanticFailure(
          'dive.invalid_pair', 'Dive requires two distinct existing maps.');
    }
    final targetZone = _endpoint(target, targetZoneId);
    final b = targetZone.fieldAction!.dive!;
    if (a.role == b.role || (!unlink && (a.link != null || b.link != null))) {
      throw semanticFailure('dive.endpoints_unavailable',
          'Choose two unlinked endpoints with opposite roles.');
    }
    if (unlink) {
      try {
        validateDiveZonePair(
            sourceMap: source,
            sourceZoneId: sourceZone.id,
            targetMap: target,
            targetZoneId: targetZone.id);
      } on Object {
        throw semanticFailure('dive.invalid_pair',
            'Only an exact reciprocal Dive pair can be unlinked.');
      }
    }
    MapData replace(MapData map, MapGameplayZone zone, DiveZoneLink? link) =>
        updateGameplayZoneOnMap(map,
            zoneId: zone.id,
            fieldAction: zone.fieldAction!
                .copyWith(dive: zone.fieldAction!.dive!.copyWith(link: link)));
    final afterSource = replace(source, sourceZone,
        unlink ? null : DiveZoneLink(mapId: target.id, zoneId: targetZone.id));
    final afterTarget = replace(target, targetZone,
        unlink ? null : DiveZoneLink(mapId: source.id, zoneId: sourceZone.id));
    if (!unlink) {
      try {
        validateDiveZonePair(
            sourceMap: afterSource,
            sourceZoneId: sourceZone.id,
            targetMap: afterTarget,
            targetZoneId: targetZone.id);
      } on Object catch (error) {
        throw semanticFailure('dive.invalid_pair', '$error');
      }
    }
    if (!unlink &&
        !divePairHasSafeArrivals(
            sourceMap: afterSource,
            sourceZoneId: sourceZone.id,
            targetMap: afterTarget,
            targetZoneId: targetZone.id,
            project: context.manifest)) {
      throw semanticFailure('dive.arrival_unsafe',
          'Both Dive arrivals require the correct terrain and a safe player footprint.');
    }
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    for (final pair in [(source, afterSource), (target, afterTarget)]) {
      MapValidator.validate(pair.$2, projectDialogueContext: context.manifest);
      final mapId = pair.$1.id;
      final entry =
          context.manifest.maps.where((entry) => entry.id == mapId).single;
      final change = AuthoringResourceChange(
          resource: AuthoringResourceRef(
              kind: 'map',
              id: mapId,
              revision: planning.snapshot.resourceFingerprints['map:$mapId']),
          storageKey: entry.relativePath,
          beforeBytes: planning.snapshot.resourceBytes('map:$mapId'),
          afterBytes: encodeMapAuthoringDocument(pair.$2));
      changes.add(change);
      diffs.add(AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: change.resource,
          path: '/gameplayZones',
          before: jsonDecode(jsonEncode(
              pair.$1.gameplayZones.map((zone) => zone.toJson()).toList())),
          after: jsonDecode(jsonEncode(
              pair.$2.gameplayZones.map((zone) => zone.toJson()).toList()))));
    }
    return AuthoringMutationDraft(
        changeSet:
            AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diffs)),
        preview: {
          'operation': planning.request.actionId,
          'sourceMapId': source.id,
          'targetMapId': target.id,
          'sourceZoneId': sourceZone.id,
          'targetZoneId': targetZone.id,
          'changedMapCount': 2,
          'multiMapGuarantee': 'recoverable',
          'inverseAction': unlink
              ? 'gameplay_zone.dive.link_pair_apply'
              : 'gameplay_zone.dive.unlink_pair_apply',
          'seed': planning.seed
        });
  }
}

MapGameplayZone _endpoint(MapData map, String id) {
  final zones = map.gameplayZones.where((zone) => zone.id == id).toList();
  if (zones.length != 1 || !isDiveZone(zones.single)) {
    throw semanticFailure(
        'dive.endpoint_missing', 'Dive endpoint is missing or ambiguous.');
  }
  try {
    validateFieldActionZone(map, zones.single);
  } on Object {
    throw semanticFailure(
        'dive.endpoint_invalid', 'The Dive endpoint is invalid.');
  }
  return zones.single;
}
