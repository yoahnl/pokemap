import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_border_lifecycle_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_lifecycle_publication.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:flutter_test/flutter_test.dart';

ResourceMutationPreparation _plan() => ResourceMutationPreparation(
  sessionId: 'session',
  actionId: 'border.blueprint.set_deprecated',
  parameters: const {'blueprintId': 'fence', 'isDeprecated': true},
  snapshotRevision: 'snapshot',
  manifestRevision: 'manifest',
  changedPaths: const ['project.json'],
  confirmationRequired: true,
);

void main() {
  test('border publication requires a fresh confirmed preparation', () async {
    var preparations = 0, publications = 0;
    var available = true;
    final controller = ResourceBorderLifecycleController(
      prepareOperation: () async {
        preparations++;
        return _plan();
      },
      canPublish: () => available,
      publish: (_) async {
        publications++;
        return const ResourceLifecyclePublicationResult(
          error: null,
          publicationCommitted: true,
        );
      },
    );
    controller.confirm(true);
    expect(await controller.apply(), isNotNull);
    await controller.prepare();
    controller.confirm(true);
    available = false;
    expect(await controller.apply(), isNotNull);
    available = true;
    await controller.prepare();
    expect(controller.confirmed, isFalse);
    controller.confirm(true);
    expect(await controller.apply(), isNull);
    expect(await controller.apply(), isNotNull);
    expect(preparations, 2);
    expect(publications, 1);
  });

  test('border preparation failure preserves a recoverable refusal', () async {
    var attempts = 0;
    final controller = ResourceBorderLifecycleController(
      prepareOperation: () async {
        if (attempts++ == 0) throw StateError('Propriétaire en cours');
        return _plan();
      },
      canPublish: () => true,
      publish: (_) async => const ResourceLifecyclePublicationResult(
        error: null,
        publicationCommitted: true,
      ),
    );
    await controller.prepare();
    expect(controller.error, contains('Propriétaire en cours'));
    expect(controller.canApply, isFalse);
    await controller.prepare();
    expect(controller.error, isNull);
    expect(controller.preparation, isNotNull);
  });

  test(
    'closing waits for border preparation and ignores the late state',
    () async {
      final pending = Completer<ResourceMutationPreparation>();
      final controller = ResourceBorderLifecycleController(
        prepareOperation: () => pending.future,
        canPublish: () => true,
        publish: (_) async => const ResourceLifecyclePublicationResult(
          error: null,
          publicationCommitted: true,
        ),
      );
      final preparing = controller.prepare();
      controller.dispose();
      var settled = false;
      final settling = controller.settle().then((_) => settled = true);
      expect(settled, isFalse);
      pending.complete(_plan());
      await preparing;
      await settling;
      expect(settled, isTrue);
      expect(controller.preparation, isNull);
      expect(await controller.apply(), isNotNull);
    },
  );

  for (final committed in [false, true]) {
    test('border retry follows publication commitment $committed', () async {
      final result = Completer<ResourceLifecyclePublicationResult>();
      var publications = 0;
      final controller = ResourceBorderLifecycleController(
        prepareOperation: () async => _plan(),
        canPublish: () => true,
        publish: (_) {
          publications++;
          return result.future;
        },
      );
      await controller.prepare();
      controller.confirm(true);
      final pending = controller.apply();
      expect(await controller.apply(), isNotNull);
      result.complete(
        ResourceLifecyclePublicationResult(
          error: 'Publication interrompue',
          publicationCommitted: committed,
        ),
      );
      expect(await pending, 'Publication interrompue');
      expect(controller.canApply, !committed);
      await controller.apply();
      expect(publications, committed ? 1 : 2);
    });
  }
}
