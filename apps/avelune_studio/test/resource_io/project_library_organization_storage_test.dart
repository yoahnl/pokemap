import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/project_library_organization.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'working_catalog_classification_fixture.dart';

void main() {
  test(
    'library organization publishes one batch and preserves unrelated data',
    () async {
      final fixture = await ClassificationFixture.create(unrelated: 300);
      addTearDown(fixture.dispose);
      await fixture.openWorkspace();
      final project = fixture.workspace.active!;
      project.commit(project.current.copyWith(name: 'Jardin en cours'));
      final ProjectLibraryOrganization organization = fixture.resources;
      final prepared = await fixture.resources.prepareResourceIndexes(
        expectedSnapshotRevision: await fixture.resources
            .captureResourceRevision(),
      );
      fixture.accept(prepared);
      final library = await fixture.maps.readResourceLibrary(fixture.session);
      final items = library.items
          .where((item) => const {'arbre', 'rocher'}.contains(item.id))
          .toList();
      final created = await organization.saveLibraryFamily(
        existing: null,
        name: 'Sous-bois',
        parentId: 'trees',
        expectedRevision: library.revision!,
      );
      fixture.accept(created.receipt);
      expect(created.family?.parentId, 'trees');

      fixture.phases.clear();
      final batch = await organization.classifyLibraryResources(
        items,
        family: (id: created.id),
        role: ResourceLibraryRole.component,
        expectedRevision: created.receipt.revision,
      );
      fixture.accept(batch.receipt);
      expect(batch.receipt.actionId, 'resource.classify_batch');
      expect(
        batch.items.map((item) => item.id),
        unorderedEquals(['arbre', 'rocher']),
      );
      expect(
        batch.items.map((item) => item.familyId),
        everyElement(created.id),
      );
      expect(
        batch.items.map((item) => item.role),
        everyElement(ResourceLibraryRole.component),
      );
      expect(
        fixture.phases.where((phase) => phase == 'apply.end'),
        hasLength(1),
      );
      expect(fixture.phases, isNot(contains('attach.start')));

      await expectLater(
        organization.deleteLibraryFamily(
          created.family!,
          expectedRevision: batch.receipt.revision,
        ),
        throwsA(
          isA<ResourceFailure>().having(
            (error) => error.message,
            'message',
            contains('contient'),
          ),
        ),
      );
      await expectLater(
        organization.classifyLibraryResources(
          items,
          family: (id: null),
          role: null,
          expectedRevision: library.revision!,
        ),
        throwsA(isA<ResourceFailure>()),
      );
      final moved = await organization.saveLibraryFamily(
        existing: created.family,
        name: 'Végétation basse',
        parentId: 'vegetation',
        expectedRevision: batch.receipt.revision,
      );
      fixture.accept(moved.receipt);
      expect(moved.family?.id, created.id);
      expect(moved.family?.parentId, 'vegetation');
      expect(fixture.workspace.active, same(project));
      expect(project.current.name, 'Jardin en cours');
      expect(project.dirty, isTrue);

      await fixture.reopen();
      final reopened = await fixture.maps.readResourceLibrary(fixture.session);
      expect(reopened.catalog.families.single, moved.family);
      final two = reopened.items.where(
        (item) => const {'arbre', 'rocher'}.contains(item.id),
      );
      expect(two.map((item) => item.familyId), everyElement(created.id));
      expect(
        two.map((item) => item.role),
        everyElement(ResourceLibraryRole.component),
      );
      final unrelated = reopened.items.singleWhere(
        (item) => item.id == 'decor_0000',
      );
      expect(unrelated.familyId, 'buildings');
      expect(unrelated.description, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'library preparation and clearing a family keep the resource role',
    () async {
      final fixture = await ClassificationFixture.create();
      addTearDown(fixture.dispose);
      await fixture.openWorkspace();
      final ProjectLibraryOrganization organization = fixture.resources;
      final library = await fixture.maps.readResourceLibrary(fixture.session);
      final original = library.items.singleWhere((item) => item.id == 'arbre');
      final created = await organization.saveLibraryFamily(
        existing: null,
        name: 'Famille vide',
        parentId: null,
        expectedRevision: library.revision!,
      );
      fixture.accept(created.receipt);
      await expectLater(
        organization.deleteLibraryFamily(
          created.family!,
          expectedRevision: created.receipt.revision,
        ),
        throwsA(isA<ProjectLibraryNeedsPreparation>()),
      );
      final prepared = await fixture.resources.prepareResourceIndexes(
        expectedSnapshotRevision: created.receipt.revision,
      );
      fixture.accept(prepared);
      final roles = await organization.classifyLibraryResources(
        [original],
        family: null,
        role: ResourceLibraryRole.component,
        expectedRevision: prepared.revision,
      );
      fixture.accept(roles.receipt);
      expect(roles.items.single.familyId, original.familyId);
      final unfiled = await organization.classifyLibraryResources(
        roles.items,
        family: (id: null),
        role: null,
        expectedRevision: roles.receipt.revision,
      );
      fixture.accept(unfiled.receipt);
      expect(unfiled.items.single.familyId, isNull);
      expect(unfiled.items.single.role, ResourceLibraryRole.component);
      final deleted = await organization.deleteLibraryFamily(
        created.family!,
        expectedRevision: unfiled.receipt.revision,
      );
      fixture.accept(deleted.receipt);
      expect(deleted.family, isNull);
      final persisted = await fixture.readPersistedCatalog();
      expect(persisted.families, isEmpty);
      expect(
        persisted.entryFor('element', 'arbre')?.role,
        ResourceLibraryRole.component,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
