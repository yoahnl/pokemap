import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../references/resource_usage_documents.dart';
import '../../references/resource_usage_walk.dart';
import '../../transactions/change_set.dart';
import '../../domains/narrative/dialogue_authoring_service.dart';
import '../../domains/assets/project_media_store.dart';
import 'catalog_metadata_documents.dart';
import '../project_snapshot.dart';

part 'catalog_resource_usage_sources.dart';
part 'catalog_resource_usage_mutations.dart';

abstract final class CatalogResourceUsageIndex {
  static final marker = CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, 'resourceUsageIndex');

  static CatalogDefinitionKey _key(String kind, String identity) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          '$kind:${crypto.sha256.convert(utf8.encode(identity))}');

  static String _source(CatalogDefinitionKey key) => jsonEncode(key.toJson());

  static bool owns(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.workspaceState &&
      (key == marker ||
          key.id.startsWith('resourceUsageSource:') ||
          key.id.startsWith('resourceUsageConsumers:'));

  static bool isSource(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.workspaceState &&
      key.id.startsWith('resourceUsageSource:');

  static Future<bool> prepared(CatalogSnapshot snapshot) async {
    final unit = await snapshot.lookup(marker);
    if (unit == null) return false;
    if (unit.payload['schemaVersion'] != 1) {
      throw const FormatException('catalog.resource_usage.invalid_version');
    }
    return unit.payload['sourceRevisionsVersion'] == 1;
  }

  static Future<void> requirePrepared(CatalogSnapshot snapshot) async {
    if (!await prepared(snapshot)) {
      throw const CatalogStorageException(
          'catalog.resource_usage.preparation_required',
          'Explicitly prepare the resource usage index before changing resource scope.');
    }
  }

  static Future<Set<String>> directDependencies(CatalogSnapshot snapshot, CatalogDefinitionUnit unit) async =>
      (await _catalogUsageSource(unit, snapshot.lookup))?.targets ?? const {};

  static Future<({Set<String> targets, String revision})> dialogueSourceDependencies(CatalogSnapshot snapshot, String id) async {
    await requirePrepared(snapshot);
    final identity = 'external:dialogueSource:$id';
    final unit = await snapshot.lookup(_key('resourceUsageSource', identity));
    final revision = unit?.payload['resourceRevision'];
    if (unit == null || revision is! String || revision.isEmpty) {
      throw const CatalogStorageException('resource_library.usage_incomplete', 'Prepare the dialogue resource usage index before attaching this Scene.');
    }
    return (targets: _strings(unit, identity, 'targets').toSet(), revision: revision);
  }

  static Future<bool> familyHasMembers(
      CatalogSnapshot snapshot, String id) async {
    await requirePrepared(snapshot);
    final identity = 'family:$id';
    return _strings(
            await snapshot.lookup(_key('resourceUsageConsumers', identity)),
            identity,
            'sources')
        .isNotEmpty;
  }

  static Future<Set<String>> consumerOwners(
      CatalogSnapshot snapshot, String identity) async {
    await requirePrepared(snapshot);
    final owners = <String>{};
    final consumers =
        await snapshot.lookup(_key('resourceUsageConsumers', identity));
    for (final source in _strings(consumers, identity, 'sources')) {
      final document =
          await snapshot.lookup(_key('resourceUsageSource', source));
      if (document == null ||
          document.payload['identity'] != source ||
          !(document.payload['targets'] as List).contains(identity)) {
        throw const FormatException('catalog.resource_usage.stale_consumer');
      }
      owners.add(document.payload['owner'] as String);
    }
    return owners;
  }

  static Future<Set<String>> mapUsages(
      CatalogSnapshot snapshot, String kind, String id, Iterable<String> mapIds,
      {Future<Iterable<String>> Function()? readMapIds}) async {
    await requirePrepared(snapshot);
    final first = '${switch (kind) {
      'smartTilePreset' => 'preset',
      'borderBlueprint' => 'border',
      _ => kind,
    }}:$id';
    final pending = <String>[first];
    final visited = <String>{first};
    final maps = <String>{};
    final sources = <String>{};
    for (var i = 0; i < pending.length; i++) {
      final identity = pending[i];
      final consumers =
          await snapshot.lookup(_key('resourceUsageConsumers', identity));
      for (final source in _strings(consumers, identity, 'sources')) {
        if (!sources.add(source)) continue;
        final document =
            await snapshot.lookup(_key('resourceUsageSource', source));
        if (document == null ||
            document.payload['identity'] != source ||
            !(document.payload['targets'] as List).contains(identity)) {
          throw const FormatException('catalog.resource_usage.stale_consumer');
        }
        final owner = document.payload['owner'] as String;
        if (owner.startsWith('map:')) maps.add(owner.substring(4));
        if (owner == 'project:project') {
          maps.addAll(readMapIds == null ? mapIds : await readMapIds());
        }
        if (visited.add(owner)) pending.add(owner);
        if (visited.length + sources.length > snapshot.limits.maxClosureNodes) {
          throw const FormatException('catalog.resource_usage.closure_limit');
        }
      }
    }
    return Set.unmodifiable(maps);
  }

  static Set<String> _strings(
      CatalogDefinitionUnit? unit, String identity, String field) {
    if (unit == null) return {};
    final payload = unit.payload;
    final values = payload[field];
    if (payload['schemaVersion'] != 1 ||
        payload['identity'] != identity ||
        values is! List ||
        values.any((value) => value is! String)) {
      throw const FormatException('catalog.resource_usage.invalid_entry');
    }
    final result = values.cast<String>().toSet();
    if (result.length != values.length ||
        jsonEncode(result.toList()..sort()) != jsonEncode(values)) {
      throw const FormatException('catalog.resource_usage.invalid_order');
    }
    return result;
  }

  static CatalogDefinitionUnit _document(
          String source, String owner, Set<String> targets,
          {String? revision}) =>
      CatalogDefinitionUnit(key: _key('resourceUsageSource', source), payload: {
        'schemaVersion': 1,
        'identity': source,
        'owner': owner,
        'targets': targets.toList()..sort(),
        'resourceRevision': revision,
      });

  static CatalogDefinitionUnit _consumers(
          String identity, Set<String> sources) =>
      CatalogDefinitionUnit(
          key: _key('resourceUsageConsumers', identity),
          payload: {
            'schemaVersion': 1,
            'identity': identity,
            'sources': sources.toList()..sort(),
          });

  static Future<List<CatalogDefinitionUnit>> initialize({
    required CatalogSnapshot catalog,
    required ProjectSnapshot project,
    Iterable<CatalogDefinitionUnit>? units,
  }) async {
    final issues = <String>[];
    final documents = resourceUsageDocuments(project, issues);
    if (issues.isNotEmpty) {
      throw CatalogStorageException('resource_library.usage_incomplete',
          'The resource index needs a complete saved project: ${issues.join(', ')}');
    }
    final records = <CatalogDefinitionUnit>[];
    for (final unit in units ?? await catalog.readAllUnits()) {
      final document = await _catalogUsageSource(unit, catalog.lookup);
      if (document == null || document.targets.isEmpty) continue;
      records
          .add(_document(_source(unit.key), document.owner, document.targets));
    }
    for (final document in documents.where((doc) => const {
          'map',
          'dialogueSource',
          'media',
          'pokemonMedia'
        }.contains(doc.kind))) {
      final source = 'external:${document.identity}';
      final value = _usageSource(document);
      final revisionIdentity = document.kind == 'media'
          ? projectMediaCatalogResourceIdentity
          : document.identity;
      final revision = project.resourceFingerprints[revisionIdentity];
      if (revision == null) {
        throw const CatalogStorageException('resource_library.usage_incomplete',
            'Every external usage document needs its captured content revision.');
      }
      records.add(
          _document(source, value.owner, value.targets, revision: revision));
    }
    final consumers = <String, Set<String>>{};
    for (final record in records) {
      for (final target in (record.payload['targets'] as List).cast<String>()) {
        consumers
            .putIfAbsent(target, () => {})
            .add(record.payload['identity'] as String);
      }
    }
    return [
      CatalogDefinitionUnit(
          key: marker,
          payload: {'schemaVersion': 1, 'sourceRevisionsVersion': 1}),
      ...records,
      for (final entry in consumers.entries) _consumers(entry.key, entry.value),
    ];
  }

  static Future<List<CatalogDefinitionUnit>> maintain({
    required CatalogSnapshot snapshot,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
    required Iterable<AuthoringResourceChange> additionalChanges,
    Iterable<CatalogDefinitionUnit> restoredExternalSources = const [],
  }) =>
      _CatalogResourceUsageMutation.maintain(
        snapshot: snapshot,
        upserts: upserts,
        removals: removals,
        additionalChanges: additionalChanges,
        restoredExternalSources: restoredExternalSources,
      );
}
