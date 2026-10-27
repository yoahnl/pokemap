import 'resource_usage_report.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/local_transaction_file_gateway.dart';
import '../transactions/transaction_journal.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import '../ports/transaction_file_gateway.dart';

const exteriorReferenceNamespace = 'authoring/exterior-decoration';

String exteriorReferenceIndexPath(CatalogDefinitionKey key) =>
    '$exteriorReferenceNamespace/references/${key.kind.name}/${sha256.convert(utf8.encode(key.id))}.json';
String exteriorReferenceBackupPath(CatalogDefinitionKey key) =>
    '${exteriorReferenceIndexPath(key)}.backup';
String exteriorReferenceAdmissionPath(String mapId) =>
    '$exteriorReferenceNamespace/owners/${sha256.convert(utf8.encode(mapId))}/admission.json';
String exteriorReferenceOwnerPath(String mapId, String kind, String id) =>
    '$exteriorReferenceNamespace/owners/${sha256.convert(utf8.encode(mapId))}/$kind/${sha256.convert(utf8.encode(id))}.json';

Set<CatalogDefinitionKey> exteriorSectorReferences(
        ExteriorDecorationSector sector) =>
    {
      for (final instance in sector.scene.instances)
        CatalogDefinitionKey(CatalogDefinitionKind.model3d, instance.modelId),
      if (sector.scene.cliffFrame case final frame?)
        CatalogDefinitionKey(
            CatalogDefinitionKind.smartTileAtlas, frame.atlasId),
      for (final layer in sector.layers)
        ...switch (layer) {
          SmartTileLayer() => {
              CatalogDefinitionKey(
                  CatalogDefinitionKind.smartTilePreset, layer.presetId),
              for (final id in layer.materialPalette.skip(1))
                CatalogDefinitionKey(
                    CatalogDefinitionKind.smartTileMaterial, id),
              for (final stroke in layer.patternStrokes)
                CatalogDefinitionKey(
                    CatalogDefinitionKind.smartTilePattern, stroke.patternId),
            },
          EnvironmentLayer() => {
              for (final area in layer.content.areas)
                CatalogDefinitionKey(
                    CatalogDefinitionKind.environmentPreset, area.presetId),
            },
          BorderLayer() => {
              for (final feature in layer.content.features)
                CatalogDefinitionKey(
                    CatalogDefinitionKind.borderRecord, feature.blueprintId),
            },
          _ => <CatalogDefinitionKey>{},
        },
    };
Set<CatalogDefinitionKey> exteriorBorderReferences(
        ExteriorDecorationBorder border) =>
    {
      CatalogDefinitionKey(
          CatalogDefinitionKind.borderRecord, border.feature.blueprintId),
      for (final instance in border.instances)
        CatalogDefinitionKey(CatalogDefinitionKind.model3d, instance.modelId),
    };

final class ExteriorReferenceOwner {
  ExteriorReferenceOwner(this.mapId, this.unitKind, this.unitId) {
    if (![mapId, unitId]
            .every((id) => RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) ||
        !const {'sector', 'border'}.contains(unitKind)) {
      throw const FormatException('exterior.reference_index_invalid');
    }
  }
  factory ExteriorReferenceOwner.fromJson(Map<String, dynamic> json) {
    if (json.length != 3 ||
        json['mapId'] is! String ||
        json['unitKind'] is! String ||
        json['unitId'] is! String) {
      throw const FormatException('exterior.reference_index_invalid');
    }
    return ExteriorReferenceOwner(json['mapId'] as String,
        json['unitKind'] as String, json['unitId'] as String);
  }
  final String mapId, unitKind, unitId;
  String get identity => '$mapId:$unitKind:$unitId';
  String get unitPath => unitKind == 'border'
      ? 'maps/$mapId.decoration/borders/$unitId.json'
      : 'maps/$mapId.decoration/$unitId.json';
  Map<String, dynamic> toJson() =>
      {'mapId': mapId, 'unitKind': unitKind, 'unitId': unitId};
}

Map<String, ExteriorReferenceOwner> decodeExteriorReferenceOwners(
    List<int>? bytes, CatalogDefinitionKey key) {
  if (bytes == null) return {};
  if (bytes.length > 16 * 1024 * 1024) {
    throw const FormatException('exterior.reference_index_invalid');
  }
  final json = jsonDecode(utf8.decode(bytes));
  if (json is! Map<String, dynamic> ||
      json.length != 4 ||
      json['schemaVersion'] != 1 ||
      json['kind'] != key.kind.name ||
      json['id'] != key.id ||
      json['owners'] is! List) {
    throw const FormatException('exterior.reference_index_invalid');
  }
  final result = <String, ExteriorReferenceOwner>{};
  for (final value in json['owners'] as List) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('exterior.reference_index_invalid');
    }
    final owner = ExteriorReferenceOwner.fromJson(value);
    if (result.containsKey(owner.identity)) {
      throw const FormatException('exterior.reference_index_invalid');
    }
    result[owner.identity] = owner;
  }
  return result;
}

Map<String, dynamic> encodeExteriorReferenceOwners(
        CatalogDefinitionKey key, Map<String, ExteriorReferenceOwner> owners) =>
    {
      'schemaVersion': 1,
      'kind': key.kind.name,
      'id': key.id,
      'owners': [
        for (final id in owners.keys.toList()..sort()) owners[id]!.toJson()
      ],
    };

Future<void> requireUnusedExteriorReferences(
    Iterable<CatalogDefinitionKey> removed,
    TransactionFileGateway gateway) async {
  const kinds = {
    CatalogDefinitionKind.model3d,
    CatalogDefinitionKind.smartTileMaterial,
    CatalogDefinitionKind.smartTilePreset,
    CatalogDefinitionKind.smartTilePattern,
    CatalogDefinitionKind.smartTileAtlas,
    CatalogDefinitionKind.environmentPreset,
    CatalogDefinitionKind.borderRecord
  };
  final selected = removed.where((key) => kinds.contains(key.kind)).toSet();
  if (selected.isEmpty) return;
  if (gateway is LocalTransactionFileGateway) {
    final scoped = await gateway.inNamespace('exterior-decoration');
    if ((await scoped.listJournals()).any((journal) =>
        journal.status != AuthoringTransactionStatus.committed &&
        journal.status != AuthoringTransactionStatus.compensated)) {
      throw const FormatException(
          'exterior.reference_index_recovery_required: recover the pending decoration transaction before removing resources.');
    }
  }
  for (final key in selected) {
    final bytes = await gateway.readResource(exteriorReferenceIndexPath(key));
    if (bytes == null &&
        await gateway.readResource(exteriorReferenceBackupPath(key)) != null) {
      throw const FormatException(
          'exterior.reference_index_recovery_required: a known incoming index is missing.');
    }
    final owners = decodeExteriorReferenceOwners(bytes, key);
    for (final owner in owners.values) {
      final bytes = await gateway.readResource(owner.unitPath);
      if (bytes == null || bytes.length > 8 * 1024 * 1024) {
        throw const FormatException(
            'exterior.reference_index_recovery_required: declared owner is missing.');
      }
      final json =
          Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
      final references = owner.unitKind == 'border'
          ? exteriorBorderReferences(ExteriorDecorationBorder.fromJson(json))
          : exteriorSectorReferences(ExteriorDecorationSector.fromJson(json));
      if (!references.contains(key)) {
        throw const FormatException(
            'exterior.reference_index_recovery_required: declared owner differs.');
      }
    }
    if (owners.isNotEmpty) {
      throw FormatException(
          'exterior.resource_in_use: ${key.kind.name}:${key.id} is used by ${owners.values.first.identity}.');
    }
  }
}

Iterable<CatalogDefinitionKey> exteriorDeletedDefinitions(
    String action, Map<String, Object?> parameters) sync* {
  final target = switch (action) {
    'model3d.delete' => (CatalogDefinitionKind.model3d, 'modelId'),
    'smart_tile.preset.delete' => (
        CatalogDefinitionKind.smartTilePreset,
        'presetId'
      ),
    'smart_tile.pattern.delete' => (
        CatalogDefinitionKind.smartTilePattern,
        'patternId'
      ),
    'environment.preset.delete' => (
        CatalogDefinitionKind.environmentPreset,
        'presetId'
      ),
    'border.blueprint.delete' => (
        CatalogDefinitionKind.borderRecord,
        'blueprintId'
      ),
    _ => null,
  };
  if (target != null && parameters[target.$2] is String) {
    yield CatalogDefinitionKey(target.$1, parameters[target.$2] as String);
  }
}

Future<ResourceUsageReport> projectExteriorReferenceUsages(
    ResourceUsageReport report,
    Future<List<int>?> Function(String, int) readResource) async {
  CatalogDefinitionKey? keyFor(String family, String id) => switch (family) {
        'models3d' ||
        'model3d' =>
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, id),
        'terrains' ||
        'preset' =>
          CatalogDefinitionKey(CatalogDefinitionKind.smartTilePreset, id),
        'materials' ||
        'smartTileMaterial' =>
          CatalogDefinitionKey(CatalogDefinitionKind.smartTileMaterial, id),
        'borders' ||
        'border' =>
          CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, id),
        'environments' ||
        'environmentPreset' =>
          CatalogDefinitionKey(CatalogDefinitionKind.environmentPreset, id),
        'smartTileAtlas' =>
          CatalogDefinitionKey(CatalogDefinitionKind.smartTileAtlas, id),
        'smartTilePattern' =>
          CatalogDefinitionKey(CatalogDefinitionKind.smartTilePattern, id),
        _ => null,
      };
  final direct = keyFor(report.target.family, report.target.id);
  final keys = {
    if (direct != null) direct,
    for (final entry in report.entries)
      if (keyFor(entry.ownerKind, entry.ownerId) case final key?) key
  };
  final entries = [...report.entries], issues = [...report.coverageIssues];
  final fingerprints = {...report.fingerprints}, seen = <String>{};
  for (final key in keys) {
    try {
      final path = exteriorReferenceIndexPath(key),
          bytes = await readResource(path, 16 * 1024 * 1024);
      if (bytes == null &&
          await readResource(exteriorReferenceBackupPath(key), 4096) != null) {
        throw const FormatException('missing known incoming index');
      }
      fingerprints['exteriorReference:$path'] = bytes == null
          ? computeAuthoringJsonFingerprint(null, logicalName: path)
          : computeAuthoringBytesFingerprint(bytes, logicalName: path);
      final owners = decodeExteriorReferenceOwners(bytes, key);
      for (final owner in owners.values) {
        final raw = await readResource(owner.unitPath, 8 * 1024 * 1024);
        if (raw == null) throw const FormatException('missing exterior owner');
        final json =
            Map<String, dynamic>.from(jsonDecode(utf8.decode(raw)) as Map);
        final refs = owner.unitKind == 'border'
            ? exteriorBorderReferences(ExteriorDecorationBorder.fromJson(json))
            : exteriorSectorReferences(ExteriorDecorationSector.fromJson(json));
        if (!refs.contains(key)) {
          throw const FormatException('changed exterior owner');
        }
        if (!seen.add(owner.identity)) continue;
        entries.add(ResourceUsageEntry(
            ownerKind: 'map',
            ownerId: owner.mapId,
            ownerLabel:
                'Décor extérieur · ${owner.mapId} · ${owner.unitKind}:${owner.unitId}',
            location: '${owner.unitPath} · ${owner.unitKind}:${owner.unitId}',
            relation: key == direct
                ? ResourceUsageRelation.direct
                : ResourceUsageRelation.indirect,
            mapId: owner.mapId,
            entityId: 'exterior:${owner.unitKind}:${owner.unitId}'));
      }
    } on Object {
      issues.add(
          'resource.usages.exterior_reference_index_invalid:${key.kind.name}:${key.id}');
    }
  }
  return ResourceUsageReport(
      target: report.target,
      revision: report.revision,
      fingerprints: fingerprints,
      entries: entries,
      coverageIssues: issues);
}
