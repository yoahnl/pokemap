import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../ports/project_file_reader.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/change_set.dart';

typedef CatalogNarrativeEventConsumer = ({String kind, String id, String label});

typedef CatalogNarrativeEventConsumerPatch = ({
  List<CatalogDefinitionUnit> upserts,
  List<CatalogDefinitionKey> removals
});

abstract final class CatalogNarrativeEventConsumers {
  static const preparationScope = 'narrativeEventConsumers';

  static final marker = CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, 'narrativeEventConsumerIndex');

  static CatalogDefinitionKey facetKey(String eventId) => CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState,
      jsonEncode(['narrativeEventConsumers', eventId]));

  static Future<bool> prepared(CatalogSnapshot snapshot) async =>
      (await snapshot.lookup(marker))?.payload['schemaVersion'] == 1;

  static Future<List<CatalogNarrativeEventConsumer>?> consumersOf(
      CatalogSnapshot snapshot, String eventId) async {
    if (!await prepared(snapshot)) return null;
    final facet =
        _Facet.read(eventId, await snapshot.lookup(facetKey(eventId)));
    return facet.sorted();
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
        metadataFields: {'maps', 'worldRules'});
    final project = catalog.projectMetadata;
    final facets = <String, _Facet>{};
    _Facet facet(String eventId) =>
        facets.putIfAbsent(eventId, () => _Facet(eventId));
    for (final rule in project.worldRules) {
      for (final eventId in _ruleReferences(rule)) {
        facet(eventId).add(('worldRule', rule.id, rule.label));
      }
    }
    final observed = <String, String?>{};
    for (final entry in project.maps) {
      validateProjectRelativePath(entry.relativePath);
      final payload =
          await store.gateway.captureResourcePayload(entry.relativePath);
      observed[entry.relativePath] = payload?.resourceRevision;
      if (payload == null) {
        throw CatalogStorageException(
            'catalog.narrative_event_consumers.map_missing',
            'The map ${entry.id} is missing, so its behaviour references cannot be proven.');
      }
      final List<int> bytes;
      try {
        bytes = await payload.readBytes();
      } finally {
        await payload.release();
      }
      final owner = _mapReferences(bytes);
      if (owner == null) continue;
      if (owner.id != entry.id) {
        throw const FormatException(
            'catalog.narrative_event_consumers.map_identity');
      }
      for (final eventId in owner.events) {
        facet(eventId).add(('map', owner.id, owner.label));
      }
    }
    for (final entry in observed.entries) {
      if (await store.gateway.readResourceRevision(entry.key) != entry.value) {
        throw const CatalogStorageException(
            'catalog.narrative_event_consumers.changed_during_preparation',
            'A map changed while its behaviour references were being prepared.');
      }
    }
    String fingerprint(Object? root, Map<String, String?> resources) =>
        computeAuthoringJsonFingerprint(
            {'catalog': root, 'resources': resources},
            logicalName: 'narrative-event-consumers');
    return (
      units: [
        CatalogDefinitionUnit(
            key: marker, payload: {'id': marker.id, 'schemaVersion': 1}),
        for (final entry in facets.entries)
          if (entry.value.consumers.isNotEmpty)
            entry.value.unit(),
      ],
      revision: fingerprint(snapshot.root.toJson(), observed),
      currentRevision: () async => fingerprint(
          (await store.readHead())?.toJson(), {
        for (final path in observed.keys)
          path: await store.gateway.readResourceRevision(path)
      }),
    );
  }

  static Future<CatalogNarrativeEventConsumerPatch> maintain({
    required CatalogSnapshot snapshot,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
    required Iterable<AuthoringResourceChange> additionalChanges,
  }) async {
    const none = (
      upserts: <CatalogDefinitionUnit>[],
      removals: <CatalogDefinitionKey>[]
    );
    final ruleKeys = <CatalogDefinitionKey>{
      for (final unit in upserts)
        if (_isRuleKey(unit.key)) unit.key,
      for (final key in removals)
        if (_isRuleKey(key)) key,
    };
    final mapChanges = [
      for (final change in additionalChanges)
        if (change.resource.kind == 'map') change
    ];
    if (ruleKeys.isEmpty && mapChanges.isEmpty) return none;
    if (!await prepared(snapshot)) return none;
    final before = <(String, String), _Owner>{};
    final after = <(String, String), _Owner>{};
    for (final key in ruleKeys) {
      final rule = _rule(await snapshot.lookup(key));
      if (rule != null) before[('worldRule', rule.id)] = _ruleOwner(rule);
    }
    for (final unit in upserts) {
      if (!_isRuleKey(unit.key)) continue;
      final rule = _rule(unit);
      if (rule != null) after[('worldRule', rule.id)] = _ruleOwner(rule);
    }
    for (final change in mapChanges) {
      for (final (images, payload) in [
        (before, change.beforePayload),
        (after, change.afterPayload)
      ]) {
        if (payload == null) continue;
        final owner = _mapReferences(await payload.readBytes());
        if (owner != null) images[('map', owner.id)] = owner;
      }
    }
    final facets = <String, _Facet>{};
    Future<_Facet> facet(String eventId) async =>
        facets[eventId] ??= _Facet.read(
            eventId, await snapshot.lookup(facetKey(eventId)));
    final owners = {...before.keys, ...after.keys};
    for (final owner in owners) {
      final previous = before[owner];
      final next = after[owner];
      if (previous != null &&
          next != null &&
          previous.label == next.label &&
          _sameSet(previous.events, next.events)) {
        continue;
      }
      for (final eventId in previous?.events ?? const <String>{}) {
        (await facet(eventId)).remove(owner.$1, owner.$2);
      }
    }
    for (final owner in owners) {
      final previous = before[owner];
      final next = after[owner];
      if (next == null ||
          (previous != null &&
              previous.label == next.label &&
              _sameSet(previous.events, next.events))) {
        continue;
      }
      for (final eventId in next.events) {
        (await facet(eventId)).add((owner.$1, owner.$2, next.label));
      }
    }
    final result = (
      upserts: <CatalogDefinitionUnit>[],
      removals: <CatalogDefinitionKey>[]
    );
    for (final facet in facets.values) {
      if (!facet.changed) continue;
      if (facet.consumers.isNotEmpty) {
        result.upserts.add(facet.unit());
      } else if (facet.existed) {
        result.removals.add(facetKey(facet.eventId));
      }
    }
    return result;
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  static bool _isRuleKey(CatalogDefinitionKey key) {
    if (key.kind != CatalogDefinitionKind.catalogMetadata) return false;
    try {
      final parts = jsonDecode(key.id);
      return parts is List &&
          parts.length == 3 &&
          parts[0] == 'projectDefinition' &&
          parts[1] == 'worldRules' &&
          parts[2] is int;
    } on FormatException {
      return false;
    }
  }

  static WorldRuleDefinition? _rule(CatalogDefinitionUnit? unit) {
    final value = unit?.payload['value'];
    if (value is! Map || value['field'] != 'worldRules') return null;
    return WorldRuleDefinition.fromJson(
        Map<String, dynamic>.from(value['definition'] as Map));
  }

  static _Owner _ruleOwner(WorldRuleDefinition rule) =>
      _Owner(rule.id, rule.label, _ruleReferences(rule));

  static Set<String> _ruleReferences(WorldRuleDefinition rule) => {
        if (rule.target.kind == WorldRuleTargetKind.narrativeEvent &&
            rule.target.eventId != null)
          rule.target.eventId!,
        if (rule.source.kind == WorldRuleSourceKind.consumedEvent)
          rule.source.sourceId,
      };

  static final _conditionToken = utf8.encode('narrativeEventConsumed');

  static _Owner? _mapReferences(List<int> bytes) {
    if (!_contains(bytes, _conditionToken)) return null;
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map || value['id'] is! String) {
      throw const FormatException('catalog.narrative_event_consumers.map_invalid');
    }
    final events = <String>{};
    final pending = <Object?>[value];
    while (pending.isNotEmpty) {
      final node = pending.removeLast();
      if (node is Map) {
        if (node['kind'] == 'narrativeEventConsumed' &&
            node['eventId'] is String) {
          events.add(node['eventId'] as String);
        }
        pending.addAll(node.values);
      } else if (node is List) {
        pending.addAll(node);
      }
    }
    if (events.isEmpty) return null;
    final id = value['id'] as String;
    final name = value['name'];
    return _Owner(id, name is String && name.isNotEmpty ? name : id, events);
  }

  static bool _contains(List<int> bytes, List<int> token) {
    final first = token.first;
    final last = bytes.length - token.length;
    for (var i = 0; i <= last; i++) {
      if (bytes[i] != first) continue;
      var j = 1;
      while (j < token.length && bytes[i + j] == token[j]) {
        j++;
      }
      if (j == token.length) return true;
    }
    return false;
  }
}

final class _Owner {
  _Owner(this.id, this.label, this.events);
  final String id;
  final String label;
  final Set<String> events;
}

final class _Facet {
  _Facet(this.eventId) : existed = false;

  _Facet.read(this.eventId, CatalogDefinitionUnit? unit)
      : existed = unit != null {
    if (unit == null) return;
    final payload = unit.payload;
    final values = payload['consumers'];
    if (payload['schemaVersion'] != 1 ||
        payload['eventId'] != eventId ||
        values is! List) {
      throw const FormatException('catalog.narrative_event_consumers.invalid');
    }
    for (final value in values) {
      if (value is! Map ||
          value['kind'] is! String ||
          value['id'] is! String ||
          value['label'] is! String) {
        throw const FormatException(
            'catalog.narrative_event_consumers.invalid_consumer');
      }
      final consumer = (
        kind: value['kind'] as String,
        id: value['id'] as String,
        label: value['label'] as String
      );
      if (consumers.containsKey((consumer.kind, consumer.id))) {
        throw const FormatException(
            'catalog.narrative_event_consumers.duplicate_consumer');
      }
      consumers[(consumer.kind, consumer.id)] = consumer;
    }
  }

  final String eventId;
  final bool existed;
  final consumers = <(String, String), CatalogNarrativeEventConsumer>{};
  bool changed = false;

  void add((String, String, String) consumer) {
    consumers[(consumer.$1, consumer.$2)] =
        (kind: consumer.$1, id: consumer.$2, label: consumer.$3);
    changed = true;
  }

  void remove(String kind, String id) {
    consumers.remove((kind, id));
    changed = true;
  }

  List<CatalogNarrativeEventConsumer> sorted() => consumers.values.toList()
    ..sort((a, b) => a.kind == b.kind
        ? a.id.compareTo(b.id)
        : a.kind.compareTo(b.kind));

  CatalogDefinitionUnit unit() {
    final key = CatalogNarrativeEventConsumers.facetKey(eventId);
    return CatalogDefinitionUnit(key: key, payload: {
      'id': key.id,
      'schemaVersion': 1,
      'eventId': eventId,
      'consumers': [
        for (final consumer in sorted())
          {'kind': consumer.kind, 'id': consumer.id, 'label': consumer.label}
      ],
    });
  }
}
