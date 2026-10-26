import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/catalog_storage/catalog_history_compatibility.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'manifest rejects unsupported versions, self mappings and unsafe charges',
      () {
    final source = CatalogObjectReference(sha256: 'a' * 64, byteLength: 1);
    final target = CatalogObjectReference(sha256: 'b' * 64, byteLength: 1);
    for (final bytes in [-1, 0, 1073741825, 9223372036854775807]) {
      expect(
          () => CatalogHistoryRootConversion(
              source: source, target: target, additionalBytes: bytes),
          throwsFormatException);
    }
    expect(
        () => CatalogHistoryRootConversion(
            source: source, target: source, additionalBytes: 1),
        throwsFormatException);
    expect(
        () => CatalogHistoryRootConversion(
            source: source,
            target: target,
            additionalBytes: 1,
            normalizationVersion: 2),
        throwsFormatException);
  });

  for (final profile in [(0, true), (1, false), (1, true), (2, true)]) {
    test('converts exact events ${profile.$1} and legacy facts ${profile.$2}',
        () async {
      final fixture = await _Fixture.open(
          eventsVersion: profile.$1, legacyFacts: profile.$2);
      addTearDown(fixture.close);
      final original = fixture.snapshot.root;
      final sourceUnits = await fixture.snapshot.readAllUnits();
      final prepared = await fixture.prepare();
      expect(prepared, isNotNull);
      final conversion = prepared!.conversion;
      expect(conversion.source, original);
      expect(conversion.target, prepared.targetSnapshot.root);
      expect(
          conversion.additionalBytes,
          prepared.objects.values
              .fold<int>(0, (sum, bytes) => sum + bytes.length));
      expect(
          CatalogHistoryRootConversion.fromJson(conversion.toJson()).toJson(),
          conversion.toJson());
      expect(await fixture.store.readHead(), original);
      await expectLater(fixture.store.requireHistoryConversion(conversion),
          throwsA(_preparationRequired));
      await fixture.store.gateway.withExclusiveWriteLock(
          () => prepared.publishUnderLock(fixture.store));
      await fixture.store.requireHistoryConversion(conversion);
      expect(await fixture.store.readHead(), original);
      expect(
          await fixture.store.metadataIndexPrepared(fixture.snapshot), isFalse);
      expect(await fixture.store.metadataIndexPrepared(prepared.targetSnapshot),
          isTrue);
      for (final unit in sourceUnits.where(
          (unit) => unit.key.kind != CatalogDefinitionKind.workspaceState)) {
        expect((await prepared.targetSnapshot.indexEntry(unit.key))!.reference,
            (await fixture.snapshot.indexEntry(unit.key))!.reference);
      }
      final selected = await CatalogNarrativeEventDocuments.read(
          prepared.targetSnapshot, {_eventId});
      expect(selected!.records.single.toJson(), _record.toJson());
      expect(
          await CatalogMetadataDocuments.readFactIdsForRuntimeIdentity(
              snapshot: prepared.targetSnapshot,
              runtimeIdentity: 'legacy-alias'),
          {'fact'});
      final freshAuthority = await CatalogStorageStore.open(
          projectRoot: fixture.project.path,
          trustedAdmissionDirectory: Directory('${fixture.base.path}/fresh'));
      await expectLater(freshAuthority.requireHistoryConversion(conversion),
          throwsA(_preparationRequired));
      final wrongLimits = await CatalogStorageStore.open(
          projectRoot: fixture.project.path,
          trustedAdmissionDirectory: fixture.admissions,
          limits: CatalogStorageLimits(maxDefinitions: 99999));
      await expectLater(wrongLimits.requireHistoryConversion(conversion),
          throwsA(_preparationRequired));
      await expectLater(
          fixture.store.requireHistoryConversion(CatalogHistoryRootConversion(
              source: conversion.source,
              target: conversion.target,
              additionalBytes: conversion.additionalBytes + 1)),
          throwsA(_preparationRequired));
    });
  }

  test('current metadata requires no conversion or publication', () async {
    final fixture = await _Fixture.open(eventsVersion: 2, legacyFacts: false);
    addTearDown(fixture.close);
    expect(await fixture.prepare(), isNull);
    expect(
        await fixture.store.metadataIndexPrepared(fixture.snapshot), isFalse);
  });

  test('forged extra facet and altered v1 records never receive a conversion',
      () async {
    for (final defect in ['extra-facet', 'altered-record']) {
      final fixture = await _Fixture.open(
          eventsVersion: 1, legacyFacts: false, defect: defect);
      addTearDown(fixture.close);
      final objects = await Directory('${fixture.project.path}/catalog/objects')
          .list()
          .map((file) => file.path)
          .toList();
      expect(await fixture.prepare(), isNull);
      expect(
          await Directory('${fixture.project.path}/catalog/objects')
              .list()
              .map((file) => file.path)
              .toList(),
          unorderedEquals(objects));
      expect(
          await fixture.store.metadataIndexPrepared(fixture.snapshot), isFalse);
    }
  });

  test('metadata evidence must be complete and bound to the admitted source',
      () async {
    final fixture = await _Fixture.open(eventsVersion: 0, legacyFacts: true);
    addTearDown(fixture.close);
    for (final supplied in [
      fixture.metadata.skip(1).toList(),
      [
        CatalogDefinitionUnit(
            key: fixture.metadata.first.key,
            payload: {...fixture.metadata.first.payload, 'forged': true}),
        ...fixture.metadata.skip(1),
      ],
      [...fixture.metadata, fixture.metadata.first],
    ]) {
      await expectLater(
          CatalogHistoryCompatibility.prepare(
              store: fixture.store,
              source: fixture.snapshot,
              metadataUnits: supplied),
          throwsFormatException);
    }
    final unadmitted =
        (await fixture.store.openRoot(fixture.snapshot.root)).snapshot;
    await expectLater(
        CatalogHistoryCompatibility.prepare(
            store: fixture.store,
            source: unadmitted,
            metadataUnits: fixture.metadata),
        throwsA(_preparationRequired));
  });

  test('conversion publication rejects a different store owner', () async {
    final fixture = await _Fixture.open(eventsVersion: 0, legacyFacts: true);
    addTearDown(fixture.close);
    final prepared = (await fixture.prepare())!;
    final other = await CatalogStorageStore.open(
        projectRoot: fixture.project.path,
        trustedAdmissionDirectory: fixture.admissions);
    await expectLater(
        prepared.publishUnderLock(other),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.history_conversion_owner')));
    await expectLater(
        fixture.store.requireHistoryConversion(prepared.conversion),
        throwsA(_preparationRequired));
  });

  test(
      'explicit recovery reconstructs an exact conversion in a fresh authority',
      () async {
    final fixture = await _Fixture.open(eventsVersion: 0, legacyFacts: true);
    addTearDown(fixture.close);
    final conversion = (await fixture.prepare())!.conversion;
    final authority = await CatalogStorageStore.open(
        projectRoot: fixture.project.path,
        trustedAdmissionDirectory: Directory('${fixture.base.path}/recovery'));
    await expectLater(authority.requireHistoryConversion(conversion),
        throwsA(_preparationRequired));
    final originalHead = await authority.readHead();
    await authority.gateway.withExclusiveWriteLock(() =>
        CatalogHistoryCompatibility.recover(
            store: authority, conversion: conversion));
    await authority.requireHistoryConversion(conversion);
    final source = (await authority.openRoot(conversion.source)).snapshot;
    final target = (await authority.openRoot(conversion.target)).snapshot;
    await authority.restoreIndexAdmission(source);
    await authority.restoreIndexAdmission(target);
    expect(await authority.metadataIndexPrepared(source), isFalse);
    expect(await authority.metadataIndexPrepared(target), isTrue);
    expect(await authority.readHead(), originalHead);
    expect(await CatalogNarrativeEventDocuments.read(target, {_eventId}),
        isNotNull);
    expect(await authority.gateway.listJournals(), isEmpty);
    expect(
        await File('${fixture.project.path}/.pokemap/authoring/history.jsonl')
            .exists(),
        isFalse);
  });

  test('explicit recovery rejects a false target or charge before publication',
      () async {
    final fixture = await _Fixture.open(eventsVersion: 0, legacyFacts: true);
    addTearDown(fixture.close);
    final conversion = (await fixture.prepare())!.conversion;
    final admissions = Directory('${fixture.base.path}/recovery');
    final authority = await CatalogStorageStore.open(
        projectRoot: fixture.project.path,
        trustedAdmissionDirectory: admissions);
    final objects = await Directory('${fixture.project.path}/catalog/objects')
        .list()
        .map((file) => file.path)
        .toList();
    for (final invalid in [
      CatalogHistoryRootConversion(
          source: conversion.source,
          target: CatalogObjectReference(sha256: 'a' * 64, byteLength: 1),
          additionalBytes: conversion.additionalBytes),
      CatalogHistoryRootConversion(
          source: conversion.source,
          target: conversion.target,
          additionalBytes: conversion.additionalBytes + 1),
    ]) {
      await expectLater(
          authority.gateway.withExclusiveWriteLock(() =>
              CatalogHistoryCompatibility.recover(
                  store: authority, conversion: invalid)),
          throwsFormatException);
    }
    expect(
        await Directory('${fixture.project.path}/catalog/objects')
            .list()
            .map((file) => file.path)
            .toList(),
        unorderedEquals(objects));
    expect(await admissions.list().toList(), isEmpty);
    expect(await authority.readHead(), fixture.snapshot.root);
    expect(await authority.gateway.listJournals(), isEmpty);
  });

  test('tampered private conversion record is rejected', () async {
    final fixture = await _Fixture.open(eventsVersion: 0, legacyFacts: true);
    addTearDown(fixture.close);
    final prepared = (await fixture.prepare())!;
    await fixture.store.gateway
        .withExclusiveWriteLock(() => prepared.publishUnderLock(fixture.store));
    final certificates = await fixture.admissions
        .list()
        .where((file) => file is File)
        .cast<File>()
        .toList();
    final record = certificates.singleWhere((file) =>
        (jsonDecode(file.readAsStringSync()) as Map)
            .containsKey('historyConversion'));
    await record.writeAsString('{}', flush: true);
    await expectLater(
        fixture.store.requireHistoryConversion(prepared.conversion),
        throwsFormatException);
    await expectLater(
        fixture.store.gateway.withExclusiveWriteLock(() =>
            CatalogHistoryCompatibility.recover(
                store: fixture.store, conversion: prepared.conversion)),
        throwsFormatException);
    expect(await record.readAsString(), '{}');
  });
}

final _preparationRequired = isA<CatalogStorageException>()
    .having((error) => error.code, 'code', 'catalog.preparation_required');
const _eventId = 'evt_018f0f8c-7b8a-7def-8000-000000000001';
final _record = NarrativeEventRecord.draft(NarrativeEventDraft(
    id: _eventId,
    name: 'Historical event',
    conditions: const [],
    priority: 0,
    order: 0));

final class _Fixture {
  _Fixture(this.base, this.project, this.admissions, this.store, this.snapshot,
      this.metadata);
  final Directory base;
  final Directory project;
  final Directory admissions;
  final CatalogStorageStore store;
  final CatalogSnapshot snapshot;
  final List<CatalogDefinitionUnit> metadata;

  static Future<_Fixture> open(
      {required int eventsVersion,
      required bool legacyFacts,
      String? defect}) async {
    final task = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle');
    await task.create(recursive: true);
    final base = await task.createTemp('history-compatibility-');
    final project = await Directory('${base.path}/project').create();
    final admissions = Directory('${base.path}/admissions');
    final store = await CatalogStorageStore.open(
        projectRoot: project.path, trustedAdmissionDirectory: admissions);
    final build = PortableCatalogPublication.encodeProject(ProjectManifest(
        name: 'Compatibility',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
              id: 'fact', label: 'Fact', legacyFlagName: 'legacy-alias')
        ],
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [_record],
            legacyClaims: const [])));
    final source = CatalogSnapshot.readAllSync(
            root: build.storage.root,
            readObject: (reference) => build.storage.objects[reference.sha256]!)
        .units;
    final derived = CatalogMetadataDocuments.initialize(source);
    final legacy = <CatalogDefinitionUnit>[];
    for (final unit in derived) {
      if (legacyFacts && unit.key.id.startsWith('["factRuntimeIdentity",')) {
        continue;
      }
      if (legacyFacts &&
          unit.key == CatalogMetadataDocuments.fieldKey('facts')) {
        legacy.add(CatalogDefinitionUnit(
            key: unit.key,
            payload: {...unit.payload}
              ..remove('factRuntimeIdentitiesVersion')));
      } else if (eventsVersion != 2 &&
          (unit.key == CatalogNarrativeEventDocuments.indexKey ||
              unit.key.id.startsWith('["narrativeEventDocument",') ||
              unit.key.id.startsWith('["narrativeEventDocumentChunk",'))) {
        if (eventsVersion == 1 &&
            unit.key == CatalogNarrativeEventDocuments.indexKey) {
          legacy.add(CatalogDefinitionUnit(
              key: unit.key, payload: {...unit.payload, 'indexVersion': 1}));
        }
      } else {
        legacy.add(unit);
      }
    }
    if (eventsVersion == 1) {
      final key = CatalogNarrativeEventDocuments.recordKey(_eventId);
      legacy.add(CatalogDefinitionUnit(key: key, payload: {
        'id': key.id,
        'eventId': _eventId,
        'record': defect == 'altered-record'
            ? NarrativeEventRecord.draft(NarrativeEventDraft(
                    id: _eventId,
                    name: 'Forged',
                    conditions: const [],
                    priority: 0,
                    order: 0))
                .toJson()
            : _record.toJson(),
      }));
    }
    if (defect == 'extra-facet') {
      legacy.add(CatalogDefinitionUnit(
          key: CatalogMetadataDocuments.trainerItemKey('forged'),
          payload: {
            'schemaVersion': 1,
            'trainerIds': ['forged']
          }));
    }
    await store.publish(
        CatalogStorageBuilder(limits: store.limits).build([
          ...source.where(
              (unit) => unit.key.kind != CatalogDefinitionKind.workspaceState),
          ...legacy,
        ]),
        expectedRootRevision: null);
    final snapshot = (await store.openRoot((await store.readHead())!)).snapshot;
    final metadata = <CatalogDefinitionUnit>[];
    await snapshot.objectReferences(onUnit: (unit) {
      if (unit.key.kind == CatalogDefinitionKind.catalogMetadata ||
          unit.key.kind == CatalogDefinitionKind.workspaceState) {
        metadata.add(unit);
      }
    });
    return _Fixture(base, project, admissions, store, snapshot, metadata);
  }

  Future<CatalogPreparedHistoryConversion?> prepare() =>
      CatalogHistoryCompatibility.prepare(
          store: store, source: snapshot, metadataUnits: metadata);
  Future<void> close() => base.delete(recursive: true);
}
