import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'item_system_authoring_probe.dart';
import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_fixture_digest.dart';
import 'studio_transport_session.dart';

final class ItemSystemTransportEvidenceCollector {
  const ItemSystemTransportEvidenceCollector();

  Future<ItemSystemExecutionReceipt> collect({
    required Directory projectRootDirectory,
    required Directory mcpPackageRootDirectory,
    required String sourceRevision,
    required DateTime recordedAtUtc,
    bool includeStudio = true,
  }) async {
    final required = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
      ItemSystemProofLevel.mcpParityL5,
    );
    final fixtureSha256 = await computeItemSystemFixtureSha256(
      projectRootDirectory,
    );
    final payload = <String, Object?>{
      if (!includeStudio)
        'missingTransports': [ItemSystemTransport.editor.wireName],
    };

    try {
      final transports = {
        ItemSystemTransport.directApi: () => _runDirect(projectRootDirectory),
        ItemSystemTransport.jsonl: () => _runJsonl(projectRootDirectory),
        if (includeStudio)
          ItemSystemTransport.editor: () => _runStudio(projectRootDirectory),
        ItemSystemTransport.mcp: () =>
            _runMcp(projectRootDirectory, mcpPackageRootDirectory),
      };
      final pairs = <Map<String, Object?>>[];
      final errors = <String, String>{};
      for (final entry in transports.entries) {
        try {
          pairs.addAll(await entry.value());
        } on Object catch (error) {
          errors[entry.key.wireName] = error.toString();
        }
      }
      pairs.sort((left, right) {
        final leftId = '${left['actionId']}@${left['transport']}';
        final rightId = '${right['actionId']}@${right['transport']}';
        return leftId.compareTo(rightId);
      });
      payload['transportPairs'] = pairs;
      if (errors.isNotEmpty) {
        payload['transportErrors'] = errors;
        throw StateError('One or more Item transport executions failed.');
      }
      final pairIds = <String>{
        for (final pair in pairs) '${pair['actionId']}@${pair['transport']}',
      };
      if (pairs.length != required.length * transports.length ||
          pairIds.length != pairs.length) {
        throw StateError('The Item transport execution matrix is incomplete.');
      }
      for (final actionId in required) {
        final complete = transports.keys.every(
          (transport) => pairIds.contains('$actionId@${transport.wireName}'),
        );
        final semanticStates = pairs
            .where((pair) => pair['actionId'] == actionId)
            .map((pair) => pair['semanticStateSha256'])
            .toSet();
        if (!complete || semanticStates.length != 1) {
          throw StateError('Item transports disagree after $actionId.');
        }
      }
      payload
        ..['transportExecutorSha256'] = await _transportExecutorSha256(
          mcpPackageRootDirectory,
          includeStudio: includeStudio,
        )
        ..['availableTransportsAgree'] = true;
    } on Object catch (error) {
      payload['error'] = error.toString();
    }

    final complete =
        includeStudio && payload['availableTransportsAgree'] == true;
    return ItemSystemExecutionReceipt.record(
      level: ItemSystemProofLevel.mcpParityL5,
      sourceRevision: sourceRevision,
      fixtureSha256: fixtureSha256,
      payload: payload,
      attemptedCapabilities: required,
      succeededCapabilities: complete ? required : const [],
      failedCapabilities: complete ? const [] : required,
      producer: 'item-system-transport-evidence-collector',
      runnerVersion: '1.0.0',
      recordedAtUtc: recordedAtUtc,
    );
  }

  Map<String, Object?> buildParityReceiptBundle(
    ItemSystemExecutionReceipt receipt,
  ) {
    if (receipt.level != ItemSystemProofLevel.mcpParityL5 ||
        receipt.verdict != ItemSystemExecutionVerdict.passed) {
      throw ArgumentError.value(
        receipt.level,
        'receipt',
        'must be one passed L5 execution receipt',
      );
    }
    final rawPairs = receipt.payload['transportPairs'];
    final rawExecutorDigests = receipt.payload['transportExecutorSha256'];
    if (rawPairs is! List || rawExecutorDigests is! Map) {
      throw const FormatException(
        'L5 receipt is missing transport execution evidence.',
      );
    }
    final evidenceRevision = 'sha256:${receipt.payloadSha256}';
    final fixtureDigest = 'sha256:${receipt.fixtureSha256}';
    final receipts = <AuthoringTransportExecutionReceipt>[];
    for (final rawPair in rawPairs) {
      if (rawPair is! Map) {
        throw const FormatException('Transport pair must be a JSON object.');
      }
      final pair = Map<String, Object?>.from(rawPair);
      final actionId = pair['actionId'];
      final transportName = pair['transport'];
      final observedReceiptSha256 = pair['receiptSha256'];
      final semanticStateSha256 = pair['semanticStateSha256'];
      if (actionId is! String ||
          transportName is! String ||
          observedReceiptSha256 is! String ||
          semanticStateSha256 is! String) {
        throw const FormatException('Transport pair fields are invalid.');
      }
      final transport = _authoringTransport(transportName);
      final executorSha256 = rawExecutorDigests[transportName];
      if (executorSha256 is! String) {
        throw FormatException(
          'Missing executor digest for transport $transportName.',
        );
      }
      receipts.add(
        AuthoringTransportExecutionReceipt(
          receiptId: '$actionId@${transport.name}',
          actionId: actionId,
          transport: transport,
          sourceRevision: receipt.sourceRevision,
          evidenceRevision: evidenceRevision,
          fixtureDigest: fixtureDigest,
          executorDigest: 'sha256:$executorSha256',
          observedReceiptSha256: 'sha256:$observedReceiptSha256',
          semanticStateDigest: 'sha256:$semanticStateSha256',
          evidencePath: _transportEvidencePath(transport),
        ),
      );
    }
    if (receipts.length !=
        ItemSystemV1CertificationProfile.requiredItemActionIds.length *
            AuthoringTransport.values.length) {
      throw const FormatException('Transport receipt matrix is incomplete.');
    }
    return <String, Object?>{
      'sourceRevision': receipt.sourceRevision,
      'evidenceRevision': evidenceRevision,
      'fixtureDigest': fixtureDigest,
      'receipts': receipts.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

AuthoringTransport _authoringTransport(String transportName) {
  return switch (transportName) {
    'direct_api' => AuthoringTransport.directApi,
    'jsonl' => AuthoringTransport.cli,
    'editor' => AuthoringTransport.editor,
    'mcp' => AuthoringTransport.mcp,
    _ => throw FormatException('Unknown transport: $transportName.'),
  };
}

String _transportEvidencePath(AuthoringTransport transport) {
  return switch (transport) {
    AuthoringTransport.directApi =>
      'tools/pokemap_product_certification/lib/src/'
          'item_system_transport_evidence_collector.dart#direct-api',
    AuthoringTransport.cli =>
      'tools/pokemap_product_certification/lib/src/'
          'item_system_transport_evidence_collector.dart#jsonl',
    AuthoringTransport.editor =>
      'tools/pokemap_product_certification/lib/src/'
          'item_system_transport_evidence_collector.dart#editor',
    AuthoringTransport.mcp => 'tools/pokemap_mcp/src/item_evidence_runner.ts',
  };
}

Future<List<Map<String, Object?>>> _runDirect(Directory source) async {
  final fixture = await _TransportFixture.copy(source, 'direct');
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: <String>[fixture.project.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final reads = AuthoringReadApi(
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
  final pairs = <Map<String, Object?>>[];
  final observedReceiptIds = <String>{};
  WorkspaceHandle? workspaceHandle;
  try {
    final opened = await reads.openProject(fixture.project.path);
    workspaceHandle = opened.workspaceHandle;
    await mutations.attachProject(
      projectRootPath: fixture.project.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    for (final action in itemSystemAuthoringProbeActions) {
      final operationId = 'cert-direct-${action.slug}';
      final plan = await action.plan(
        operationId: operationId,
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        snapshots: snapshots,
        mutations: mutations,
      );
      String? confirmationToken;
      if (action.actionId == 'item.delete_apply') {
        final confirmation = await mutations.confirm(
          opened.projectHandle,
          planId: plan['planId']! as String,
        );
        confirmationToken = confirmation['confirmationToken']! as String;
      }
      final applied = await mutations.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: operationId,
        confirmationToken: confirmationToken,
      );
      final receipt = Map<String, Object?>.from(applied['receipt']! as Map);
      _requireObservedReceipt(receipt, action.actionId, observedReceiptIds);
      pairs.add(
        await fixture.pair(
          action.actionId,
          ItemSystemTransport.directApi,
          receipt,
        ),
      );
    }
  } finally {
    if (workspaceHandle != null) {
      await mutations.detachWorkspace(workspaceHandle);
      await reads.closeWorkspace(workspaceHandle);
    }
    await fixture.dispose();
  }
  return pairs;
}

Future<List<Map<String, Object?>>> _runJsonl(Directory source) async {
  final fixture = await _TransportFixture.copy(source, 'jsonl');
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: <String>[fixture.project.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final reads = AuthoringReadApi(
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
  final worker = JsonlWorker(api: reads, mutations: mutations);
  final pairs = <Map<String, Object?>>[];
  final observedReceiptIds = <String>{};
  try {
    final opened = await _workerRequest(worker, 'open', <String, Object?>{
      'projectRoot': fixture.project.path,
    });
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    for (final action in itemSystemAuthoringProbeActions) {
      final observed = action.usesWorkshop
          ? await _workerRequest(worker, 'workshop_snapshot', <String, Object?>{
              'projectHandle': projectHandle,
              'actionId': action.actionId,
              'parameters': action.parameters,
              'includeDocuments': false,
            })
          : await _workerRequest(worker, 'query', <String, Object?>{
              'projectHandle': projectHandle,
              'request': AuthoringQueryRequest(
                resourceKind: 'itemDefinition',
                operation: AuthoringQueryOperation.list,
                view: AuthoringQueryView.detail,
              ).toJson(),
            });
      final plan = await _workerRequest(worker, 'plan', <String, Object?>{
        'projectHandle': projectHandle,
        'request': action
            .request(
              operationId: 'cert-jsonl-${action.slug}',
              workspaceHandle: workspaceHandle,
              revision: observed.data['snapshotRevision']! as String,
            )
            .toJson(),
      });
      String? confirmationToken;
      if (action.actionId == 'item.delete_apply') {
        final confirmation = await _workerRequest(
          worker,
          'confirm',
          <String, Object?>{
            'projectHandle': projectHandle,
            'planId': plan.data['planId'],
          },
        );
        confirmationToken = confirmation.data['confirmationToken']! as String;
      }
      final applied = await _workerRequest(worker, 'apply', <String, Object?>{
        'projectHandle': projectHandle,
        'planId': plan.data['planId'],
        'operationId': 'cert-jsonl-${action.slug}',
        if (confirmationToken != null) 'confirmationToken': confirmationToken,
      });
      final receipt = Map<String, Object?>.from(
        applied.data['receipt']! as Map,
      );
      _requireObservedReceipt(receipt, action.actionId, observedReceiptIds);
      pairs.add(
        await fixture.pair(action.actionId, ItemSystemTransport.jsonl, receipt),
      );
    }
  } finally {
    await fixture.dispose();
  }
  return pairs;
}

Future<List<Map<String, Object?>>> _runStudio(Directory source) async {
  final fixture = await _TransportFixture.copy(source, 'editor');
  try {
    final studio = await StudioTransportSession.open(fixture.project);
    try {
      final pairs = <Map<String, Object?>>[];
      final observedReceiptIds = <String>{};
      for (final action in itemSystemAuthoringProbeActions) {
        final applied = await studio.run(
          actionId: action.actionId,
          actionVersion: 1,
          parameters: action.parameters,
          operationId: 'cert-editor-${action.slug}',
          preferWorkshop: action.usesWorkshop,
          confirm: action.actionId == 'item.delete_apply',
        );
        final receipt = applied.toJson();
        _requireObservedReceipt(receipt, action.actionId, observedReceiptIds);
        pairs.add(
          await fixture.pair(
            action.actionId,
            ItemSystemTransport.editor,
            receipt,
          ),
        );
      }
      return pairs;
    } finally {
      await studio.close();
    }
  } finally {
    await fixture.dispose();
  }
}

Future<List<Map<String, Object?>>> _runMcp(
  Directory source,
  Directory mcpRoot,
) async {
  final runner = p.join(mcpRoot.path, 'dist/src/item_evidence_runner.js');
  final server = p.join(mcpRoot.path, 'dist/src/index.js');
  if (!await File(runner).exists() || !await File(server).exists()) {
    throw StateError('The packaged MCP evidence runner has not been built.');
  }
  final result = await Process.run('node', <String>[
    runner,
    '--project-root',
    source.path,
    '--server',
    server,
  ], workingDirectory: mcpRoot.path);
  if (result.exitCode != 0) {
    throw StateError('MCP evidence runner failed: ${result.stderr}');
  }
  final json = jsonDecode(result.stdout.toString());
  if (json is! Map<String, dynamic> ||
      json['schemaVersion'] != 1 ||
      json['transport'] != 'mcp' ||
      json['pairs'] is! List) {
    throw StateError('MCP evidence runner returned an invalid envelope.');
  }
  return (json['pairs'] as List<dynamic>)
      .map((pair) => Map<String, Object?>.from(pair as Map<dynamic, dynamic>))
      .toList(growable: false);
}

Future<AuthoringResult> _workerRequest(
  JsonlWorker worker,
  String command,
  Map<String, Object?> args,
) async {
  final response = await worker.processLine(
    jsonEncode(<String, Object?>{
      'id': 'cert-$command',
      'command': command,
      'args': args,
    }),
  );
  final result = AuthoringResult.fromJson(
    jsonDecode(response) as Map<String, dynamic>,
  );
  if (result.status != AuthoringResultStatus.success) {
    throw StateError('$command failed: ${result.error?.message}');
  }
  return result;
}

void _requireObservedReceipt(
  Map<String, Object?> receipt,
  String actionId,
  Set<String> observedReceiptIds,
) {
  if (receipt['actionId'] != actionId || receipt['status'] != 'applied') {
    throw StateError('$actionId did not return an applied receipt.');
  }
  final receiptId = receipt['receiptId'];
  if (receiptId is! String || !observedReceiptIds.add(receiptId)) {
    throw StateError('$actionId returned a missing or duplicate receipt.');
  }
}

final class _TransportFixture {
  const _TransportFixture(this.root, this.project);

  final Directory root;
  final Directory project;

  static Future<_TransportFixture> copy(
    Directory source,
    String transport,
  ) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap-item-$transport-evidence-',
    );
    final project = Directory(p.join(root.path, 'project'));
    await _copyDirectory(source, project);
    return _TransportFixture(root, project);
  }

  Future<Map<String, Object?>> pair(
    String actionId,
    ItemSystemTransport transport,
    Map<String, Object?> receipt,
  ) async {
    final catalogJson = jsonDecode(
      await File(p.join(project.path, 'data/pokemon/catalogs/items.json'))
          .readAsString(),
    ) as Map<String, dynamic>;
    final catalog = decodeProjectItemCatalog(catalogJson);
    verifyItemSystemAuthoringProbeState(catalog, actionId);
    final normalizedReceipt = _normalizedObservedReceipt(receipt);
    return <String, Object?>{
      'actionId': actionId,
      'transport': transport.wireName,
      'receiptSha256': _canonicalSha256(normalizedReceipt),
      'semanticStateSha256': _canonicalSha256(
        encodeProjectItemCatalog(catalog),
      ),
      'afterRevision': receipt['afterRevision'],
    };
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Map<String, Object?> _normalizedObservedReceipt(Map<String, Object?> receipt) {
  final normalized = Map<String, Object?>.from(receipt)
    ..remove('receiptId')
    ..remove('createdAtUtc');
  final extensions = normalized['extensions'];
  if (extensions is Map) {
    normalized['extensions'] = Map<String, Object?>.from(extensions)
      ..remove('planId');
  }
  return normalized;
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final targetPath = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      await entity.copy(targetPath);
    } else {
      throw StateError('Unsupported fixture entity: ${entity.path}');
    }
  }
}

String _canonicalSha256(Object? value) {
  return sha256
      .convert(utf8.encode(jsonEncode(_canonicalJson(value))))
      .toString();
}

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalJson(value[key]),
    };
  }
  if (value is List) return value.map(_canonicalJson).toList(growable: false);
  return value;
}

Future<Map<String, String>> _transportExecutorSha256(
  Directory mcpRoot, {
  required bool includeStudio,
}) async {
  final repositoryRoot = Directory(p.normalize(p.join(mcpRoot.path, '../..')));
  const collector =
      'tools/pokemap_product_certification/lib/src/'
      'item_system_transport_evidence_collector.dart';
  const probe =
      'tools/pokemap_product_certification/lib/src/'
      'item_system_authoring_probe.dart';
  const actions =
      'packages/map_authoring/lib/src/domains/gameplay/'
      'item_catalog_actions.dart';
  const direct =
      'packages/map_authoring/lib/src/api/'
      'local_map_authoring_mutation_api.dart';
  return <String, String>{
    'direct_api': await _sourceFilesSha256(repositoryRoot, const <String>[
      collector,
      probe,
      actions,
      direct,
    ]),
    'jsonl': await _sourceFilesSha256(repositoryRoot, const <String>[
      collector,
      probe,
      actions,
      direct,
      'packages/map_authoring/lib/src/tooling/jsonl_worker.dart',
    ]),
    if (includeStudio)
      'editor': await _sourceFilesSha256(repositoryRoot, const <String>[
        collector,
        probe,
        actions,
        direct,
        'tools/pokemap_product_certification/lib/src/studio_transport_session.dart',
        'apps/avelune_studio/lib/features/presentations/data/local_presentation_connection.dart',
        'apps/avelune_studio/lib/features/project_session/domain/project_session.dart',
      ]),
    'mcp': await _mcpBuildSha256(mcpRoot),
  };
}

Future<String> _sourceFilesSha256(
  Directory root,
  List<String> relativePaths,
) async {
  return _filesSha256(root, <File>[
    for (final relativePath in relativePaths)
      File(p.join(root.path, relativePath)),
  ]);
}

Future<String> _mcpBuildSha256(Directory mcpRoot) async {
  final dist = Directory(p.join(mcpRoot.path, 'dist/src'));
  if (!await dist.exists()) {
    throw StateError('Missing ${dist.path}.');
  }
  final files = await dist
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File && entity.path.endsWith('.js'))
      .cast<File>()
      .toList();
  files.sort((left, right) => left.path.compareTo(right.path));
  return _filesSha256(mcpRoot, files);
}

Future<String> _filesSha256(Directory root, List<File> files) async {
  final bytes = BytesBuilder(copy: false);
  for (final file in files) {
    if (!await file.exists()) throw StateError('Missing ${file.path}.');
    bytes
      ..add(utf8.encode(p.relative(file.path, from: root.path)))
      ..addByte(0)
      ..add(await file.readAsBytes())
      ..addByte(0);
  }
  return sha256.convert(bytes.takeBytes()).toString();
}
