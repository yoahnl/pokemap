import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_interaction_reconciliation.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  stdout.writeln(jsonEncode(await reconcileSourceInteractions(args)));
}

Future<Map<String, Object?>> reconcileSourceInteractions(
    List<String> args) async {
  if (args.length != 6 ||
      args[5].trim().isEmpty ||
      args[5].length > 256 ||
      args[5].contains('\u0000')) {
    throw ArgumentError(
        'Expected absolute inventory, projection, expanded mutations, '
        'native project, unused output directory, and nonempty tool revision.');
  }
  for (final value in args.take(5)) {
    if (!path.isAbsolute(value) ||
        path.normalize(value) != value ||
        value.contains('\u0000')) {
      throw ArgumentError(
          'Every input and output path must be absolute and normalized.');
    }
  }
  final project = Directory(args[3]);
  _require(
      await FileSystemEntity.type(project.path, followLinks: false) ==
              FileSystemEntityType.directory &&
          await project.resolveSymbolicLinks() == project.path,
      'The native project must be a canonical directory without symlink aliases.');
  final output = args[4];
  _require(
      !path.equals(project.path, output) &&
          !path.isWithin(project.path, output),
      'Reconciliation output must stay outside the native project.');
  _require(
      await FileSystemEntity.type(output, followLinks: false) ==
          FileSystemEntityType.notFound,
      'Reconciliation output must be unused.');
  final parent = Directory(path.dirname(output));
  _require(
      await FileSystemEntity.type(parent.path, followLinks: false) ==
              FileSystemEntityType.directory &&
          await parent.resolveSymbolicLinks() == parent.path,
      'The output parent must exist and be canonical without symlink aliases.');

  final inputs = <_EvidenceInput>[];
  for (final value in args.take(3)) {
    inputs.add(await _EvidenceInput.read(value));
  }
  final inventory = inputs[0].json;
  final projection = inputs[1].json;
  final mutationEnvelope = inputs[2].json;
  _require(
      inventory['kind'] == 'sourceInteractionInventory' &&
          inventory['schemaVersion'] == 1,
      'Expected a current source interaction inventory.');
  _require(projection['kind'] == 'rc01CurrentConverterEventProjection',
      'Expected a current converter event projection.');
  _require(
      mutationEnvelope['kind'] ==
              'rc01CurrentConverterExpandedEventMutations' &&
          mutationEnvelope['schemaVersion'] == 1 &&
          mutationEnvelope['expanded'] == true &&
          mutationEnvelope['selection'] ==
              'sourceOwnerContainsExactProjectedEventIdentity',
      'Expected explicitly expanded source-event mutations.');
  final sourceHash = _hash(inventory['sourceSnapshotHash']);
  final normalizationHash = _hash(inventory['normalizationHash']);
  final sourceProfileHash = _hash(inventory['analysisProfileHash']);
  final namespace = _string(inventory['logicalProjectNamespace']);
  _require(
      inventory['toolRevision'] == args[5] &&
          projection['toolRevision'] == args[5] &&
          mutationEnvelope['toolRevision'] == args[5],
      'Inventory, projection and mutations must use the requested tool revision.');
  _require(
      projection['sourceSnapshotHash'] == sourceHash &&
          projection['normalizationHash'] == normalizationHash &&
          projection['sourceProfileHash'] == sourceProfileHash &&
          projection['logicalProjectNamespace'] == namespace &&
          mutationEnvelope['sourceSnapshotHash'] == sourceHash &&
          mutationEnvelope['normalizationHash'] == normalizationHash &&
          mutationEnvelope['sourceProfileHash'] == sourceProfileHash &&
          mutationEnvelope['logicalProjectNamespace'] == namespace,
      'Inventory, projection and mutation provenance must agree.');
  _require(
      _hash(projection['nativeDraftHash']) ==
          _hash(mutationEnvelope['nativeDraftHash']),
      'Projection and mutations must describe the same native draft.');
  _require(
      _hash(projection['preparationHash']) ==
          _hash(mutationEnvelope['preparationHash']),
      'Projection and mutations must describe the same preparation.');
  _require(
      _hash(mutationEnvelope['sourceProjectionRawSha256']) == inputs[1].sha256,
      'Linked mutations must reference the exact supplied projection bytes.');
  final profileHash = projection['interpretationProfileHash'] == null
      ? null
      : _hash(projection['interpretationProfileHash']);
  _require(mutationEnvelope['interpretationProfileHash'] == profileHash,
      'Projection and mutations must use the same interpretation profile.');
  final rawMutations = mutationEnvelope['mutations'];
  _require(rawMutations is List && rawMutations.length <= 32768,
      'Expected a bounded expanded mutation list.');
  final mutations = <NativeMutation>[];
  final operationIds = <String>{};
  for (var index = 0; index < (rawMutations as List).length; index++) {
    final row = _object(rawMutations[index]);
    _require(
        row['ordinal'] == index &&
            row['actionVersion'] is int &&
            (row['actionVersion'] as int) > 0,
        'Mutation ordinals and action versions must be exact positive integers.');
    final operation = _string(row['operationId']);
    _require(
        operationIds.add(operation), 'Duplicate mutation operation identity.');
    mutations.add(NativeMutation(
      operationId: ConverterId(operation),
      actionId: _string(row['actionId']),
      actionVersion: row['actionVersion'] as int,
      sourceEntityIds: _ids(row['sourceEntityIds']),
      targetEntityIds: _ids(row['targetEntityIds']),
      parameters: _object(row['parameters']),
    ));
  }

  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [project.path], fileReader: reader);
  final loader = ProjectSnapshotLoader(handles: handles);
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles),
    snapshotLoader: loader,
  );
  final opened = await api.openProject(project.path);
  Directory? staging;
  try {
    _require(!opened.recoveryRequired,
        'The native project requires recovery before audit.');
    final observed = await loader.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    _require(observed.loadDiagnostics.isEmpty,
        'Strict native observation has diagnostics.');
    final reconciliation = SourceInteractionReconciliation.build(
      inventory: inventory,
      projectionEvidence: projection,
      expectedMutations: mutations,
      observedProject: observed.manifest,
      observedMaps: observed.maps,
      toolRevision: args[5],
      projectionToolRevision: _string(projection['toolRevision']),
      logicalProjectNamespace: namespace,
      sourceSnapshotHash: sourceHash,
      normalizationHash: normalizationHash,
      sourceProfileHash: sourceProfileHash,
      interpretationProfileHash: profileHash,
    );
    final ledger = reconciliation.toJson();
    final summary = reconciliation.summaryJson();
    final second = await loader.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    _require(second.revision == observed.revision,
        'The native project changed during reconciliation.');
    for (final input in inputs) {
      await input.verifyUnchanged();
    }
    _require(
        await FileSystemEntity.type(output, followLinks: false) ==
            FileSystemEntityType.notFound,
        'The output appeared during reconciliation.');
    staging = await parent.createTemp('.rc01-reconciliation-');
    Future<void> writeJson(String name, Object? value) =>
        File('${staging!.path}/$name')
            .writeAsString(jsonEncode(value), flush: true);
    await writeJson('ledger.json', ledger);
    await writeJson('summary.json', summary);
    await writeJson('read-receipt.json', {
      'kind': 'sourceInteractionReconciliationReadReceipt',
      'schemaVersion': 1,
      'toolRevision': args[5],
      'nativeProjectRevision': observed.revision,
      'nativeProjectReobservedUnchanged': true,
      'observedNativeCounts': {
        'scope': 'canonicalSnapshotPresenceOnly',
        'sourceFidelityCertified': false,
        'maps': observed.maps.length,
        'entities': observed.maps
            .fold<int>(0, (count, map) => count + map.entities.length),
        'triggers': observed.maps
            .fold<int>(0, (count, map) => count + map.triggers.length),
        'warps': observed.maps
            .fold<int>(0, (count, map) => count + map.warps.length),
        'eventRecords': observed.manifest.eventRegistry?.records.length ?? 0,
        'dialogues': observed.manifest.dialogues.length,
        'scenes': observed.manifest.scenes.length,
        'facts': observed.manifest.facts.length,
        'worldRules': observed.manifest.worldRules.length,
        'trainers': observed.manifest.trainers.length,
        'encounterTables': observed.manifest.encounterTables.length,
        'shops': observed.manifest.shops.length,
        'badges': observed.manifest.badges.length,
        'characters': observed.manifest.characters.length,
        'cinematics': observed.manifest.cinematics.length,
        'presentationCinematics':
            observed.manifest.presentationCinematics.length,
        'cinematicMediaAssets': observed.manifest.cinematicMediaAssets.length,
      },
      'inputs': [
        for (final input in inputs)
          {
            'fileName': path.basename(input.path),
            'sha256': input.sha256,
            'byteLength': input.byteLength,
          }
      ],
      'sourceScriptsExecuted': 0,
      'aiSourceInferenceCalls': 0,
      'nativeMutationCalls': 0,
      'globalPlayabilityCertified': false,
    });
    final events = (ledger['events'] as List).map(_object).toList();
    await File('${staging.path}/events.csv').writeAsString(
        _csv(events, [
          'sourceIdentity',
          'sourceMapId',
          'sourceEventId',
          'mapName',
          'name',
          'locator',
          'converterDecision',
          'nativeComparison',
          'nativeComparisonScope',
          'pageNativeCoverageCertified',
          'gaps',
          'actualNative',
          'runtimeProof',
          'criticality',
        ]),
        flush: true);
    final pages = <Map<String, Object?>>[
      for (final event in events)
        for (final page in event['pages'] as List)
          {
            'sourceIdentity': event['sourceIdentity'],
            'sourceMapId': event['sourceMapId'],
            'sourceEventId': event['sourceEventId'],
            ..._object(page)
          },
    ];
    await File('${staging.path}/pages.csv').writeAsString(
        _csv(pages, [
          'sourceIdentity',
          'sourceMapId',
          'sourceEventId',
          'originalPageIndex',
          'converterDecision',
          'nativeComparison',
          'nativeComparisonScope',
          'coverage',
          'expectedObjectKeys',
          'sharedExpectedObjectKeys',
          'runtimeProof',
          'criticality',
        ]),
        flush: true);
    _require(
        await FileSystemEntity.type(output, followLinks: false) ==
            FileSystemEntityType.notFound,
        'The output appeared before publication.');
    await staging.rename(output);
    staging = null;
    return summary;
  } finally {
    if (staging != null && await staging.exists()) {
      await staging.delete(recursive: true);
    }
    await api.closeWorkspace(opened.workspaceHandle);
  }
}

String _csv(List<Map<String, Object?>> rows, List<String> columns) => '${[
      columns.map(SourceInteractionInventory.csvCell).join(','),
      for (final row in rows)
        columns.map((key) {
          final value = row[key];
          return SourceInteractionInventory.csvCell(value == null
              ? ''
              : value is String
                  ? value
                  : jsonEncode(value));
        }).join(','),
    ].join('\n')}\n';

List<ConverterId> _ids(Object? value) {
  _require(value is List, 'Expected mutation identity arrays.');
  return (value as List).map((value) => ConverterId(_string(value))).toList();
}

String _string(Object? value) {
  _require(value is String && value.trim().isNotEmpty,
      'Expected a nonempty string.');
  return value as String;
}

String _hash(Object? value) => Sha256Hash(_string(value)).value;

Map<String, Object?> _object(Object? value) {
  _require(value is Map<String, Object?>, 'Expected a JSON object.');
  return value as Map<String, Object?>;
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

final class _EvidenceInput {
  _EvidenceInput(this.path, this.json, this.sha256, this.byteLength);
  final String path;
  final Map<String, Object?> json;
  final String sha256;
  final int byteLength;
  static const maxBytes = 268435456;

  static Future<_EvidenceInput> read(String path) async {
    final file = File(path);
    _require(
        await FileSystemEntity.type(path, followLinks: false) ==
                FileSystemEntityType.file &&
            await file.resolveSymbolicLinks() == path,
        'Evidence inputs must be canonical regular files.');
    _require(await file.length() <= maxBytes,
        'Evidence input exceeds the byte quota.');
    final bytes = await file.readAsBytes();
    _require(bytes.length <= maxBytes,
        'Evidence input changed beyond the byte quota.');
    final json = _object(jsonDecode(utf8.decode(bytes)));
    canonicalHashOf(json,
        limits: const ContractLimits(
            maxDepth: 96,
            maxNodes: 16000000,
            maxTextCodeUnits: maxBytes,
            maxStringCodeUnits: 1048576));
    return _EvidenceInput(
        path, json, crypto.sha256.convert(bytes).toString(), bytes.length);
  }

  Future<void> verifyUnchanged() async {
    final file = File(path);
    _require(
        await FileSystemEntity.type(path, followLinks: false) ==
                FileSystemEntityType.file &&
            await file.resolveSymbolicLinks() == path &&
            await file.length() == byteLength,
        'Evidence input path or size changed during reconciliation.');
    final bytes = await file.readAsBytes();
    _require(
        crypto.sha256.convert(bytes).toString() == sha256 &&
            bytes.length == byteLength,
        'Evidence input changed during reconciliation.');
  }
}
