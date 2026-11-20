import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/project_border_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'border_profile_loading_fixture.dart';

const _borderId = 'cliff_target';

void main() {
  test(
    'draft and publish remain local with unrelated profiles present',
    () async {
      final costs = <int, List<int>>{};
      for (final unrelated in [0, 120]) {
        final fixture = await _fixture(unrelated);
        try {
          final port = fixture.resources as ProjectBorderWorkshopPort;
          final blocked = fixture.blockedWorkshopFiles();
          final before = await port.readWorkshopBorder(_borderId);
          final original = before.project.borderCatalog.recordById(_borderId)!;
          final placed = File('${fixture.root.path}/maps/jardin.json');
          final bytes = await placed.readAsBytes();
          var revision = before.revision;
          final writes = <int>[];
          for (final name in ['Clôture ajustée', 'Clôture du jardin']) {
            writes.add(
              await fixture.guarded(blocked, () async {
                final receipt = await port.saveBorderDraft(
                  _borderId,
                  draft: _change(original, name),
                  expectedRevision: revision,
                );
                expect(receipt.actionId, 'border.blueprint.draft.upsert');
                expect(receipt.changedPaths, ['catalog/HEAD.json']);
                expect(receipt.changedMaps, isEmpty);
                revision = receipt.revision;
              }),
            );
          }
          final saved = await port.readWorkshopBorder(_borderId);
          final savedRecord = saved.project.borderCatalog.recordById(
            _borderId,
          )!;
          expect(saved.revision, revision);
          expect(savedRecord.draft, _change(original, 'Clôture du jardin'));
          expect(savedRecord.latestPublished, original.latestPublished);
          expect(await placed.readAsBytes(), bytes);
          await expectLater(
            port.saveBorderDraft(
              _borderId,
              draft: _change(original, 'Révision périmée'),
              expectedRevision: before.revision,
            ),
            throwsA(isA<ResourceFailure>()),
          );
          await fixture.reopen();
          final reopened = fixture.resources as ProjectBorderWorkshopPort;
          final afterReopen = await reopened.readWorkshopBorder(_borderId);
          expect(afterReopen.revision, revision);
          expect(afterReopen.project.borderCatalog.records.single, savedRecord);
          final publishReads = await fixture.guarded(blocked, () async {
            final receipt = await reopened.publishBorderDraft(
              _borderId,
              expectedRevision: afterReopen.revision,
            );
            expect(receipt.actionId, 'border.blueprint.publish');
            expect(receipt.changedPaths, ['catalog/HEAD.json']);
            expect(receipt.changedMaps, isEmpty);
          });
          final published = (await reopened.readWorkshopBorder(_borderId))
              .project
              .borderCatalog
              .records
              .single;
          expect(published.latestPublished?.revision, 2);
          expect(
            published.latestPublished?.definition.name,
            'Clôture du jardin',
          );
          expect(
            published
                .latestPublished
                ?.definition
                .primitives
                .first
                .blocksMovement,
            isFalse,
          );
          expect(await placed.readAsBytes(), bytes);
          costs[unrelated] = [...writes, publishReads];
        } finally {
          await fixture.dispose();
        }
      }
      printOnFailure('$costs');
      expect(costs[120], costs[0]);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('a partial receipt can be reconciled without another write', () async {
    final fixture = await _fixture(15);
    addTearDown(fixture.dispose);
    final resources = LocalResourceAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
      beforeReconciliation: () async =>
          throw const ResourceFailure('Relecture interrompue'),
    );
    addTearDown(resources.dispose);
    final port = resources as ProjectBorderWorkshopPort;
    final before = await port.readWorkshopBorder(_borderId);
    final original = before.project.borderCatalog.records.single;
    final draft = _change(original, 'Brouillon enregistré');
    late ResourceMutationReceipt receipt;
    try {
      await port.saveBorderDraft(
        _borderId,
        draft: draft,
        expectedRevision: before.revision,
      );
      fail('Expected a partial receipt after the interrupted read');
    } on ResourceFailure catch (error) {
      receipt = error.partialReceipt!;
    }
    final head = File('${fixture.root.path}/catalog/HEAD.json');
    final savedHead = await head.readAsBytes();
    await fixture.guarded(
      fixture.blockedWorkshopFiles(),
      () => port.reconcileBorderWorkshop(_borderId, receipt),
    );
    expect(await head.readAsBytes(), savedHead);
    final current = await port.readWorkshopBorder(_borderId);
    expect(current.revision, receipt.revision);
    expect(current.project.borderCatalog.records.single.draft, draft);
    expect(
      current.project.borderCatalog.records.single.latestPublished,
      original.latestPublished,
    );
  });

  test(
    'publication refreshes the loaded profile without replacing the map draft',
    () async {
      final fixture = await _fixture(0);
      addTearDown(fixture.dispose);
      final workspace = fixture.workspace;
      final entry = workspace.project!.maps.singleWhere(
        (map) => map.id == 'jardin',
      );
      final other = workspace.project!.maps.singleWhere(
        (map) => map.id == 'clairiere',
      );
      await workspace.activate(other);
      final unrelatedDocument = workspace.active!;
      expect(
        unrelatedDocument.current.layers.whereType<BorderLayer>(),
        isEmpty,
      );
      expect(
        unrelatedDocument.current.spatialScene!.instances.single.modelId,
        'piece_target_a',
      );
      await workspace.activate(entry);
      await workspace.ensureBorderBlueprint(_borderId);
      final document = workspace.active!;
      document.commit(
        document.current.copyWith(properties: {'local-edit': true}),
      );
      final pendingMap = document.current;
      final beforeVisual = workspace.visualProject!;
      final visualBuilds = workspace.visualProjectionBuilds;
      expect(
        beforeVisual.borderCatalog
            .recordById(_borderId)
            ?.latestPublished
            ?.revision,
        1,
      );
      final port = fixture.resources as ProjectBorderWorkshopPort;
      final read = await port.readWorkshopBorder(_borderId);
      final original = read.project.borderCatalog.records.single;
      final blocked = fixture.blockedWorkshopFiles();
      await fixture.guarded(blocked, () async {
        final draft = await port.saveBorderDraft(
          _borderId,
          draft: _change(original, 'Brouillon à publier'),
          expectedRevision: read.revision,
        );
        workspace.acceptResources(draft.before, draft.manifest);
        expect(
          workspace.visualProject!.borderCatalog
              .recordById(_borderId)
              ?.latestPublished,
          original.latestPublished,
        );

        final publication = await port.publishBorderDraft(
          _borderId,
          expectedRevision: draft.revision,
        );
        final changed = publication.manifest.borderCatalog.recordById(
          _borderId,
        )!;
        workspace.acceptResources(
          publication.before,
          publication.manifest,
          changedBorder: changed,
        );
        expect(
          workspace.visualProject!.borderCatalog.recordById(_borderId),
          changed,
        );
        expect(workspace.visualProjectionBuilds, visualBuilds);
        expect(workspace.borderWorkshopSelectionsVisited, 1);
        expect(workspace.active, same(document));
        expect(document.current, same(pendingMap));
        expect(document.dirty, isTrue);
      });
      await fixture.maps.loadMapSelection(fixture.session, entry);
      final baseline = await fixture.maps.resourceBaseline(fixture.session);
      expect(
        baseline.manifest.borderCatalog
            .recordById(_borderId)
            ?.latestPublished
            ?.revision,
        2,
      );
      expect(workspace.documents[other.id], same(unrelatedDocument));
    },
  );

  test(
    'a later catalogue revision requires reopening before recovery',
    () async {
      final fixture = await _fixture(0);
      addTearDown(fixture.dispose);
      final interrupted = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        beforeReconciliation: () async =>
            throw const ResourceFailure('Coupure'),
      );
      addTearDown(interrupted.dispose);
      final read = await interrupted.readWorkshopBorder(_borderId);
      late ResourceMutationReceipt partial;
      try {
        await interrupted.saveBorderDraft(
          _borderId,
          draft: _change(
            read.project.borderCatalog.records.single,
            'Première écriture',
          ),
          expectedRevision: read.revision,
        );
        fail('Expected the interrupted read');
      } on ResourceFailure catch (error) {
        partial = error.partialReceipt!;
      }

      final freshMaps = LocalMapWorkspaceAdapter();
      await freshMaps.loadCatalog(fixture.session);
      final other = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: freshMaps,
      );
      addTearDown(other.dispose);
      final newer = await other.readWorkshopBorder(_borderId);
      await other.saveBorderDraft(
        _borderId,
        draft: _change(
          newer.project.borderCatalog.records.single,
          'Écriture plus récente',
        ),
        expectedRevision: newer.revision,
      );
      await expectLater(
        interrupted.reconcileBorderWorkshop(_borderId, partial),
        throwsA(isA<BorderWorkshopReopenRequired>()),
      );
    },
  );
}

Future<BorderFixture> _fixture(int unrelated) async {
  final parent = await Directory(
    '/Users/karim/Library/Caches/AveluneQA/border-workshop-8b',
  ).create(recursive: true);
  final result = await BorderFixture.create(
    unrelated: unrelated,
    parent: parent,
    placeBorder: true,
  );
  await result.openWorkspace();
  return result;
}

BorderBlueprintDraft _change(BorderBlueprintRecord record, String name) {
  const version = ProjectBorderCatalog.latestSupportedFormatVersion;
  final encoded = encodeBorderBlueprintRecordJson(
    record,
    formatVersion: version,
  );
  final draft = Map<String, Object?>.from(encoded['draft'] as Map);
  final definition = Map<String, Object?>.from(draft['definition'] as Map);
  final primitives = List.of(definition['primitives'] as List);
  primitives[0] = {
    ...Map<String, Object?>.from(primitives.first as Map),
    'weight': 12,
    'blocksMovement': false,
  };
  return decodeBorderBlueprintRecordJson({
    'id': record.id,
    'draft': {
      ...draft,
      'definition': {...definition, 'name': name, 'primitives': primitives},
    },
  }, formatVersion: version).draft;
}
