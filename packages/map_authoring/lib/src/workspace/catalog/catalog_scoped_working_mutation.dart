import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../transactions/plan_store.dart';
import 'catalog_workshop_selection.dart';
import 'catalog_metadata_documents.dart';

final class CatalogScopedWorkingMutation {
  CatalogScopedWorkingMutation._(
      this.projectedProject,
      this.upserts,
      this.removals,
      this.additionalChanges,
      this.diff,
      this.workspaceFingerprint);

  final ProjectManifest projectedProject;
  final List<CatalogDefinitionUnit> upserts;
  final List<CatalogDefinitionKey> removals;
  final List<AuthoringResourceChange> additionalChanges;
  final AuthoringDiff diff;
  final String? workspaceFingerprint;

  static Future<CatalogScopedWorkingMutation> translate({
    required CatalogWorkshopSelection selection,
    required AuthoringPlan publicPlan,
  }) async {
    final before = selection.snapshot.manifest;
    var projected = before;
    final additional = <AuthoringResourceChange>[];
    for (final change in publicPlan.changeSet.changes) {
      if (change.storageKey == 'project.json') {
        if (change.afterPayload == null || change.resource.kind != 'project') {
          throw const FormatException(
              'catalog.workshop: invalid project change');
        }
        projected = ProjectManifest.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(await change.afterPayload!.readBytes()))
                as Map));
      } else {
        if (change.storageKey.startsWith('catalog/') ||
            change.storageKey.startsWith('.pokemap/')) {
          throw const FormatException('catalog.workshop: internal path');
        }
        additional.add(change);
      }
    }
    final previousJson = before.toJson();
    final projectedJson = projected.toJson();
    final changedFields = <String>{};
    for (final field in {...previousJson.keys, ...projectedJson.keys}) {
      if (_same(previousJson[field], projectedJson[field])) continue;
      if (!selection.writableSections.contains(field)) {
        throw AuthoringPlanException(
            code: 'catalog.mutation_outside_scope',
            message: 'The action changes the undeclared section $field.');
      }
      changedFields.add(field);
    }
    final catalog = selection.reader.catalog;
    final shellKey = CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata, 'publication-shell');
    final originalShell = (await catalog.lookup(shellKey))!;
    final oldShell =
        Map<String, Object?>.from(originalShell.payload['value'] as Map);
    final nextShell = Map<String, Object?>.from(oldShell);
    final upserts = <CatalogDefinitionUnit>[];
    final removals = <CatalogDefinitionKey>[];
    if (changedFields.contains('models3d') &&
        publicPlan.request.actionId == 'model3d.configure') {
      final previous = before.models3d.single;
      final next = projected.models3d.single;
      final expected = previous.copyWith(
        light: next.light,
        clearLight: next.light == null,
      );
      if (!_same(expected.toJson(), next.toJson())) {
        throw const FormatException('catalog.light: geometry changes are outside scope');
      }
      final key = CatalogDefinitionKey(CatalogDefinitionKind.model3d, previous.id);
      final original = (await catalog.lookup(key))!;
      upserts.add(CatalogDefinitionUnit(
        key: key,
        payload: {...original.payload, 'value': _preserveUntouched(
          original.payload['value'], previous.toJson(), next.toJson())},
        references: original.references,
      ));
      changedFields.remove('models3d');
    }
    final indexed = selection.metadataDocuments;
    if (indexed != null) {
      for (final field in changedFields.toList()) {
        final original = indexed.documents[field];
        if (original == null) continue;
        final beforeRows = {
          for (final row in (previousJson[field] as List).cast<Map>())
            row['id'] as String: row
        };
        final afterRows = {
          for (final row in (projectedJson[field] as List).cast<Map>())
            row['id'] as String: row
        };
        if (!afterRows.keys.toSet().containsAll(beforeRows.keys)) {
          CatalogWorkshopSelection.unsupported(publicPlan.request.actionId,
              'targeted metadata deletion support');
        }
        var position = indexed.counts[field]!;
        for (final entry in afterRows.entries) {
          if (_same(beforeRows[entry.key], entry.value)) continue;
          final existing = original[entry.key];
          if (existing != null) {
            final value =
                Map<String, Object?>.from(existing.payload['value'] as Map);
            value['definition'] = _preserveUntouched(
                value['definition'], beforeRows[entry.key], entry.value);
            upserts.add(CatalogDefinitionUnit(
                key: existing.key,
                payload: {...existing.payload, 'value': value},
                references: existing.references));
          } else {
            final key = CatalogMetadataDocuments.definitionKey(field, position);
            upserts.add(CatalogDefinitionUnit(key: key, payload: {
              'id': key.id,
              'section': r'$projectDefinition',
              'position': position++,
              'value': {'field': field, 'definition': entry.value},
            }));
          }
        }
        changedFields.remove(field);
      }
    }
    if (changedFields.isNotEmpty) {
      final built = PortableCatalogPublication.encodeProject(projected);
      final generated = PortableCatalogPublication.readSync(built.descriptor,
          readObject: (reference) => built.storage.objects[reference.sha256]!);
      final builtBefore = PortableCatalogPublication.encodeProject(before);
      final canonicalBefore = {
        for (final unit in PortableCatalogPublication.readSync(
            builtBefore.descriptor,
            readObject: (reference) =>
                builtBefore.storage.objects[reference.sha256]!).units)
          unit.key: unit
      };
      final generatedShell =
          generated.units.singleWhere((unit) => unit.key == shellKey);
      final generatedValue = generatedShell.payload['value'] as Map;
      for (final field in changedFields) {
        if (generatedValue.containsKey(field)) {
          nextShell[field] = generatedValue[field];
        } else {
          nextShell.remove(field);
        }
        final previousUnits = <CatalogDefinitionKey, CatalogDefinitionUnit>{};
        Future<void> collect(String type, [int? position]) async {
          final key = CatalogDefinitionKey(
              CatalogDefinitionKind.catalogMetadata,
              jsonEncode([type, field, if (position != null) position]));
          final unit = await catalog.lookup(key);
          if (unit != null) previousUnits[key] = unit;
        }

        final previous = previousJson[field];
        if (previous is List) {
          for (var position = 0; position < previous.length; position++) {
            await collect('projectDefinition', position);
          }
        }
        await collect('projectAggregateHeader');
        final header = previousUnits.values
            .where((u) => u.payload['section'] == r'$projectAggregateHeader')
            .firstOrNull;
        if (header != null) {
          final count = (header.payload['value'] as Map)['chunkCount'] as int;
          for (var position = 0; position < count; position++) {
            await collect('projectAggregateChunk', position);
          }
        }
        if (previous is Map) {
          final rawAggregate = header == null
              ? oldShell[field]
              : jsonDecode(utf8.decode([
                  for (var position = 0;
                      position < (header.payload['value'] as Map)['chunkCount'];
                      position++)
                    ...base64.decode((previousUnits[CatalogDefinitionKey(
                        CatalogDefinitionKind.catalogMetadata,
                        jsonEncode(['projectAggregateChunk', field, position]))]!
                        .payload['value'] as Map)['data'] as String)
                ]));
          final preserved = _preserveUntouched(rawAggregate, previous, projectedJson[field]);
          List<int> aggregateBytes = utf8.encode(jsonEncode(preserved));
          final generatedHeader = generated.units.where((unit) =>
              unit.payload['section'] == r'$projectAggregateHeader' &&
              (unit.payload['value'] as Map)['field'] == field).firstOrNull;
          if (header == null && generatedHeader == null && aggregateBytes.length <= 8192) {
            nextShell[field] = preserved;
            continue;
          }
          const chunkSize = 65536;
          final oldCount = header == null ? 0 : (header.payload['value'] as Map)['chunkCount'] as int;
          final minimumLength = oldCount == 0 ? 0 : (oldCount - 1) * chunkSize + 1;
          if (aggregateBytes.length < minimumLength) {
            aggregateBytes = [...aggregateBytes, ...List<int>.filled(minimumLength - aggregateBytes.length, 32)];
          }
          final chunkCount = (aggregateBytes.length + chunkSize - 1) ~/ chunkSize;
          CatalogDefinitionUnit aggregateUnit(String type, String section, int position,
              Map<String, Object?> value, {bool headerUnit = false}) {
            final key = CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
                jsonEncode([type, field, if (!headerUnit) position]));
            final existing = previousUnits[key];
            return CatalogDefinitionUnit(key: key, payload: {
              ...?existing?.payload, 'id': key.id, 'section': section,
              'position': position, 'value': <String, Object?>{...Map<String, Object?>.from(existing?.payload['value'] as Map? ?? const {}), ...value},
            }, references: existing?.references ?? const []);
          }
          upserts.add(aggregateUnit('projectAggregateHeader', r'$projectAggregateHeader', 0,
              {'field': field, 'sha256': crypto.sha256.convert(aggregateBytes).toString(),
               'byteLength': aggregateBytes.length, 'chunkCount': chunkCount}, headerUnit: true));
          for (var position = 0; position < chunkCount; position++) {
            final start = position * chunkSize;
            upserts.add(aggregateUnit('projectAggregateChunk', r'$projectAggregateChunk', position,
                {'field': field, 'data': base64.encode(aggregateBytes.sublist(start,
                    (start + chunkSize).clamp(0, aggregateBytes.length)))}));
          }
          nextShell[field] = <String, Object?>{};
          continue;
        }
        final desired = <CatalogDefinitionKey>{};
        for (final unit in generated.units) {
          final value = unit.payload['value'];
          if (unit.key == shellKey ||
              unit.key.kind != CatalogDefinitionKind.catalogMetadata ||
              value is! Map ||
              value['field'] != field) {
            continue;
          }
          desired.add(unit.key);
          final existing = previousUnits[unit.key];
          final priorCanonical = canonicalBefore[unit.key];
          if (existing != null &&
              priorCanonical != null &&
              _same(priorCanonical.payload, unit.payload)) {
            continue;
          }
          final payload = existing == null || priorCanonical == null
              ? unit.payload
              : Map<String, Object?>.from(_preserveUntouched(
                      existing.payload, priorCanonical.payload, unit.payload)
                  as Map);
          upserts.add(CatalogDefinitionUnit(
              key: unit.key,
              payload: payload,
              references: existing?.references ?? unit.references));
        }
        removals
            .addAll(previousUnits.keys.where((key) => !desired.contains(key)));
      }
      if (!_same(oldShell, nextShell)) {
        upserts.add(CatalogDefinitionUnit(
            key: originalShell.key,
            payload: {...originalShell.payload, 'value': nextShell},
            references: originalShell.references));
      }
    }
    if (removals.isNotEmpty) {
      CatalogWorkshopSelection.unsupported(publicPlan.request.actionId,
          'a targeted incoming-reference proof for removing catalog storage units');
    }
    final paths = selection.resourceRevisions.keys.toList()..sort();
    final resource = AuthoringResourceRef(
        kind: 'catalogHead',
        id: 'catalog',
        extensions: {'workshopResourcePaths': paths});
    final fingerprint = additional.isEmpty
        ? null
        : computeAuthoringJsonFingerprint({
            'catalogRevision': selection.reader.revision,
            'resources': {
              for (final change in additional)
                change.storageKey: change.afterRevision
            },
          }, logicalName: 'catalog-workshop-state.json');
    return CatalogScopedWorkingMutation._(
        projected,
        upserts,
        removals,
        additional,
        AuthoringDiff([
          for (final entry in publicPlan.changeSet.diff.entries)
            if (entry.resource.kind == 'project')
              AuthoringDiffEntry.fromJson(
                  {...entry.toJson(), 'resource': resource.toJson()})
            else
              entry,
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: resource,
              path: '/workshopRevision',
              before: selection.snapshot.revision,
              after: fingerprint ?? selection.reader.revision),
        ]),
        fingerprint);
  }

  static bool _same(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);

  static Object? _preserveUntouched(
      Object? original, Object? before, Object? after) {
    if (_same(before, after)) return original;
    if (original is Map && before is Map && after is Map) {
      final result = Map<String, Object?>.from(original);
      for (final key in {...before.keys, ...after.keys}) {
        if (!after.containsKey(key)) {
          result.remove(key);
        } else if (!before.containsKey(key)) {
          result[key as String] = after[key];
        } else {
          result[key as String] =
              _preserveUntouched(original[key], before[key], after[key]);
        }
      }
      return result;
    }
    if (original is List && before is List && after is List && original.length == before.length) {
      final byId = <String, int>{};
      if (before.every((value) => value is Map && value['id'] is String) &&
          after.every((value) => value is Map && value['id'] is String)) {
        for (var index = 0; index < before.length; index++) {
          byId[(before[index] as Map)['id'] as String] = index;
        }
        return [for (final value in after)
          if (byId[(value as Map)['id']] case final index?)
            _preserveUntouched(original[index], before[index], value)
          else value];
      }
      final used = <int>{};
      return [for (var position = 0; position < after.length; position++)
        (() {
          var index = -1;
          for (var candidate = 0; candidate < before.length; candidate++) {
            if (!used.contains(candidate) && _same(before[candidate], after[position])) {
              index = candidate; break;
            }
          }
          if (index < 0 && position < before.length && !used.contains(position)) {
            final old = before[position];
            final next = after[position];
            if (before.length == after.length ||
                (old is Map && next is Map && old['speciesId'] != null && old['speciesId'] == next['speciesId'])) {
              index = position;
            }
          }
          if (index < 0) return after[position];
          used.add(index);
          return _preserveUntouched(original[index], before[index], after[position]);
        })()];
    }
    return after;
  }
}
