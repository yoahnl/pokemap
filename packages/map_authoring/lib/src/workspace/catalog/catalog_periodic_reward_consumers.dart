import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../support/authoring_fingerprint.dart';
import '../../contracts/authoring_request.dart';
import '../../transactions/change_set.dart';
import 'catalog_narrative_event_documents.dart';

abstract final class CatalogPeriodicRewardConsumers {
  static CatalogDefinitionKey sourceKey(String sceneId, String nodeId) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['periodicRewardConsumers', sceneId, nodeId]));

  static Future<List<CatalogDefinitionUnit>> maintainAndGuard({
    required CatalogSnapshot snapshot,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
    Iterable<AuthoringResourceChange> additionalChanges = const [],
    AuthoringRequest? request,
  }) async {
    final beforeScenes = <String, SceneAsset>{};
    final afterScenes = <String, SceneAsset>{};
    final affected = <CatalogDefinitionKey>{};
    void collect(Map<String, SceneAsset> scenes, SceneAsset scene) {
      if (scenes.containsKey(scene.id)) {
        throw const CatalogStorageException(
            'catalog.periodic_reward_consumers.ambiguous_scene',
            'The changed Scene identity is ambiguous. Preserve the original definitions and inspect the duplicate.');
      }
      scenes[scene.id] = scene;
    }

    for (final unit in upserts) {
      if (!_isSceneKey(unit.key)) continue;
      affected.add(unit.key);
      final after = _scene(unit);
      if (after != null) {
        collect(afterScenes, after);
      }
    }
    for (final key in removals) {
      if (_isSceneKey(key)) affected.add(key);
    }
    for (final key in affected) {
      final before = _scene(await snapshot.lookup(key));
      if (before != null) collect(beforeScenes, before);
    }
    final ids = {...beforeScenes.keys, ...afterScenes.keys}.toList()..sort();
    final scenes = [
      for (final id in ids) (before: beforeScenes[id], after: afterScenes[id])
    ];
    final facets = <CatalogDefinitionKey, _ConsumerFacet>{};
    Future<_ConsumerFacet> facet(PeriodicRewardReference reference) async {
      final key = sourceKey(reference.sceneId, reference.nodeId);
      final existing = facets[key];
      if (existing != null) return existing;
      final result = _ConsumerFacet(
          reference.sceneId, reference.nodeId, await snapshot.lookup(key));
      facets[key] = result;
      return result;
    }

    for (final change in scenes) {
      final before = _conditions(change.before);
      final after = _conditions(change.after);
      for (final nodeId in {...before.keys, ...after.keys}) {
        final oldReference = before[nodeId];
        final newReference = after[nodeId];
        if (oldReference == newReference &&
            change.before?.id == change.after?.id) {
          continue;
        }
        if (oldReference != null) {
          (await facet(oldReference))
              .remove(_consumer(change.before!.id, nodeId, oldReference));
        }
        if (newReference != null) {
          (await facet(newReference))
              .add(_consumer(change.after!.id, nodeId, newReference));
        }
      }
    }
    final beforeRules = <String, WorldRuleDefinition>{};
    final afterRules = <String, WorldRuleDefinition>{};
    final ruleKeys = <CatalogDefinitionKey>{
      for (final unit in upserts)
        if (_isDefinitionKey(unit.key, 'worldRules')) unit.key,
      for (final key in removals)
        if (_isDefinitionKey(key, 'worldRules')) key,
    };
    for (final key in ruleKeys) {
      final before = _worldRule(await snapshot.lookup(key));
      if (before != null) beforeRules[before.id] = before;
    }
    for (final unit in upserts) {
      final after = _worldRule(unit);
      if (after != null) afterRules[after.id] = after;
    }
    for (final id in {...beforeRules.keys, ...afterRules.keys}) {
      final before = beforeRules[id]?.source.rewardReference;
      final after = afterRules[id]?.source.rewardReference;
      if (before == after) continue;
      Map<String, Object?> consumer(PeriodicRewardReference reference) => {
            'kind': 'worldRule',
            'ruleId': id,
            'rewardId': reference.rewardId,
          };
      if (before != null) (await facet(before)).remove(consumer(before));
      if (after != null) (await facet(after)).add(consumer(after));
    }
    final pending = {for (final unit in upserts) unit.key: unit};
    final removed = removals.toSet();
    Future<CatalogDefinitionUnit?> projected(CatalogDefinitionKey key) async =>
        removed.contains(key)
            ? null
            : pending[key] ?? await snapshot.lookup(key);
    for (final key in {...pending.keys, ...removed}
        .where(CatalogNarrativeEventDocuments.isRecordKey)) {
      final previous = await snapshot.lookup(key);
      final current = await projected(key);
      if (previous?.payload['sha256'] == current?.payload['sha256'] &&
          previous?.payload['deleted'] == current?.payload['deleted']) continue;
      final before = await CatalogNarrativeEventDocuments.readRecordUnit(
          previous, snapshot.lookup);
      final after = await CatalogNarrativeEventDocuments.readRecordUnit(
          current, projected);
      Map<String, PeriodicRewardReference> refs(NarrativeEventRecord? record) =>
          {
            for (final (index, condition)
                in (record?.definitionOrNull?.conditionExpression.leaves ??
                        record?.draftOrNull?.conditionExpression.leaves ??
                        const <NarrativeEventCondition>[])
                    .indexed)
              if (condition.rewardReference
                  case final PeriodicRewardReference reference)
                '$index': reference,
          };
      final old = refs(before);
      final next = refs(after);
      for (final index in {...old.keys, ...next.keys}) {
        final a = old[index];
        final b = next[index];
        if (a == b && before?.id == after?.id) continue;
        Map<String, Object?> consumer(
                String eventId, PeriodicRewardReference reference) =>
            {
              'kind': 'eventCondition',
              'eventId': eventId,
              'conditionIndex': index,
              'rewardId': reference.rewardId
            };
        if (a != null) (await facet(a)).remove(consumer(before!.id, a));
        if (b != null) (await facet(b)).add(consumer(after!.id, b));
      }
    }
    for (final change
        in additionalChanges.where((change) => change.resource.kind == 'map')) {
      Future<MapData?> decode(bool before) async {
        final payload = before ? change.beforePayload : change.afterPayload;
        if (payload == null) return null;
        return MapData.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(await payload.readBytes())) as Map));
      }

      final before = await decode(true);
      final after = await decode(false);
      final target = request?.actionId == 'map3d.instance.visibility.set'
          ? request?.parameters['instanceId'] as String?
          : null;
      Map<String, Map<String, PeriodicRewardReference>> references(
              MapData? map) =>
          {
            for (final instance in map?.spatialScene?.instances ??
                const <SpatialModelInstance>[])
              if (target == null || instance.id == target)
                instance.id: {
                  for (final (index, condition)
                      in (instance.visibilityCondition?.leaves ??
                              const <NarrativeEventCondition>[])
                          .indexed)
                    if (condition.rewardReference
                        case final PeriodicRewardReference reference)
                      '$index': reference,
                },
          };
      final previous = references(before);
      final next = references(after);
      for (final instanceId in {...previous.keys, ...next.keys}) {
        final old =
            previous[instanceId] ?? const <String, PeriodicRewardReference>{};
        final current =
            next[instanceId] ?? const <String, PeriodicRewardReference>{};
        for (final index in {...old.keys, ...current.keys}) {
          final a = old[index];
          final b = current[index];
          if (a == b && before?.id == after?.id) continue;
          Map<String, Object?> consumer(
                  String mapId, PeriodicRewardReference reference) =>
              {
                'kind': 'modelVisibility',
                'mapId': mapId,
                'instanceId': instanceId,
                'conditionIndex': index,
                'rewardId': reference.rewardId,
              };
          if (a != null) (await facet(a)).remove(consumer(before!.id, a));
          if (b != null) (await facet(b)).add(consumer(after!.id, b));
        }
      }
      final entityTarget = request?.actionId == 'entity.set_presentation'
          ? request?.parameters['entityId'] as String?
          : null;
      Map<(String, String, int), PeriodicRewardReference> entityReferences(
              MapData? map) =>
          {
            for (final entity
                in request?.actionId == 'map3d.instance.visibility.set'
                    ? const <MapEntity>[]
                    : map?.entities ?? const <MapEntity>[])
              if (entityTarget == null || entity.id == entityTarget)
                for (final variant in entity.presentation?.variants ??
                    const <MapEntityPresentationVariant>[])
                  for (final (index, leaf) in variant.condition.leaves.indexed)
                    if (leaf.rewardReference
                        case final PeriodicRewardReference reference)
                      (entity.id, variant.id, index): reference,
          };
      final oldEntities = entityReferences(before);
      final newEntities = entityReferences(after);
      for (final key in {...oldEntities.keys, ...newEntities.keys}) {
        final a = oldEntities[key];
        final b = newEntities[key];
        if (a == b && before?.id == after?.id) continue;
        Map<String, Object?> consumer(
                String mapId, PeriodicRewardReference reference) =>
            {
              'kind': 'entityPresentation',
              'mapId': mapId,
              'entityId': key.$1,
              'variantId': key.$2,
              'conditionIndex': '${key.$3}',
              'rewardId': reference.rewardId,
            };
        if (a != null) (await facet(a)).remove(consumer(before!.id, a));
        if (b != null) (await facet(b)).add(consumer(after!.id, b));
      }
    }
    for (final change in scenes) {
      final before = change.before;
      if (before == null) continue;
      final next = _claims(change.after);
      for (final old in _claims(before).entries) {
        if (before.id == change.after?.id && next[old.key] == old.value) {
          continue;
        }
        final source = await facet(PeriodicRewardReference(
            sceneId: before.id, nodeId: old.key, rewardId: old.value));
        if (source.consumers.isNotEmpty) {
          throw const CatalogStorageException(
              'catalog.periodic_reward_reference_in_use',
              'A condition still references this reward action. Change its consumers before removing or replacing the source.');
        }
        if (!source.complete) {
          throw const CatalogStorageException(
              'catalog.periodic_reward_reference_coverage_unknown',
              'Historical reward references have not been inspected. Preserve this action or inspect its consumers explicitly before removing or replacing it.');
        }
      }
    }
    return [
      for (final entry in facets.entries)
        if (entry.value.changed) entry.value.unit(entry.key)
    ];
  }

  static bool _isSceneKey(CatalogDefinitionKey key) =>
      _isDefinitionKey(key, 'scenes');

  static bool _isDefinitionKey(CatalogDefinitionKey key, String field) {
    if (key.kind != CatalogDefinitionKind.catalogMetadata) return false;
    try {
      final parts = jsonDecode(key.id);
      return parts is List &&
          parts.length == 3 &&
          parts[0] == 'projectDefinition' &&
          parts[1] == field &&
          parts[2] is int;
    } on FormatException {
      return false;
    }
  }

  static WorldRuleDefinition? _worldRule(CatalogDefinitionUnit? unit) {
    if (unit == null || !_isDefinitionKey(unit.key, 'worldRules')) return null;
    final value = unit.payload['value'];
    if (value is! Map || value['field'] != 'worldRules') return null;
    return WorldRuleDefinition.fromJson(
        Map<String, dynamic>.from(value['definition'] as Map));
  }

  static SceneAsset? _scene(CatalogDefinitionUnit? unit) {
    if (unit?.key.kind != CatalogDefinitionKind.catalogMetadata ||
        unit?.payload['section'] != r'$projectDefinition') {
      return null;
    }
    final value = unit!.payload['value'];
    if (value is! Map || value['field'] != 'scenes') return null;
    return SceneAsset.fromJson(
        Map<String, dynamic>.from(value['definition'] as Map));
  }

  static Map<String, PeriodicRewardReference> _conditions(SceneAsset? scene) =>
      {
        for (final node in scene?.graph.nodes ?? const <SceneNode>[])
          if (node.payload
              case SceneConditionPayload(
                conditionSource: SceneConditionSource(:final rewardReference?)
              ))
            node.id: rewardReference,
      };

  static Map<String, String> _claims(SceneAsset? scene) => {
        for (final node in scene?.graph.nodes ?? const <SceneNode>[])
          if (node.payload
              case SceneActionPayload(
                interactiveCommand: SceneClaimPeriodicRewardInteractiveCommand(
                  :final definition
                )
              ))
            node.id: definition.rewardId,
      };

  static Map<String, Object?> _consumer(
          String sceneId, String nodeId, PeriodicRewardReference reference) =>
      {
        'kind': 'sceneCondition',
        'sceneId': sceneId,
        'nodeId': nodeId,
        'rewardId': reference.rewardId,
      };
}

final class _ConsumerFacet {
  _ConsumerFacet(this.sceneId, this.nodeId, CatalogDefinitionUnit? existing)
      : complete = existing?.payload['coverage'] == 'complete' {
    if (existing == null) return;
    final raw = existing.payload;
    if (raw['schemaVersion'] != 1 ||
        raw['sceneId'] != sceneId ||
        raw['nodeId'] != nodeId ||
        !const {'unknown', 'complete'}.contains(raw['coverage']) ||
        raw['consumers'] is! List) {
      throw const FormatException('catalog.periodic_reward_consumers.invalid');
    }
    for (final value in raw['consumers'] as List) {
      if (value is! Map ||
          value['kind'] is! String ||
          value['rewardId'] is! String) {
        throw const FormatException(
            'catalog.periodic_reward_consumers.invalid_consumer');
      }
      final consumer = Map<String, Object?>.from(value);
      if (consumers.containsKey(_identity(consumer))) {
        throw const FormatException(
            'catalog.periodic_reward_consumers.duplicate_consumer');
      }
      consumers[_identity(consumer)] = consumer;
    }
  }

  final String sceneId;
  final String nodeId;
  final bool complete;
  final consumers = <String, Map<String, Object?>>{};
  bool changed = false;

  String _identity(Map<String, Object?> consumer) =>
      canonicalAuthoringJson({...consumer}..remove('rewardId'));
  void add(Map<String, Object?> consumer) {
    consumers[_identity(consumer)] = consumer;
    changed = true;
  }

  void remove(Map<String, Object?> consumer) {
    consumers.remove(_identity(consumer));
    changed = true;
  }

  CatalogDefinitionUnit unit(CatalogDefinitionKey key) {
    final identities = consumers.keys.toList()..sort();
    return CatalogDefinitionUnit(key: key, payload: {
      'id': key.id,
      'schemaVersion': 1,
      'sceneId': sceneId,
      'nodeId': nodeId,
      'coverage': complete ? 'complete' : 'unknown',
      'consumers': [for (final id in identities) consumers[id]],
    });
  }
}
