import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../ports/project_file_reader.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/authoring_payload.dart';
import '../../transactions/change_set.dart';
import 'catalog_map_directory_entries.dart';
import 'catalog_metadata_documents.dart';

export 'catalog_map_directory_entries.dart'
    show CatalogMapDirectoryElement, CatalogMapDirectoryEntries;

sealed class CatalogMapDirectoryRead {
  const CatalogMapDirectoryRead();
}

final class CatalogMapDirectoryPages extends CatalogMapDirectoryRead {
  const CatalogMapDirectoryPages(this.pages, this.unknownMapIds);
  final List<CatalogMapDirectoryEntries> pages;
  final List<String> unknownMapIds;
}

final class CatalogMapDirectoryPreparationRequired
    extends CatalogMapDirectoryRead {
  const CatalogMapDirectoryPreparationRequired(this.reason);
  final String reason;
}

typedef CatalogMapDirectoryPatch = ({
  List<CatalogDefinitionUnit> upserts,
  List<CatalogDefinitionKey> removals
});

abstract final class CatalogMapDirectory {
  static const preparationScope = 'mapDirectory';

  static final marker = CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, 'mapDirectoryIndex');

  static CatalogDefinitionKey pageKey(String mapId) => CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState,
      jsonEncode(['mapDirectory', mapId]));

  static Future<bool> prepared(CatalogSnapshot snapshot) async =>
      (await snapshot.lookup(marker))?.payload['schemaVersion'] == 1;

  static Future<CatalogMapDirectoryRead> read(
      CatalogSnapshot snapshot, Iterable<String> mapIds) async {
    final state = await snapshot.lookup(marker);
    if (state == null) {
      return const CatalogMapDirectoryPreparationRequired('absent');
    }
    if (state.payload['schemaVersion'] != 1) {
      return const CatalogMapDirectoryPreparationRequired('stale');
    }
    final pages = <CatalogMapDirectoryEntries>[];
    final unknown = <String>[];
    for (final mapId in mapIds) {
      final page = await snapshot.lookup(pageKey(mapId));
      if (page != null) {
        pages.add(_decode(page));
      } else if (await snapshot
              .lookup(CatalogMetadataDocuments.documentKey('maps', mapId)) ==
          null) {
        unknown.add(mapId);
      } else {
        return const CatalogMapDirectoryPreparationRequired('stale');
      }
    }
    return CatalogMapDirectoryPages(pages, unknown);
  }

  static Future<
      ({
        List<CatalogDefinitionUnit> units,
        String revision,
        Future<String> Function() currentRevision
      })> prepare({
    required CatalogSnapshot snapshot,
    required CatalogStorageStore store,
  }) async {
    final catalog = await PortableProjectCatalog.fromSnapshot(snapshot,
        metadataFields: {'maps'});
    final observed = <String, String?>{};
    final units = <CatalogDefinitionUnit>[
      CatalogDefinitionUnit(
          key: marker, payload: {'id': marker.id, 'schemaVersion': 1}),
    ];
    for (final entry in catalog.projectMetadata.maps) {
      validateProjectRelativePath(entry.relativePath);
      final payload =
          await store.gateway.captureResourcePayload(entry.relativePath);
      observed[entry.relativePath] = payload?.resourceRevision;
      if (payload == null) {
        throw CatalogStorageException('catalog.map_directory.map_missing',
            'The map ${entry.id} is missing, so its elements cannot be listed.');
      }
      final List<int> bytes;
      try {
        bytes = await payload.readBytes();
      } finally {
        await payload.release();
      }
      final entries = CatalogMapDirectoryEntries.fromMapBytes(bytes);
      if (entries.mapId != entry.id) {
        throw const FormatException('catalog.map_directory.map_identity');
      }
      units.add(_page(entries));
    }
    for (final entry in observed.entries) {
      if (await store.gateway.readResourceRevision(entry.key) != entry.value) {
        throw const CatalogStorageException(
            'catalog.map_directory.changed_during_preparation',
            'A map changed while its elements were being listed.');
      }
    }
    String fingerprint(Object? root, Map<String, String?> resources) =>
        computeAuthoringJsonFingerprint(
            {'catalog': root, 'resources': resources},
            logicalName: 'map-directory');
    return (
      units: units,
      revision: fingerprint(snapshot.root.toJson(), observed),
      currentRevision: () async =>
          fingerprint((await store.readHead())?.toJson(), {
            for (final path in observed.keys)
              path: await store.gateway.readResourceRevision(path)
          }),
    );
  }

  static Future<CatalogMapDirectoryPatch> maintain({
    required CatalogSnapshot snapshot,
    required Iterable<AuthoringResourceChange> additionalChanges,
  }) async {
    final result = (
      upserts: <CatalogDefinitionUnit>[],
      removals: <CatalogDefinitionKey>[]
    );
    final changes = [
      for (final change in additionalChanges)
        if (change.resource.kind == 'map') change
    ];
    if (changes.isEmpty || !await prepared(snapshot)) return result;
    Future<CatalogMapDirectoryEntries?> entries(
            AuthoringPayload? payload) async =>
        payload == null
            ? null
            : CatalogMapDirectoryEntries.fromMapBytes(
                await payload.readBytes());
    for (final change in changes) {
      final next = await entries(change.afterPayload);
      final previous = await entries(change.beforePayload);
      if (next != null) {
        final page = _page(next);
        final existing = await snapshot.lookup(page.key);
        if (existing == null ||
            canonicalAuthoringJson(existing.payload) !=
                canonicalAuthoringJson(page.payload)) {
          result.upserts.add(page);
        }
      }
      if (previous != null &&
          previous.mapId != next?.mapId &&
          await snapshot.lookup(pageKey(previous.mapId)) != null) {
        result.removals.add(pageKey(previous.mapId));
      }
    }
    return result;
  }

  static CatalogDefinitionUnit _page(CatalogMapDirectoryEntries entries) {
    final key = pageKey(entries.mapId);
    return CatalogDefinitionUnit(key: key, payload: {
      'id': key.id,
      'schemaVersion': 1,
      'mapId': entries.mapId,
      'name': entries.name,
      'elements': entries.elements,
    });
  }

  static CatalogMapDirectoryEntries _decode(CatalogDefinitionUnit unit) {
    final payload = unit.payload;
    final elements = payload['elements'];
    if (payload['schemaVersion'] != 1 ||
        payload['mapId'] is! String ||
        payload['name'] is! String ||
        elements is! List ||
        elements.any((element) => element is! Map)) {
      throw const FormatException('catalog.map_directory.page_invalid');
    }
    return CatalogMapDirectoryEntries(
        payload['mapId'] as String, payload['name'] as String, [
      for (final element in elements) Map<String, Object?>.from(element as Map)
    ]);
  }
}
