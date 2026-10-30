import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Scene owner facets follow relocation and deletion without stale owners',
      () async {
    final first = _source(
        _registry([_record(1, sceneId: 'a'), _record(2, sceneId: 'b')]));
    final before = {
      for (final unit in [
        ...first,
        ...CatalogNarrativeEventDocuments.initialize(first)
      ])
        unit.key: unit
    };
    final after = _source(
        _registry([_record(1, sceneId: 'b'), _record(3, sceneId: 'b')]));
    final afterKeys = after.map((unit) => unit.key).toSet();
    final removals = first
        .map((unit) => unit.key)
        .where((key) => !afterKeys.contains(key))
        .toList();
    final delta = await CatalogNarrativeEventDocuments.maintain(
        lookup: (key) async => before[key], upserts: after, removals: removals);
    final next = {...before}..removeWhere((key, _) => removals.contains(key));
    for (final unit in [...after, ...delta]) {
      next[unit.key] = unit;
    }
    final committed = await _snapshot(next.values);
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            committed, '/not-read', {'a'}),
        isEmpty);
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            committed, '/not-read', {'b'}),
        {_id(1), _id(3)});
    final original = await _snapshot(before.values);
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            original, '/not-read', {'a'}),
        {_id(1)});
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            original, '/not-read', {'b'}),
        {_id(2)});
  });
  test('legacy owner cache rejects changed registry until explicit reopen',
      () async {
    final qa = Directory(
        '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/puzzle-authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('owner-cache-');
    addTearDown(() => root.delete(recursive: true));
    final before =
        await _snapshot(_source(_registry([_record(1, sceneId: 'a')])));
    await CatalogNarrativeEventDocuments.initializeSceneOwners(
        before, root.path);
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            before, root.path, {'a'}),
        {_id(1)});
    final changed =
        await _snapshot(_source(_registry([_record(1, sceneId: 'b')])));
    await expectLater(
        CatalogNarrativeEventDocuments.readSceneOwnerIds(
            changed, root.path, {'a'}),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.scene_owner_cache_stale')));
    await expectLater(
        CatalogNarrativeEventDocuments.readSceneOwnerIds(
            changed, root.path, {'b'}),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.scene_owner_cache_stale')));
    await CatalogNarrativeEventDocuments.initializeSceneOwners(
        changed, root.path);
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            changed, root.path, {'a'}),
        isEmpty);
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            changed, root.path, {'b'}),
        {_id(1)});
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            before, root.path, {'a'}),
        {_id(1)});
    expect(await root.list().toList(), isEmpty);
  });
  for (final count in [2, 400]) {
    test(
        'event document index follows shared registry changes with $count records',
        () async {
      final beforeSource =
          _source(_registry([for (var i = 1; i <= count; i++) _record(i)]));
      final before = {
        for (final unit in beforeSource) unit.key: unit,
        for (final unit
            in CatalogNarrativeEventDocuments.initialize(beforeSource))
          unit.key: unit
      };
      final afterSource = _source(_registry([
        _record(2, name: 'Updated'),
        for (var i = 3; i <= count; i++) _record(i),
        _record(999),
      ]));
      final afterSourceByKey = {for (final unit in afterSource) unit.key: unit};
      final upserts = afterSource
          .where((unit) =>
              jsonEncode(before[unit.key]?.toJson()) !=
              jsonEncode(unit.toJson()))
          .toList();
      final removals = beforeSource
          .map((unit) => unit.key)
          .where((key) => !afterSourceByKey.containsKey(key))
          .toList();
      final indexed = await CatalogNarrativeEventDocuments.maintain(
          lookup: (key) async => before[key],
          upserts: upserts,
          removals: removals);
      final next = {...before}..removeWhere((key, _) => removals.contains(key));
      for (final unit in [...upserts, ...indexed]) {
        next[unit.key] = unit;
      }
      final snapshot = await _snapshot(next.values);
      final selected = await CatalogNarrativeEventDocuments.read(
          snapshot, {_id(1), _id(2), _id(999)});
      expect(selected!.records.map((record) => record.id), [_id(2), _id(999)]);
      expect(selected.records.first.draftOrNull!.name, 'Updated');
    });
  }

  for (final defect in [
    'count',
    'size',
    'base64',
    'placeholder',
    'orphan',
    'identity'
  ]) {
    test(
        'event index initialization and maintenance reject noncanonical $defect aggregates',
        () async {
      final valid = _source(_registry([_record(1)]));
      final before = {
        for (final unit in [
          ...valid,
          ...CatalogNarrativeEventDocuments.initialize(valid)
        ])
          unit.key: unit
      };
      final invalid = _malformedAggregate(defect);
      expect(() => CatalogNarrativeEventDocuments.initialize(invalid),
          throwsFormatException);
      await expectLater(
          CatalogNarrativeEventDocuments.maintain(
              lookup: (key) async => before[key],
              upserts: invalid,
              removals: const []),
          throwsFormatException);
    });
  }

  test(
      'indexed records preserve large valid payloads without a new unit size ceiling',
      () async {
    final record = _record(1, name: 'Event ${'x' * 1100000}');
    final source = _source(_registry([record]));
    final snapshot = await _snapshot(
        [...source, ...CatalogNarrativeEventDocuments.initialize(source)]);
    final selected =
        await CatalogNarrativeEventDocuments.read(snapshot, {_id(1)});
    expect(selected!.records.single, record);
  });

  test('unrelated metadata edits never decode the registry aggregate',
      () async {
    final source =
        _source(_registry([for (var i = 1; i <= 400; i++) _record(i)]));
    final byKey = {for (final unit in source) unit.key: unit};
    final shell =
        source.singleWhere((unit) => unit.key.id == 'publication-shell');
    final changed = CatalogDefinitionUnit(key: shell.key, payload: {
      ...shell.payload,
      'value': <String, Object?>{
        ...Map<String, Object?>.from(shell.payload['value'] as Map),
        'name': 'Renamed'
      },
    });
    final reads = <CatalogDefinitionKey>[];
    final result = await CatalogNarrativeEventDocuments.maintain(
        lookup: (key) async {
          reads.add(key);
          return byKey[key];
        },
        upserts: [changed],
        removals: const []);
    expect(result, isEmpty);
    expect(reads, [shell.key]);
  });

  test(
      'explicit preparation upgrades an admitted metadata index missing event rows',
      () async {
    final root = Directory(
        '${Platform.environment['HOME']}/Library/Caches/AveluneQA/targeted-story-authoring/prepare');
    await root.create(recursive: true);
    addTearDown(() => root.delete(recursive: true));
    final source = _source(_registry([_record(1)]));
    final legacy = CatalogMetadataDocuments.initialize(source).where((unit) =>
        unit.key != CatalogNarrativeEventDocuments.indexKey &&
        !unit.key.id.startsWith('["narrativeEventDocument",'));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await store.publish(CatalogStorageBuilder().build([...source, ...legacy]),
        expectedRootRevision: null);
    final snapshot = (await store.openRoot((await store.readHead())!)).snapshot;
    await snapshot.validate();
    await store.gateway.withExclusiveWriteLock(
        () => store.publishMetadataIndexAdmissionUnderLock(snapshot));
    final session = await CatalogEditingSession.open(
        store: store, projectId: 'old-metadata', actorId: 'editor');
    addTearDown(session.close);
    await store.requireMetadataIndexAdmission(session.snapshot);
    expect(await CatalogNarrativeEventDocuments.prepared(session.snapshot),
        isFalse);
    await session.prepareMetadataDocuments();
    final selected =
        await CatalogNarrativeEventDocuments.read(session.snapshot, {_id(1)});
    expect(selected!.records.single.id, _id(1));
  });

  test('unprepared registry indexes require an explicit preparation', () async {
    final snapshot = await _snapshot(_source(_registry([_record(1)])));
    await expectLater(
        CatalogNarrativeEventDocuments.read(snapshot, {_id(1)}),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.preparation_required')));
  });
}

String _id(int value) =>
    'evt_018f0f8c-7b8a-7def-8000-${value.toString().padLeft(12, '0')}';
NarrativeEventRecord _record(int id, {String? name, String? sceneId}) =>
    NarrativeEventRecord.draft(NarrativeEventDraft(
        id: _id(id),
        name: name ?? 'Event $id',
        sceneId: sceneId,
        conditions: const [],
        priority: 0,
        order: id));
NarrativeEventRegistry _registry(List<NarrativeEventRecord> records) =>
    NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const []);
List<CatalogDefinitionUnit> _source(NarrativeEventRegistry registry) {
  final build = PortableCatalogPublication.encodeProject(ProjectManifest(
      name: 'Events',
      maps: const [],
      tilesets: const [],
      eventRegistry: registry));
  return CatalogSnapshot.readAllSync(
          root: build.storage.root,
          readObject: (reference) => build.storage.objects[reference.sha256]!)
      .units;
}

Future<CatalogSnapshot> _snapshot(Iterable<CatalogDefinitionUnit> units) async {
  final build = CatalogStorageBuilder().build(units);
  return CatalogSnapshot.open(
      root: build.root,
      readObject: (reference) async => build.objects[reference.sha256]!);
}

List<CatalogDefinitionUnit> _malformedAggregate(String defect) {
  final registry =
      _registry([_record(1, name: defect == 'size' ? 'x' * 70000 : 'Event')]);
  final source = _source(registry);
  final shell =
      source.singleWhere((unit) => unit.key.id == 'publication-shell');
  var text = jsonEncode(registry.toJson());
  while (text.length % 3 == 0) {
    text += ' ';
  }
  final bytes = utf8.encode(text);
  final count = defect == 'count' ? 2 : (bytes.length + 65535) ~/ 65536;
  final shellValue = <String, Object?>{
    ...Map<String, Object?>.from(shell.payload['value'] as Map),
    'eventRegistry': defect == 'placeholder' || defect == 'orphan'
        ? registry.toJson()
        : <String, Object?>{}
  };
  CatalogDefinitionKey key(String type, [int? position]) =>
      CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
          jsonEncode([type, 'eventRegistry', if (position != null) position]));
  final headerKey = key('projectAggregateHeader');
  final parts = <List<int>>[];
  if (defect == 'count' || defect == 'size') {
    parts.add(bytes.sublist(0, 10));
    parts.add(bytes.sublist(10));
  } else {
    for (var i = 0; i < count; i++) {
      parts.add(
          bytes.sublist(i * 65536, ((i + 1) * 65536).clamp(0, bytes.length)));
    }
  }
  return [
    for (final unit in source)
      if (unit.key == shell.key)
        CatalogDefinitionUnit(
            key: unit.key, payload: {...unit.payload, 'value': shellValue})
      else if (!unit.key.id.contains('projectAggregate'))
        unit,
    if (defect != 'orphan')
      CatalogDefinitionUnit(key: headerKey, payload: {
        'id': headerKey.id,
        'section': r'$projectAggregateHeader',
        'position': 0,
        'value': <String, Object?>{
          'field': 'eventRegistry',
          'byteLength': bytes.length,
          'chunkCount': count,
          'sha256': crypto.sha256.convert(bytes).toString()
        },
      }),
    for (var i = 0; i < parts.length; i++)
      CatalogDefinitionUnit(key: key('projectAggregateChunk', i), payload: {
        'id': key('projectAggregateChunk', i).id,
        'section': r'$projectAggregateChunk',
        'position': defect == 'identity' ? i + 1 : i,
        'value': <String, Object?>{
          'field': 'eventRegistry',
          'data': defect == 'base64'
              ? base64Encode(parts[i]).replaceAll('=', '%3D')
              : base64Encode(parts[i])
        },
      }),
  ];
}
