import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Expected a prepared FRLG specification path.');
  }
  final source = await File(arguments.single).readAsBytes();
  final units =
      _nativeUnits(jsonDecode(utf8.decode(source)) as Map<String, dynamic>);
  final native = CatalogStorageBuilder().build(units);
  final objects = {...native.objects};
  final before = await CatalogSnapshot.open(
      root: native.root, readObject: (ref) async => objects[ref.sha256]!);
  await before.validate();
  final target = units.firstWhere((unit) =>
      unit.key.kind == CatalogDefinitionKind.smartTilePattern &&
      unit.references
          .any((ref) => ref.kind == CatalogDefinitionKind.smartTileAnimation));
  final changed = CatalogDefinitionUnit(
      key: target.key,
      payload: {...target.payload, 'name': 'L3 native editing proof'},
      references: target.references);
  final patch = await before.patch(upserts: [changed]);
  objects.addAll(patch.objects);
  final after =
      await patch.nextSnapshot(readObject: (ref) async => objects[ref.sha256]!);
  for (final unit in units) {
    final expected = unit.key == target.key ? changed : unit;
    final actual = await after.lookup(unit.key);
    if (actual == null ||
        canonicalAuthoringJson(actual.toJson()) !=
            canonicalAuthoringJson(expected.toJson())) {
      throw StateError('Native definition changed unexpectedly: ${unit.key}.');
    }
  }
  final nativeDisk = await _filesystemJourney(
      await before.closure([target.key]), changed, 'native',
      measure: true);
  final scaling = <Map<String, Object?>>[];
  for (final factor in [1, 2, 4]) {
    final values = List.generate(
        512 * factor,
        (index) => CatalogDefinitionUnit(
                key: CatalogDefinitionKey(CatalogDefinitionKind.element,
                    'element_${index.toString().padLeft(6, '0')}'),
                payload: {
                  'name': 'Element $index',
                  'version': 1,
                  'data': 'x' * 4096
                }));
    final replacement = CatalogDefinitionUnit(
        key: values[128].key, payload: {...values[128].payload, 'version': 2});
    scaling.add({
      'factor': factor,
      ...await _filesystemJourney(values, replacement, 'scale_$factor',
          measure: true)
    });
  }
  if (scaling.map((row) => row['newObjects']).toSet().length != 1) {
    throw StateError(
        'The chosen equal-depth scaling fixture changed write counts.');
  }
  stdout.writeln(jsonEncode({
    'lot': 'L3',
    'sourceSha256': sha256.convert(source).toString(),
    'nativeDefinitions': units.length,
    'nativePatchObjects': patch.objects.length,
    'nativePatchBytes':
        patch.objects.values.fold<int>(0, (sum, bytes) => sum + bytes.length),
    'nativeUnchangedDefinitionsPreserved': units.length - 1,
    'nativeFilesystem': nativeDisk,
    'filesystemScaling': scaling,
    'temporaryProjectsRemoved': true,
    'studioIntegrated': false,
    'mobilePerformanceQualified': false,
    'scope':
        'Native unit identity and local compiled filesystem lifecycle; no device latency guarantee.',
    'verdict': 'PASS',
  }));
}

Future<Map<String, Object?>> _filesystemJourney(
    List<CatalogDefinitionUnit> units,
    CatalogDefinitionUnit changed,
    String projectId,
    {required bool measure}) async {
  final directory = await Directory.systemTemp.createTemp('avelune-l3-probe-');
  CatalogEditingSession? session;
  LeasedCatalogSnapshot? reader;
  try {
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    final build = CatalogStorageBuilder().build(units);
    await store.publish(build, expectedRootRevision: null);
    final admission = Stopwatch()..start();
    session = await CatalogEditingSession.open(
        store: store, projectId: projectId, actorId: 'local_probe');
    admission.stop();
    reader = await session.openSnapshot();
    final original = await reader.snapshot.lookup(changed.key);
    final before = await _inventory(directory);
    final edit = Stopwatch()..start();
    final plan =
        await session.planPatch(upserts: [changed], idempotencyKey: 'edit');
    final receipt = await session.apply(plan);
    edit.stop();
    final next = await _inventory(directory);
    final newObjects =
        next.entries.where((entry) => !before.containsKey(entry.key)).toList();
    for (final entry in before.entries) {
      if (next[entry.key] != entry.value) {
        throw StateError('An immutable object changed.');
      }
    }
    final history = await session.history
        .get(projectId: projectId, entryId: receipt.receiptId);
    if (history == null ||
        history.changes.length != 1 ||
        history.changes.single.storageKey !=
            CatalogStorageStore.headStorageKey) {
      throw StateError('The history rewrote more than the catalog head.');
    }
    await session.retention.collect(
        projectId: projectId, history: session.history, blobs: session.blobs);
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo');
    if (canonicalAuthoringJson(
            (await session.snapshot.lookup(changed.key))!.payload) !=
        canonicalAuthoringJson(original!.payload)) {
      throw StateError('Undo changed native content.');
    }
    await session.close();
    session = await CatalogEditingSession.open(
        store: store, projectId: projectId, actorId: 'local_probe');
    await session.redo(entryId: receipt.receiptId, idempotencyKey: 'redo');
    if (canonicalAuthoringJson(
            (await session.snapshot.lookup(changed.key))!.payload) !=
        canonicalAuthoringJson(changed.payload)) {
      throw StateError('Restart redo lost content.');
    }
    if (canonicalAuthoringJson(
            (await reader.snapshot.lookup(changed.key))!.payload) !=
        canonicalAuthoringJson(original.payload)) {
      throw StateError('Old reader changed generation.');
    }
    return {
      'definitions': units.length,
      'initialObjects': before.length,
      'initialObjectBytes':
          before.values.fold<int>(0, (sum, length) => sum + length),
      'newObjects': newObjects.length,
      'newObjectBytes':
          newObjects.fold<int>(0, (sum, entry) => sum + entry.value),
      'headBytes':
          await File('${directory.path}/${CatalogStorageStore.headStorageKey}')
              .length(),
      'historyChangedResources': history.changes.length,
      if (measure) 'coldAdmissionMicros': admission.elapsedMicroseconds,
      if (measure) 'warmPlanAndApplyMicros': edit.elapsedMicroseconds,
      'existingObjectsUnchanged': true,
      'undoCollectionRestartRedo': true,
      'oldReaderStable': true,
    };
  } finally {
    await reader?.close();
    await session?.close();
    await directory.delete(recursive: true);
  }
}

Future<Map<String, int>> _inventory(Directory directory) async {
  final result = <String, int>{};
  await for (final file
      in Directory('${directory.path}/catalog/objects').list()) {
    final name = file.path.split('/').last;
    final bytes = await (file as File).readAsBytes();
    if (name != '${sha256.convert(bytes)}.json') {
      throw StateError(
          'An immutable object no longer matches its content hash.');
    }
    result[name] = bytes.length;
  }
  return result;
}

List<CatalogDefinitionUnit> _nativeUnits(Map<String, dynamic> source) {
  final smart = source['smartTileCatalog'] as Map<String, dynamic>;
  final units = <CatalogDefinitionUnit>[];
  for (final asset in (source['assets'] as List).cast<Map<String, dynamic>>()) {
    final tileset = ProjectTilesetEntry(
        id: asset['id'] as String,
        name: asset['name'] as String,
        relativePath: asset['logicalPath'] as String,
        source: ProjectTilesetSource.regularAtlas(
            assetId: asset['id'] as String,
            pixelWidth: asset['pixelWidth'] as int,
            pixelHeight: asset['pixelHeight'] as int,
            tileWidth: (asset['tileWidth'] ?? 32) as int,
            tileHeight: (asset['tileHeight'] ?? 32) as int));
    units.add(CatalogDefinitionUnit(
        key: CatalogDefinitionKey(CatalogDefinitionKind.tileset, tileset.id),
        payload: tileset.toJson()));
  }
  for (final (section, kind) in [
    ('categories', CatalogDefinitionKind.smartTileCategory),
    ('atlases', CatalogDefinitionKind.smartTileAtlas),
    ('materials', CatalogDefinitionKind.smartTileMaterial),
    ('animations', CatalogDefinitionKind.smartTileAnimation),
    ('patterns', CatalogDefinitionKind.smartTilePattern),
    ('presets', CatalogDefinitionKind.smartTilePreset),
  ]) {
    for (final payload
        in (smart[section] as List).cast<Map<String, dynamic>>()) {
      final references = <CatalogDefinitionKey>{};
      void collect(Object? value) {
        if (value is List) {
          for (final child in value) {
            collect(child);
          }
        } else if (value is Map) {
          for (final entry in value.entries) {
            final targetKind = switch (entry.key) {
              'tilesetId' => CatalogDefinitionKind.tileset,
              'atlasId' => CatalogDefinitionKind.smartTileAtlas,
              'animationId' => CatalogDefinitionKind.smartTileAnimation,
              'materialId' ||
              'defaultMaterialId' ||
              'allowedMaterialIds' =>
                CatalogDefinitionKind.smartTileMaterial,
              'categoryId' => CatalogDefinitionKind.smartTileCategory,
              _ => null,
            };
            final child = entry.value;
            if (targetKind != null && child is String && child.isNotEmpty) {
              references.add(CatalogDefinitionKey(targetKind, child));
            } else if (targetKind != null && child is List) {
              references.addAll(child
                  .cast<String>()
                  .map((id) => CatalogDefinitionKey(targetKind, id)));
            }
            collect(child);
          }
        }
      }

      collect(payload);
      units.add(CatalogDefinitionUnit(
          key: CatalogDefinitionKey(kind, payload['id'] as String),
          payload: payload,
          references: references));
    }
  }
  final diagnostics = validateProjectSmartTileCatalog(
      catalog: ProjectSmartTileCatalog.fromJson(smart),
      projectTilesetIds: units
          .where((unit) => unit.key.kind == CatalogDefinitionKind.tileset)
          .map((unit) => unit.key.id));
  if (diagnostics.any((value) => value.isError)) {
    throw StateError('Invalid native FRLG catalog.');
  }
  return units;
}
