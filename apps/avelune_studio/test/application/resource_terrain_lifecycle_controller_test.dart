import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_lifecycle_publication.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_lifecycle_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:flutter_test/flutter_test.dart';

ResourceMutationPreparation _plan() => ResourceMutationPreparation(
  sessionId: 'session',
  actionId: 'smart_tile.preset.delete',
  parameters: const {'presetId': 'path'},
  snapshotRevision: 'snapshot',
  manifestRevision: 'manifest',
  changedPaths: const ['project.json'],
  confirmationRequired: true,
);

const _success = ResourceLifecyclePublicationResult(
  error: null,
  publicationCommitted: true,
);

void main() {
  test(
    'terrain deletion requires preparation and explicit renewed confirmation',
    () async {
      var publications = 0;
      final controller = ResourceTerrainLifecycleController(
        name: 'Chemin',
        duplicate: false,
        removing: true,
        canPublish: () => true,
        prepareOperation: (_) async => _plan(),
        publish: (_) async {
          publications++;
          return _success;
        },
      );
      controller.confirm(true);
      expect(await controller.apply(), isNotNull);
      await controller.prepareRemoval();
      expect(controller.canApply, isFalse);
      controller.confirm(true);
      await controller.prepareRemoval();
      expect(controller.confirmed, isFalse);
      controller.confirm(true);
      expect(await controller.apply(), isNull);
      expect(await controller.apply(), isNotNull);
      expect(publications, 1);
    },
  );

  test('a local-only terrain still requires confirmation without a disk preparation', () async {
    ResourceMutationPreparation? selected;
    final controller = ResourceTerrainLifecycleController(
      name: 'Chemin',
      duplicate: false,
      removing: true,
      canPublish: () => true,
      prepareOperation: (_) async => null,
      publish: (value) async {
        selected = value;
        return _success;
      },
    );
    await controller.prepareRemoval();
    expect(controller.ready, isTrue);
    expect(await controller.apply(), isNotNull);
    controller.confirm(true);
    expect(await controller.apply(), isNull);
    expect(selected, isNull);
  });

  test(
    'terrain naming preserves raw input and skips unchanged names',
    () async {
      final names = <String>[];
      final controller = ResourceTerrainLifecycleController(
        name: 'Chemin',
        duplicate: false,
        removing: false,
        canPublish: () => true,
        prepareOperation: (name) async {
          names.add(name);
          return _plan();
        },
        publish: (_) async => _success,
      );
      controller.name = '  Chemin  ';
      expect(await controller.apply(), isNull);
      expect(names, isEmpty);
      controller.name = '  Nouveau chemin  ';
      expect(controller.dirty, isTrue);
      expect(await controller.apply(), isNull);
      expect(names, ['  Nouveau chemin  ']);
    },
  );

  test('closing terrain naming before its preparation returns refuses publication and settles', () async {
    var publications = 0;
    final gate = Completer<ResourceMutationPreparation>();
    final controller = ResourceTerrainLifecycleController(
      name: 'Chemin',
      duplicate: true,
      removing: false,
      canPublish: () => true,
      prepareOperation: (_) => gate.future,
      publish: (_) async {
        publications++;
        return _success;
      },
    );
    expect(controller.name, 'Chemin — copie');
    final applying = controller.apply();
    controller.dispose();
    var settled = false;
    final settling = controller.settle().then((_) => settled = true);
    expect(settled, isFalse);
    gate.complete(_plan());
    expect(await applying, contains('plus active'));
    await settling;
    expect(settled, isTrue);
    expect(publications, 0);
  });

  test('closed terrain removal ignores a late preparation', () async {
    final gate = Completer<ResourceMutationPreparation>();
    final controller = ResourceTerrainLifecycleController(
      name: 'Chemin',
      duplicate: false,
      removing: true,
      canPublish: () => true,
      prepareOperation: (_) => gate.future,
      publish: (_) async => _success,
    );
    final preparing = controller.prepareRemoval();
    controller.dispose();
    gate.complete(_plan());
    await preparing;
    expect(controller.ready, isFalse);
    expect(controller.preparation, isNull);
  });

  test(
    'a name changed during preparation cannot publish the older name',
    () async {
      var publications = 0;
      final gate = Completer<ResourceMutationPreparation>();
      final controller = ResourceTerrainLifecycleController(
        name: 'Chemin',
        duplicate: true,
        removing: false,
        canPublish: () => true,
        prepareOperation: (_) => gate.future,
        publish: (_) async {
          publications++;
          return _success;
        },
      );
      controller.name = 'Nom A';
      final applying = controller.apply();
      controller.name = 'Nom B';
      gate.complete(_plan());
      await applying;
      expect(publications, 0);
      expect(controller.name, 'Nom B');
      expect(controller.canApply, isTrue);
    },
  );

  for (final committed in [false, true]) {
    test('terrain retry follows actual commitment $committed', () async {
      var publications = 0;
      final controller = ResourceTerrainLifecycleController(
        name: 'Chemin',
        duplicate: true,
        removing: false,
        canPublish: () => true,
        prepareOperation: (_) async => _plan(),
        publish: (_) async {
          publications++;
          return ResourceLifecyclePublicationResult(
            error: 'Relecture refusée',
            publicationCommitted: committed,
          );
        },
      );
      expect(await controller.apply(), 'Relecture refusée');
      await controller.apply();
      expect(publications, committed ? 1 : 2);
    });
  }
}
