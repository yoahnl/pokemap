import 'package:flutter_test/flutter_test.dart';
import 'working_catalog_classification_fixture.dart';

void main() {
  test('indexed map scope and empty family deletion never attach the full project', () async {
    final fixture = await ClassificationFixture.create(unrelated: 300);
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    await fixture.workspace.ensureResourceKind('element');
    final revision = await fixture.resources.captureResourceRevision();
    final prepared = await fixture.resources.prepareResourceIndexes(expectedSnapshotRevision: revision);
    fixture.accept(prepared);
    await fixture.mutate('resource.classify', {
      'resourceKind': 'element', 'resourceId': 'decor_0000', 'mapId': 'jardin',
    });
    expect(fixture.phases, contains('plan.end'));
    expect(fixture.phases, isNot(contains('attach.start')));
    expect((await fixture.readPersistedCatalog()).entryFor('element', 'decor_0000')?.mapId, 'jardin');
    await fixture.mutate('resource.family.create', {'familyId': 'empty', 'name': 'Empty'});
    fixture.phases.clear();
    await fixture.mutate('resource.family.delete', {'familyId': 'empty'});
    expect(fixture.phases, contains('plan.end'));
    expect(fixture.phases, isNot(contains('attach.start')));
    expect((await fixture.readPersistedCatalog()).families.where((family) => family.id == 'empty'), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a working catalog classification survives loading another family and reopening', () async {
    final fixture = await ClassificationFixture.create();
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'props',
    );

    await fixture.classify('element', 'arbre', 'trees');
    expect(fixture.phases, contains('plan.end'));
    expect(fixture.phases, isNot(contains('attach.start')));
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );

    final written = await fixture.readPersistedCatalog();
    expect(written.entryFor('element', 'arbre')?.familyId, 'trees');

    await fixture.workspace.ensureResourceKind('tileset');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );

    final persisted = await fixture.readPersistedCatalog();
    expect(persisted.entryFor('element', 'arbre')?.familyId, 'trees');
    expect(persisted.entryFor('element', 'rocher')?.familyId, 'props');

    await fixture.reopen();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );
  });

  test('a new family filled by a batch survives loading another family and reopening', () async {
    final fixture = await ClassificationFixture.create();
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    await fixture.workspace.ensureResourceKind('element');
    await fixture.mutate('resource.family.create', {
      'familyId': 'family_garden',
      'name': 'Jardin',
      'parentId': null,
    });
    await fixture.mutate('resource.classify_batch', {
      'entries': [
        for (final id in ['arbre', 'caisse'])
          {
            'resourceKind': 'element',
            'resourceId': id,
            'familyId': 'family_garden',
          },
      ],
    });

    await fixture.workspace.ensureResourceKind('character');
    final catalog = fixture.workspace.project!.resourceLibraryCatalog;
    expect(catalog.entryFor('element', 'arbre')?.familyId, 'family_garden');
    expect(catalog.entryFor('element', 'caisse')?.familyId, 'family_garden');
    expect(
      catalog.effectiveFamilies.map((family) => family.id),
      contains('family_garden'),
    );

    final persisted = await fixture.readPersistedCatalog();
    expect(persisted.entryFor('element', 'caisse')?.familyId, 'family_garden');
    expect(persisted.entryFor('element', 'rocher')?.familyId, 'props');

    await fixture.reopen();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'family_garden',
    );
  });
}
