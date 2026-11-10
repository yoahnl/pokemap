import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_lifecycle_publication.dart';
import 'package:avelune_studio/features/resources/application/resource_removal_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_definition_lifecycle.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const _decor = ResourceItem(
  id: 'tree',
  name: 'Arbre',
  kind: ResourceKind.decors,
  category: 'nature',
);
const _source = ResourceItem(
  id: 'atlas',
  name: 'Planche',
  kind: ResourceKind.images,
  tileset: ProjectTilesetEntry(
    id: 'atlas',
    name: 'Planche',
    relativePath: 'atlas.png',
  ),
);

ResourceMutationPreparation _preparation({
  Map<String, Object?> impact = const {},
}) => ResourceMutationPreparation(
  sessionId: 'session',
  actionId: 'element.delete',
  parameters: const {'elementId': 'tree'},
  snapshotRevision: 'snapshot',
  manifestRevision: 'manifest',
  changedPaths: const ['project.json'],
  confirmationRequired: true,
  impact: impact,
);

void main() {
  test(
    'duplicate validates fields and prevents concurrent publication',
    () async {
      final publication = Completer<ResourceLifecyclePublicationResult>();
      final submitted = <(String, String)>[];
      var available = false;
      final session = ResourceDuplicateSession(
        item: _decor,
        canPublish: () => available,
        publish: (name, category) {
          submitted.add((name, category));
          return publication.future;
        },
      );
      expect(session.name, 'Arbre — copie');
      expect(await session.apply(), isNotNull);
      available = true;
      session.name = '  ';
      expect(await session.apply(), isNotNull);
      session.name = 'Copie';
      session.categoryId = '';
      expect(await session.apply(), isNotNull);
      session.categoryId = 'nature';
      final pending = session.apply();
      expect(session.applying, isTrue);
      expect(await session.apply(), isNotNull);
      expect(submitted, [('Copie', 'nature')]);
      publication.complete(
        const ResourceLifecyclePublicationResult(
          error: null,
          publicationCommitted: true,
        ),
      );
      expect(await pending, isNull);
      expect(session.canApply, isFalse);
      expect(await session.apply(), isNotNull);
      expect(submitted, hasLength(1));
    },
  );

  for (final committed in [false, true]) {
    test('duplicate retry follows publication commitment $committed', () async {
      var publications = 0;
      final session = ResourceDuplicateSession(
        item: _decor,
        canPublish: () => true,
        publish: (_, _) async {
          publications++;
          return ResourceLifecyclePublicationResult(
            error: 'Échec de réconciliation',
            publicationCommitted: committed,
          );
        },
      );
      expect(await session.apply(), 'Échec de réconciliation');
      expect(session.canApply, !committed);
      await session.apply();
      expect(publications, committed ? 1 : 2);
      session.dispose();
      expect(session.canApply, isFalse);
    });
  }

  test('removal requires prepared confirmation and clean owners', () async {
    var dirty = <String>[];
    var available = true;
    var publications = 0;
    final controller = ResourceRemovalController(
      item: _decor,
      prepareOperation: (_) async => _preparation(),
      publish: (_) async {
        publications++;
        return const ResourceLifecyclePublicationResult(
          error: null,
          publicationCommitted: true,
        );
      },
      dirtyOwners: () => dirty,
      canPublish: () => available,
    );
    controller.confirm(true);
    expect(await controller.apply(), isNotNull);
    await controller.prepare();
    expect(controller.canApply, isFalse);
    dirty = ['Carte · Jardin'];
    controller.confirm(true);
    expect(controller.confirmed, isFalse);
    dirty = [];
    controller.confirm(true);
    available = false;
    expect(await controller.apply(), isNotNull);
    available = true;
    expect(await controller.apply(), isNull);
    expect(await controller.apply(), isNotNull);
    expect(publications, 1);
  });

  test(
    'removal reanalysis clears confirmation and checks source choice',
    () async {
      final selected = <bool>[];
      final controller = ResourceRemovalController(
        item: _source,
        prepareOperation: (removeSource) async {
          selected.add(removeSource);
          return _preparation(
            impact: {'sourceRemovalSupported': true, 'sourceRemoved': false},
          );
        },
        publish: (_) async => const ResourceLifecyclePublicationResult(
          error: null,
          publicationCommitted: true,
        ),
        dirtyOwners: () => [],
        canPublish: () => true,
      );
      await controller.prepare();
      controller.confirm(true);
      expect(controller.canApply, isTrue);
      await controller.selectRemoveSource(true);
      expect(selected, [false, true]);
      expect(controller.confirmed, isFalse);
      expect(controller.preparation, isNull);
      expect(controller.error, contains('conservation de la source'));
      expect(controller.canApply, isFalse);
      await controller.selectRemoveSource(false);
      expect(controller.error, isNull);
      expect(controller.removeSource, isFalse);
    },
  );

  test(
    'closing removal ignores late preparation and waits for settling',
    () async {
      final preparation = Completer<ResourceMutationPreparation>();
      var calls = 0;
      final controller = ResourceRemovalController(
        item: _decor,
        prepareOperation: (_) {
          calls++;
          return preparation.future;
        },
        publish: (_) async => const ResourceLifecyclePublicationResult(
          error: null,
          publicationCommitted: true,
        ),
        dirtyOwners: () => [],
        canPublish: () => true,
      );
      final pending = controller.prepare();
      await controller.prepare();
      controller.dispose();
      var settled = false;
      final settling = controller.settle().then((_) => settled = true);
      expect(settled, isFalse);
      preparation.complete(_preparation());
      await pending;
      await settling;
      expect(settled, isTrue);
      expect(controller.preparation, isNull);
      expect(controller.canApply, isFalse);
      expect(calls, 1);
    },
  );

  for (final committed in [false, true]) {
    test('removal retry follows publication commitment $committed', () async {
      var publications = 0;
      final controller = ResourceRemovalController(
        item: _decor,
        prepareOperation: (_) async => _preparation(),
        publish: (_) async {
          publications++;
          return ResourceLifecyclePublicationResult(
            error: 'Échec de réconciliation',
            publicationCommitted: committed,
          );
        },
        dirtyOwners: () => [],
        canPublish: () => true,
      );
      await controller.prepare();
      controller.confirm(true);
      expect(await controller.apply(), 'Échec de réconciliation');
      expect(controller.canApply, !committed);
      await controller.apply();
      await controller.prepare();
      expect(publications, committed ? 1 : 2);
      if (committed) expect(controller.canApply, isFalse);
    });
  }
}
