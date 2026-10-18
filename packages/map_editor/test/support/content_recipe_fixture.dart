import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

Future<List<String>> replayContentRecipeFixture(
  Directory project,
  Map<String, dynamic> recipe, {
  Map<String, Directory> inputs = const {},
}) async {
  final before = _projectBytes(project);
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [project.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final api = AuthoringReadApi(
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
    authorizationLimits: const AuthoringSecurityLimits(
      maxOperationsPerWindow: null,
    ),
    artifactStore: LocalArtifactStore(
      allowedSourceRoots: inputs.values
          .map((directory) => directory.path)
          .toList(),
      maximumArtifactBytes: 16 * 1024 * 1024,
    ),
  );
  final opened = await api.openProject(project.path);
  await mutations.attachProject(
    projectRootPath: project.path,
    workspaceHandle: opened.workspaceHandle,
    projectHandle: opened.projectHandle,
  );
  final descriptors = {
    for (final value in AuthoringMutationDispatcher.canonical().descriptors)
      value.id: value,
  };
  final bindings = <String, Object?>{};
  for (final entry in (recipe['artifacts'] as Map? ?? {}).entries) {
    final value = entry.value as Map;
    final root = inputs[value['input']]!;
    final source = File(p.join(root.path, value['path'] as String));
    if (crypto.sha256.convert(await source.readAsBytes()).toString() !=
        value['sha256']) {
      await api.closeWorkspace(opened.workspaceHandle);
      throw const FormatException('Fixture artifact changed');
    }
    bindings[entry.key as String] = (await mutations.stageArtifactFile(
      sourcePath: source.path,
      declaredMediaType: value['mediaType'] as String,
    )).reference.handle;
  }
  Object? resolve(Object? value) {
    if (value is List) return value.map(resolve).toList();
    if (value is Map) {
      if (value.keys.length == 1 && value.containsKey(r'$binding')) {
        return bindings[value[r'$binding']];
      }
      return {
        for (final entry in value.entries) entry.key: resolve(entry.value),
      };
    }
    return value;
  }

  var index = 0;
  var snapshot = await snapshots.load(opened.projectHandle);
  try {
    for (final value in recipe['actions'] as List) {
      final step = Map<String, dynamic>.from(value as Map);
      Map<String, dynamic>? action = step;
      if (step['resource'] case final Map resource) {
        final kind = resource['kind'] as String;
        final id = resource['id'] as String;
        final manifest = snapshot.manifest.toJson();
        Object? found;
        if (kind == 'map') {
          for (final map in snapshot.maps) {
            if (map.id == id) found = map.toJson();
          }
        } else {
          final field = switch (kind) {
            'worldRule' => 'worldRules',
            'fact' => 'facts',
            'dialogue' => 'dialogues',
            'eventV2' => 'eventRegistry',
            'project' => 'project',
            'tileset' => 'tilesets',
            'asset' => 'assets',
            _ => throw StateError('Unsupported fixture resource $kind'),
          };
          if (field == 'project') {
            found = manifest;
          } else {
            final entries = field == 'eventRegistry'
                ? (manifest[field] as Map)['records']
                : manifest[field];
            for (final entry in entries as List? ?? []) {
              final map = entry as Map;
              final entryId = field == 'eventRegistry'
                  ? ((map['draft'] ?? map['definition']) as Map)['id']
                  : map['id'];
              if (entryId == id) found = entry;
            }
          }
        }
        var exists = found != null;
        if (exists && resource['collection'] != null) {
          Object? collection = found;
          for (final part in (resource['collection'] as String).split('.')) {
            collection = (collection as Map)[part];
          }
          found = (collection as List? ?? [])
              .where((entry) => (entry as Map)['id'] == resource['memberId'])
              .firstOrNull;
          exists = found != null;
        }
        if (exists &&
            step['matches'] != null &&
            _matches(found, step['matches'])) {
          continue;
        }
        final selected = step[exists ? 'present' : 'absent'];
        action = selected == null
            ? null
            : Map<String, dynamic>.from(selected as Map);
      }
      if (action == null) continue;
      final id = 'recipe-${DateTime.now().microsecondsSinceEpoch}-${index++}';
      final actionId = action['actionId'] as String;
      final descriptor = descriptors[actionId]!;
      late Map<String, Object?> plan;
      try {
        plan = await mutations.plan(
          opened.projectHandle,
          AuthoringRequest(
            requestId: id,
            actionId: actionId,
            actionVersion: descriptor.version,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
            parameters: Map<String, Object?>.from(
              resolve(action['parameters']) as Map,
            ),
          ),
        );
      } on MapAuthoringException catch (error) {
        if (error.code.endsWith('.no_change')) continue;
        rethrow;
      }
      if (plan['applicable'] == false &&
          plan['nonApplicableReason'] == 'no_changes') {
        continue;
      }
      String? token;
      if (descriptor.riskLevel == AuthoringRiskLevel.high ||
          descriptor.riskLevel == AuthoringRiskLevel.critical) {
        token =
            (await mutations.confirm(
                  opened.projectHandle,
                  planId: plan['planId'] as String,
                ))['confirmationToken']
                as String;
      }
      await mutations.apply(
        opened.projectHandle,
        planId: plan['planId'] as String,
        operationId: id,
        confirmationToken: token,
      );
      snapshot = await snapshots.load(opened.projectHandle);
    }
  } finally {
    await api.closeWorkspace(opened.workspaceHandle);
  }
  final after = _projectBytes(project);
  return {
    ...before.keys,
    ...after.keys,
  }.where((path) => before[path] != after[path]).toList()..sort();
}

Map<String, String> _projectBytes(Directory root) => {
  for (final file in root.listSync(recursive: true).whereType<File>())
    if (!p.relative(file.path, from: root.path).startsWith('.pokemap'))
      p.relative(file.path, from: root.path): base64Encode(
        file.readAsBytesSync(),
      ),
};

bool _matches(Object? actual, Object? expected) {
  if (expected is List) {
    return actual is List &&
        actual.length == expected.length &&
        List.generate(
          expected.length,
          (index) => _matches(actual[index], expected[index]),
        ).every((value) => value);
  }
  if (expected is Map) {
    return actual is Map &&
        expected.entries.every(
          (entry) => _matches(actual[entry.key], entry.value),
        );
  }
  return actual == expected;
}
