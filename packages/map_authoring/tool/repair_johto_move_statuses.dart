import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:path/path.dart' as p;

const _catalogPath = 'data/pokemon/catalogs/moves.json';

const _corrections = {
  'poison_powder': ('poisoned', 'apply_status', 'statusId', 'poison', 100),
  'stun_spore': ('paralyzed', 'apply_status', 'statusId', 'paralysis', 100),
  'sleep_powder': ('asleep', 'apply_status', 'statusId', 'sleep', 100),
  'bite': ('flinch', 'apply_volatile_status', 'volatileStatusId', 'flinch', 30),
  'confuse_ray': (
    'confused',
    'apply_volatile_status',
    'volatileStatusId',
    'confusion',
    100
  ),
  'smog': ('poisoned', 'apply_status', 'statusId', 'poison', 40),
  'sludge': ('poisoned', 'apply_status', 'statusId', 'poison', 30),
  'hyper_fang': (
    'flinch',
    'apply_volatile_status',
    'volatileStatusId',
    'flinch',
    10
  ),
};

({Map<String, dynamic> document, List<String> changedMoveIds})
    correctJohtoMoveStatusCatalog(Map<String, dynamic> catalog) {
  if (catalog['catalog'] != 'moves' || catalog['entries'] is! List) {
    throw const FormatException('Expected the Johto moves catalog.');
  }
  final document = jsonDecode(jsonEncode(catalog)) as Map<String, dynamic>;
  final entries = (document['entries'] as List).cast<Map<String, dynamic>>();
  final changed = <String>[];
  for (final correction in _corrections.entries) {
    final matches = entries.where((entry) => entry['id'] == correction.key);
    if (matches.length != 1) {
      throw FormatException('Expected exactly one ${correction.key}.');
    }
    final effects = matches.single['effects'];
    if (effects is! List || effects.length != 1 || effects.single is! Map) {
      throw FormatException('Unexpected effects for ${correction.key}.');
    }
    final effect = effects.single as Map<String, dynamic>;
    final (oldStatus, kind, field, status, chance) = correction.value;
    if (effect['chance'] != chance || effect['targetScope'] != 'target') {
      throw FormatException(
          'Unexpected chance or target for ${correction.key}.');
    }
    final repaired = effect['kind'] == kind &&
        effect[field] == status &&
        (field == 'statusId'
            ? !effect.containsKey('volatileStatusId')
            : !effect.containsKey('statusId'));
    if (repaired) continue;
    if (effect['kind'] != 'apply_status' ||
        effect['statusId'] != oldStatus ||
        effect.containsKey('volatileStatusId')) {
      throw FormatException(
          'Unexpected status definition for ${correction.key}.');
    }
    effect
      ..remove('statusId')
      ..['kind'] = kind
      ..[field] = status;
    changed.add(correction.key);
  }
  return (document: document, changedMoveIds: List.unmodifiable(changed));
}

Future<Map<String, Object?>> repairJohtoMoveStatuses(
  String projectPath, {
  bool apply = false,
}) async {
  if (!p.isAbsolute(projectPath)) {
    throw const FormatException('The project path must be absolute.');
  }
  final root = await Directory(projectPath).resolveSymbolicLinks();
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(
    handles: handles,
    fingerprintCache: ProjectSnapshotFingerprintCache(),
  );
  final readApi = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ),
    snapshotLoader: snapshots,
  );
  final mutations = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: snapshots,
  );
  final opened = await readApi.openProject(root);
  String? committedReceipt;
  try {
    try {
      final snapshot = await snapshots.load(opened.projectHandle);
      final identity = snapshot.resourceStorageKeys.entries
          .where((entry) => entry.value == _catalogPath)
          .single
          .key;
      final before = snapshot.resourceBytes(identity);
      final beforeSha = sha256.convert(before).toString();
      final repair = correctJohtoMoveStatusCatalog(
        jsonDecode(utf8.decode(before)) as Map<String, dynamic>,
      );
      if (repair.changedMoveIds.isEmpty) {
        return {'status': 'unchanged', 'beforeSha256': beforeSha};
      }
      final protected = _resourceDigests(snapshot, except: identity);
      await mutations.attachProject(
        projectRootPath: root,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final operationId = 'johto-move-statuses-l01-$beforeSha';
      final planned = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operationId,
          actionId: 'pokemon.catalog.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operationId,
          parameters: {
            'relativePath': _catalogPath,
            'beforeBytesBase64': base64Encode(before),
            'document': repair.document,
          },
        ),
      );
      final changes = planned.plan.changeSet.changes;
      if (changes.length != 1 || changes.single.storageKey != _catalogPath) {
        throw StateError('The plan must replace only the moves catalog.');
      }
      final change = changes.single;
      final plannedBefore = await change.beforePayload!.readBytes();
      final plannedAfter = await change.afterPayload!.readBytes();
      if (sha256.convert(plannedBefore).toString() != beforeSha ||
          canonicalAuthoringJson(jsonDecode(utf8.decode(plannedAfter))) !=
              canonicalAuthoringJson(repair.document)) {
        throw StateError(
            'The canonical plan differs from the scoped correction.');
      }
      final result = <String, Object?>{
        'status': 'planned',
        'actionId': 'pokemon.catalog.write',
        'operationId': operationId,
        'planId': planned.planId,
        'beforeSha256': beforeSha,
        'afterSha256': sha256.convert(plannedAfter).toString(),
        'changedMoveIds': repair.changedMoveIds,
        'protectedResourceCount': protected.length,
        'beforeRevision': snapshot.revision,
      };
      if (!apply) return result;
      final confirmation = await mutations.confirmMutation(
        opened.projectHandle,
        planId: planned.planId,
      );
      final applied = await mutations.applyMutation(
        opened.projectHandle,
        planId: planned.planId,
        operationId: operationId,
        confirmationToken: confirmation.confirmationToken,
      );
      committedReceipt = 'Operation $operationId returned receipt '
          '${applied.receipt.receiptId} (${applied.receipt.status.wireName})';
      final after = await snapshots.load(opened.projectHandle);
      if (sha256.convert(after.resourceBytes(identity)).toString() !=
              result['afterSha256'] ||
          canonicalAuthoringJson(_resourceDigests(after, except: identity)) !=
              canonicalAuthoringJson(protected)) {
        throw StateError('Post-apply resource verification failed.');
      }
      return {
        ...result,
        'status': applied.receipt.status.wireName,
        'receiptId': applied.receipt.receiptId,
        'afterRevision': after.revision,
        'protectedResourcesUnchanged': true,
      };
    } finally {
      await mutations.detachWorkspace(opened.workspaceHandle);
      await readApi.closeWorkspace(opened.workspaceHandle);
    }
  } on Object catch (error) {
    if (committedReceipt != null) {
      throw StateError('$committedReceipt; post-apply verification or cleanup '
          'failed: $error. Reconcile the receipt before any retry.');
    }
    rethrow;
  }
}

Map<String, String> _resourceDigests(ProjectSnapshot snapshot,
        {required String except}) =>
    {
      for (final entry in snapshot.resourceFingerprints.entries)
        if (entry.key != except) entry.key: entry.value,
    };

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.length == 1 && arguments.single == '--help') {
      stdout.writeln('dart run tool/repair_johto_move_statuses.dart '
          '<absolute-project-path> [--apply]');
      return;
    }
    if (arguments.isEmpty ||
        arguments.length > 2 ||
        (arguments.length == 2 && arguments[1] != '--apply')) {
      throw const FormatException(
          'Expected an absolute project path and optional --apply.');
    }
    stdout.writeln(jsonEncode(await repairJohtoMoveStatuses(
      arguments.first,
      apply: arguments.length == 2,
    )));
  } on Object catch (error) {
    stderr.writeln('Johto status correction failed: $error');
    exitCode = 1;
  }
}
