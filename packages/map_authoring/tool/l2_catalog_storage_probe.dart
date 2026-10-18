import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Expected a prepared FRLG specification path.');
  }
  final sourceBytes = await File(arguments.single).readAsBytes();
  final source = jsonDecode(utf8.decode(sourceBytes)) as Map<String, dynamic>;
  final smart = source['smartTileCatalog'] as Map<String, dynamic>;
  final typed = ProjectSmartTileCatalog.fromJson(smart);
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
        tileHeight: (asset['tileHeight'] ?? 32) as int,
      ),
    );
    units.add(CatalogDefinitionUnit(
      key: CatalogDefinitionKey(CatalogDefinitionKind.tileset, tileset.id),
      payload: tileset.toJson(),
    ));
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
              for (final id in child.cast<String>()) {
                references.add(CatalogDefinitionKey(targetKind, id));
              }
            }
            collect(child);
          }
        }
      }

      collect(payload);
      units.add(CatalogDefinitionUnit(
        key: CatalogDefinitionKey(kind, payload['id'] as String),
        payload: payload,
        references: references,
      ));
    }
  }
  final nativeDiagnostics = validateProjectSmartTileCatalog(
    catalog: typed,
    projectTilesetIds: units
        .where((unit) => unit.key.kind == CatalogDefinitionKind.tileset)
        .map((unit) => unit.key.id),
  );
  if (nativeDiagnostics.any((diagnostic) => diagnostic.isError)) {
    throw StateError('The prepared native Smart Tile catalog is invalid.');
  }
  final build = CatalogStorageBuilder().build(units);
  final reads = <String>[];
  var readBytes = 0;
  final snapshot = await CatalogSnapshot.open(
    root: build.root,
    readObject: (reference) async {
      reads.add(reference.sha256);
      final bytes = build.objects[reference.sha256];
      if (bytes == null) throw StateError('Missing compiled object.');
      readBytes += bytes.length;
      return bytes;
    },
  );
  final openReads = reads.length;
  final openBytes = readBytes;
  final animated = units.firstWhere((unit) =>
      unit.key.kind == CatalogDefinitionKind.smartTilePattern &&
      unit.references.any((reference) =>
          reference.kind == CatalogDefinitionKind.smartTileAnimation));
  reads.clear();
  readBytes = 0;
  final resolved = await snapshot.lookup(animated.key);
  if (resolved == null ||
      canonicalAuthoringJson(resolved.payload) !=
          canonicalAuthoringJson(animated.payload)) {
    throw StateError('Targeted native definition changed.');
  }
  final lookupReads = reads.length;
  final lookupBytes = readBytes;
  reads.clear();
  readBytes = 0;
  final closure = await snapshot.closure([animated.key]);
  final closureReads = reads.length;
  final closureBytes = readBytes;
  if (!closure.any((unit) =>
          unit.key.kind == CatalogDefinitionKind.smartTileAnimation) ||
      !closure.any(
          (unit) => unit.key.kind == CatalogDefinitionKind.smartTileAtlas) ||
      !closure.any((unit) => unit.key.kind == CatalogDefinitionKind.tileset)) {
    throw StateError('The native animated closure is incomplete.');
  }
  await snapshot.validate();
  for (final original in units) {
    final restored = await snapshot.lookup(original.key);
    if (restored == null ||
        canonicalAuthoringJson(restored.payload) !=
            canonicalAuthoringJson(original.payload)) {
      throw StateError('Native payload changed: ${original.key}.');
    }
  }
  final temporaryProject =
      await Directory.systemTemp.createTemp('avelune-l2-native-');
  try {
    final store =
        await CatalogStorageStore.open(projectRoot: temporaryProject.path);
    final subset = CatalogStorageBuilder().build(closure);
    final published = await store.publish(subset, expectedRootRevision: null);
    final reopened = await store.openSnapshot();
    final original = await reopened!.snapshot.lookup(animated.key);
    if (canonicalAuthoringJson(original!.payload) !=
        canonicalAuthoringJson(animated.payload)) {
      throw StateError('The persisted native unit changed.');
    }
    final nextBuild = CatalogStorageBuilder().build([
      for (final unit in closure)
        if (unit.key == animated.key)
          CatalogDefinitionUnit(
            key: unit.key,
            payload: {...unit.payload, 'name': 'L2 snapshot identity proof'},
            references: unit.references,
          )
        else
          unit,
    ]);
    final next = await store.publish(nextBuild,
        expectedRootRevision: published.rootRevision);
    if ((await published.snapshot.lookup(animated.key))!.payload['name'] !=
            animated.payload['name'] ||
        (await next.snapshot.lookup(animated.key))!.payload['name'] !=
            'L2 snapshot identity proof') {
      throw StateError('Native snapshots mixed generations.');
    }
  } finally {
    await temporaryProject.delete(recursive: true);
  }
  stdout.writeln(jsonEncode({
    'schema': 'avelune.catalog-storage.l2.native-probe.v1',
    'sourceSha256': sha256.convert(sourceBytes).toString(),
    'sourceBytes': sourceBytes.length,
    'scope': 'Prepared Smart Tile definitions and tileset metadata only.',
    'definitionCount': units.length,
    'counts': {
      for (final kind in CatalogDefinitionKind.values)
        if (units.any((unit) => unit.key.kind == kind))
          kind.name: units.where((unit) => unit.key.kind == kind).length,
    },
    'objectCount': build.objects.length,
    'objectBytes':
        build.objects.values.fold<int>(0, (sum, bytes) => sum + bytes.length),
    'root': build.root.toJson(),
    'open': {'reads': openReads, 'bytes': openBytes},
    'targetedLookup': {
      'id': animated.key.id,
      'reads': lookupReads,
      'bytes': lookupBytes
    },
    'targetedClosure': {
      'definitions': closure.length,
      'reads': closureReads,
      'bytes': closureBytes
    },
    'allNativePayloadsIdentical': true,
    'nativeCatalogErrors': 0,
    'nativeFilesystemPublishReopen': true,
    'nativeFilesystemGenerationsIsolated': true,
    'temporaryFilesystemProofRemoved': true,
    'fullPackQualified': false,
    'studioIntegrated': false,
    'playerIntegrated': false,
    'mobilePerformanceQualified': false,
    'verdict': 'PASS',
  }));
}
