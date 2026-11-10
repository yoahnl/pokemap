import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_lifecycle_publication.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_replacement_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:flutter_test/flutter_test.dart';

const _choice = ResourceItem(
  id: 'bush',
  name: 'Buisson',
  kind: ResourceKind.decors,
);
const _other = ResourceItem(
  id: 'rock',
  name: 'Rocher',
  kind: ResourceKind.decors,
);

ResourceMutationPreparation _plan({bool empty = false}) =>
    ResourceMutationPreparation(
      sessionId: 'session',
      actionId: 'resource.usages.replace',
      parameters: const {'replacementId': 'bush'},
      snapshotRevision: 'snapshot',
      manifestRevision: 'manifest',
      changedPaths: empty ? [] : ['garden.json'],
      confirmationRequired: true,
      impact: const {
        'occurrenceCount': 2,
        'mapCount': 1,
        'maps': [
          {
            'mapId': 'garden',
            'instanceIds': ['tree-1', 'tree-2'],
          },
        ],
      },
    );

ResourceUsageReplacementController _controller({
  required Future<ResourceMutationPreparation> Function(String) prepare,
  Future<ResourceLifecyclePublicationResult> Function(
    ResourceMutationPreparation,
  )?
  publish,
}) => ResourceUsageReplacementController(
  name: 'Arbre',
  spatial: false,
  choices: const [_choice, _other],
  canPublish: () => true,
  prepareOperation: prepare,
  publish:
      publish ??
      (_) async => const ResourceLifecyclePublicationResult(
        error: null,
        publicationCommitted: true,
      ),
);

void main() {
  test(
    'choosing another replacement clears the reviewed confirmation',
    () async {
      final choices = <String>[];
      final controller = _controller(
        prepare: (id) async {
          choices.add(id);
          return _plan();
        },
      );
      await controller.choose(_choice);
      controller.confirm(true);
      expect(controller.canApply, isTrue);
      expect(controller.scope, [(mapId: 'garden', count: 2)]);
      expect(controller.summary, '2 occurrences sur 1 carte');
      await controller.choose(_other);
      expect(controller.confirmed, isFalse);
      expect(controller.canApply, isFalse);
      expect(choices, ['bush', 'rock']);
    },
  );

  test('unknown replacements and empty plans cannot publish', () async {
    var preparations = 0;
    final controller = _controller(
      prepare: (_) async {
        preparations++;
        return _plan(empty: true);
      },
    );
    await controller.choose(
      const ResourceItem(
        id: 'foreign',
        name: 'Autre',
        kind: ResourceKind.images,
      ),
    );
    expect(preparations, 0);
    await controller.choose(_choice);
    controller.confirm(true);
    expect(controller.canApply, isFalse);
    expect(await controller.apply(), isNotNull);
  });

  test(
    'closing waits for the retained preparation without publishing late state',
    () async {
      final preparation = Completer<ResourceMutationPreparation>();
      final controller = _controller(prepare: (_) => preparation.future);
      final choosing = controller.choose(_choice);
      controller.dispose();
      var settled = false;
      final settling = controller.settle().then((_) => settled = true);
      expect(settled, isFalse);
      preparation.complete(_plan());
      await choosing;
      await settling;
      expect(settled, isTrue);
      expect(controller.preparation, isNull);
      expect(controller.canApply, isFalse);
    },
  );

  for (final committed in [false, true]) {
    test(
      'replacement retry follows publication commitment $committed',
      () async {
        final publication = Completer<ResourceLifecyclePublicationResult>();
        var publications = 0;
        final controller = _controller(
          prepare: (_) async => _plan(),
          publish: (_) {
            publications++;
            return publication.future;
          },
        );
        await controller.choose(_choice);
        controller.confirm(true);
        final pending = controller.apply();
        expect(await controller.apply(), isNotNull);
        publication.complete(
          ResourceLifecyclePublicationResult(
            error: 'Échec de publication',
            publicationCommitted: committed,
          ),
        );
        expect(await pending, 'Échec de publication');
        expect(controller.canApply, !committed);
        await controller.apply();
        expect(publications, committed ? 1 : 2);
      },
    );
  }

  test(
    'a preparation failure keeps the choice and permits explicit retry',
    () async {
      var attempts = 0;
      final controller = _controller(
        prepare: (_) async {
          if (attempts++ == 0) throw StateError('Révision changée');
          return _plan();
        },
      );
      await controller.choose(_choice);
      expect(controller.replacement, same(_choice));
      expect(controller.error, contains('Révision changée'));
      expect(controller.canApply, isFalse);
      await controller.choose(_choice);
      controller.confirm(true);
      expect(controller.error, isNull);
      expect(controller.canApply, isTrue);
    },
  );
}
