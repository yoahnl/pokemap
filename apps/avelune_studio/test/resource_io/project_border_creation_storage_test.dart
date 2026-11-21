import 'dart:io';

import 'package:avelune_studio/features/resources/application/border_workshop_assembly.dart';
import 'package:avelune_studio/features/resources/domain/project_border_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'border_profile_loading_fixture.dart';

const _borderId = 'cliff_target';

void main() {
  test(
    'creates and reopens a new connected line without reading other profiles',
    () async {
      final fixture = await _fixture(120);
      addTearDown(fixture.dispose);
      final map = File('${fixture.root.path}/maps/jardin.json');
      final mapBytes = await map.readAsBytes();
      final port = fixture.resources as ProjectBorderWorkshopPort;
      final previous = await port.readWorkshopBorder(_borderId);
      const request = BorderCreationRequest(
        name: 'Paroi du jardin',
        capModelId: 'piece_target_b',
        straightModelId: 'piece_target_b',
        straightOnly: true,
        publish: false,
      );
      late String id;
      late BorderBlueprintRecord published;
      await fixture.guarded(fixture.blockedWorkshopFiles(), () async {
        await expectLater(
          port.createWorkshopBorder(request, expectedRevision: 'périmée'),
          throwsA(isA<ResourceFailure>()),
        );
        final edit = await port.createWorkshopBorder(
          request,
          expectedRevision: previous.revision,
        );
        id = edit.item.id;
        expect(edit.item.name, request.name);
        expect(edit.item.compatibleDimensions, {ProjectDimension.threeD});
        final receipt = edit.receipt;
        final record = receipt.manifest.borderCatalog.recordById(id)!;
        expect(receipt.actionId, 'border.blueprint.draft.upsert');
        expect(receipt.changedPaths, ['catalog/HEAD.json']);
        expect(receipt.changedMaps, isEmpty);
        expect(record.draft.baseRevision, 0);
        expect(record.latestPublished, isNull);
        expect(
          record.draft.definition.template,
          BorderBlueprintTemplate.connectedLine,
        );
        expect(record.draft.definition.straightOnly, isTrue);
        expect(
          record.draft.definition.primitives.map(
            (piece) => piece.sourceModelId,
          ),
          ['piece_target_b', 'piece_target_b'],
        );
        _expectStraightPreview(
          await port.readWorkshopBorder(id),
          id,
          draft: true,
        );
        final publication = await port.publishBorderDraft(
          id,
          expectedRevision: receipt.revision,
        );
        expect(publication.changedPaths, ['catalog/HEAD.json']);
        expect(publication.changedMaps, isEmpty);
        published = publication.manifest.borderCatalog.recordById(id)!;
        expect(published.latestPublished?.revision, 1);
      });
      expect(await map.readAsBytes(), mapBytes);
      await fixture.reopen();
      final reopened = fixture.resources as ProjectBorderWorkshopPort;
      final after = await reopened.readWorkshopBorder(id);
      expect(after.project.borderCatalog.recordById(id), published);
      _expectStraightPreview(after, id, draft: false);
      expect(
        (await reopened.readWorkshopBorder(_borderId))
            .project
            .borderCatalog
            .records,
        previous.project.borderCatalog.records,
      );
      final catalog = await WorkingProjectCatalog.open(
        store: await CatalogStorageStore.open(projectRoot: fixture.root.path),
        descriptor: WorkingProjectCatalogDescriptor(
          projectId: 'studio-border-profiles-test',
        ),
      );
      final full = await catalog.exportProject();
      expect(full.borderCatalog.records, hasLength(123));
      expect(full.borderCatalog.recordById(id), published);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('duplicates a spatial border as an independent draft', () async {
    final fixture = await _fixture(40);
    addTearDown(fixture.dispose);
    final map = File('${fixture.root.path}/maps/jardin.json');
    final bytes = await map.readAsBytes();
    final port = fixture.resources as ProjectBorderWorkshopPort;
    final before = await port.readWorkshopBorder(_borderId);
    final original = before.project.borderCatalog.records.single;
    final item = await fixture.maps.readResourceLibraryItem(
      fixture.session,
      'borderBlueprint',
      _borderId,
      expectedRevision: before.revision,
    );
    late String copyId;
    await fixture.guarded(fixture.blockedWorkshopFiles(), () async {
      final copy = await fixture.resources.duplicateLibraryResource(
        item,
        name: 'Copie du profil',
        expectedRevision: before.revision,
      );
      copyId = copy.item.id;
      expect(copyId, isNot(_borderId));
      expect(copy.item.familyId, item.familyId);
      expect(copy.receipt.actionId, 'catalog.definition.duplicate');
      expect(copy.receipt.changedPaths, ['catalog/HEAD.json']);
      expect(copy.receipt.changedMaps, isEmpty);
      final after = await port.readWorkshopBorder(copyId);
      final record = after.project.borderCatalog.records.single;
      expect(record.draft.baseRevision, 0);
      expect(record.latestPublished, isNull);
      expect(record.isDeprecated, isFalse);
      expect(record.draft.definition.name, 'Copie du profil');
      expect(
        record.draft.definition.primitives,
        original.draft.definition.primitives,
      );
      expect(
        record.draft.definition.defaults,
        original.draft.definition.defaults,
      );
    });
    expect(await map.readAsBytes(), bytes);
    await fixture.reopen();
    final reopened = fixture.resources as ProjectBorderWorkshopPort;
    expect(
      (await reopened.readWorkshopBorder(copyId))
          .project
          .borderCatalog
          .records
          .single
          .id,
      copyId,
    );
    expect(
      (await reopened.readWorkshopBorder(_borderId))
          .project
          .borderCatalog
          .records
          .single,
      original,
    );
  });

  test(
    'withdrawal names the border using a model indirectly on a map',
    () async {
      final fixture = await _fixture(0);
      addTearDown(fixture.dispose);
      final port = fixture.resources as ProjectBorderWorkshopPort;
      final border = await port.readWorkshopBorder(_borderId);
      final title =
          border.project.borderCatalog.records.single.draft.definition.name;
      final indexes = await fixture.resources.prepareResourceIndexes(
        expectedSnapshotRevision: border.revision,
      );
      final model = await fixture.maps.readResourceLibraryItem(
        fixture.session,
        'model3d',
        'piece_target_b',
        expectedRevision: indexes.revision,
      );
      final head = File('${fixture.root.path}/catalog/HEAD.json');
      final before = await head.readAsBytes();
      await fixture.guarded(fixture.blockedWorkshopFiles(), () async {
        await expectLater(
          fixture.resources.prepareLibraryDeletion(
            model,
            expectedRevision: indexes.revision,
          ),
          throwsA(
            isA<ResourceFailure>().having(
              (failure) => failure.message,
              'named consumer',
              contains('la bordure « $title »'),
            ),
          ),
        );
      });
      expect(await head.readAsBytes(), before);
    },
  );
}

void _expectStraightPreview(
  ProjectBorderWorkshopRead read,
  String id, {
  required bool draft,
}) {
  final assembly = buildBorderWorkshopAssembly(
    read.project,
    read.project.borderCatalog.recordById(id)!,
    draft: draft,
  );
  expect(assembly.issue, isNull);
  expect(assembly.map?.spatialScene?.instances, hasLength(8));
  expect(assembly.pieces.map((piece) => (piece.role, piece.placements)), [
    (BorderPrimitiveRole.lineCap, 2),
    (BorderPrimitiveRole.lineStraight, 6),
  ]);
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
