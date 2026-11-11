import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_lifecycle_publication.dart';
import 'package:avelune_studio/features/resources/application/resource_removal_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const _sheet = ResourceItem(
  id: 'sheet',
  name: 'Planche témoin',
  kind: ResourceKind.images,
  tileset: ProjectTilesetEntry(
    id: 'sheet',
    name: 'Planche témoin',
    relativePath: 'assets/planche.png',
  ),
);

final class _Analysis {
  _Analysis(this.removeSource);
  final bool removeSource;
  final result = Completer<ResourceMutationPreparation>();
}

final class _Setup {
  final analyses = <_Analysis>[];
  final applied = <ResourceMutationPreparation>[];

  late final controller = ResourceRemovalController(
    item: _sheet,
    prepareOperation: (choice) {
      final analysis = _Analysis(choice);
      analyses.add(analysis);
      return analysis.result.future;
    },
    publish: (preparation) async {
      applied.add(preparation);
      return const ResourceLifecyclePublicationResult(
        error: null,
        publicationCommitted: true,
      );
    },
    dirtyOwners: () => [],
    canPublish: () => true,
  );

  ResourceMutationPreparation plan(
    _Analysis analysis, {
    bool? capability = true,
    bool? sourceRemoved,
    bool logicalFileRemoved = true,
    String? reason,
  }) => ResourceMutationPreparation(
    sessionId: 'session',
    actionId: 'tileset.remove',
    parameters: {'tilesetId': 'sheet', 'removeSource': analysis.removeSource},
    snapshotRevision: 'snapshot-${analyses.indexOf(analysis)}',
    manifestRevision: 'manifest',
    changedPaths: [
      'project.json',
      if (sourceRemoved ?? analysis.removeSource) 'assets/catalog.json',
      if ((sourceRemoved ?? analysis.removeSource) && logicalFileRemoved)
        'assets/planche.png',
    ],
    confirmationRequired: true,
    impact: {
      'sourceRemovalSupported': ?capability,
      'sourceRemoved': sourceRemoved ?? analysis.removeSource,
      'logicalFileRemoved': logicalFileRemoved,
      'logicalSourcePath': 'assets/planche.png',
      'sourceRemovalReason': ?reason,
    },
  );

  Future<void> opened() async {
    final pending = controller.prepare();
    await ready();
    await pending;
  }

  Future<void> ready({
    bool? capability = true,
    bool? sourceRemoved,
    bool logicalFileRemoved = true,
    String? reason,
  }) async {
    final analysis = analyses.last;
    analysis.result.complete(
      plan(
        analysis,
        capability: capability,
        sourceRemoved: sourceRemoved,
        logicalFileRemoved: logicalFileRemoved,
        reason: reason,
      ),
    );
    await controller.settle();
  }
}

void main() {
  test('source off on off invalidates plans and confirms only off', () async {
    final setup = _Setup();
    final controller = setup.controller;
    final pendingFirst = controller.prepare();
    expect(setup.analyses.single.removeSource, isFalse);
    expect(controller.removeSource, isFalse);
    await setup.ready();
    await pendingFirst;
    controller.confirm(true);
    expect(controller.canApply, isTrue);

    final toggledOn = controller.selectRemoveSource(true);
    expect(controller.removeSource, isTrue);
    expect(controller.working, isTrue);
    expect(controller.confirmed, isFalse);
    expect(controller.canApply, isFalse);
    controller.confirm(true);
    expect(controller.confirmed, isFalse);
    await setup.ready();
    await toggledOn;
    expect(controller.canApply, isFalse);
    expect(controller.preparation!.changedPaths, contains('assets/planche.png'));
    controller.confirm(true);
    expect(controller.canApply, isTrue);

    final toggledOff = controller.selectRemoveSource(false);
    expect(controller.removeSource, isFalse);
    expect(controller.confirmed, isFalse);
    expect(controller.canApply, isFalse);
    await setup.ready();
    await toggledOff;
    expect(controller.confirmed, isFalse);
    expect(controller.canApply, isFalse);
    controller.confirm(true);
    expect(await controller.apply(), isNull);

    expect(setup.analyses.map((a) => a.removeSource), [false, true, false]);
    expect(setup.applied.single.parameters['removeSource'], isFalse);
    expect(setup.applied.single.changedPaths, ['project.json']);
    expect(setup.applied.single.snapshotRevision, 'snapshot-2');
  });

  test('confirmed source removal applies the exact analyzed plan', () async {
    final setup = _Setup();
    final controller = setup.controller;
    await setup.opened();
    final toggled = controller.selectRemoveSource(true);
    final current = setup.analyses.last;
    final plan = setup.plan(current);
    current.result.complete(plan);
    await toggled;
    expect(controller.canApply, isFalse);
    expect(controller.sourceRemovalSupported, isTrue);
    expect(controller.preparation, same(plan));
    controller.confirm(true);
    expect(await controller.apply(), isNull);
    expect(setup.applied.single, same(plan));
    expect(setup.applied.single.parameters['removeSource'], isTrue);
    expect(setup.applied.single.changedPaths, contains('assets/planche.png'));
  });

  for (final mode in ['erreur', 'capacité perdue']) {
    test('$mode disarms removal and allows explicit source retention', () async {
      final setup = _Setup();
      final controller = setup.controller;
      await setup.opened();
      final toggled = controller.selectRemoveSource(true);
      if (mode == 'erreur') {
        setup.analyses.last.result.completeError(StateError('source partagée'));
        await toggled;
        expect(controller.error, contains('source partagée'));
      } else {
        await setup.ready(
          capability: false,
          sourceRemoved: false,
          reason: 'La source est devenue partagée.',
        );
        await toggled;
        expect(controller.error, isNotNull);
      }
      expect(controller.sourceRemovalSupported, isFalse);
      expect(controller.removeSource, isTrue);
      expect(controller.preparation, isNull);
      expect(controller.canApply, isFalse);
      controller.confirm(true);
      expect(controller.confirmed, isFalse);
      expect(await controller.apply(), isNotNull);
      expect(setup.applied, isEmpty);

      final retention = controller.selectRemoveSource(false);
      expect(controller.removeSource, isFalse);
      await setup.ready(capability: false, sourceRemoved: false);
      await retention;
      expect(controller.error, isNull);
      expect(controller.removeSource, isFalse);
      controller.confirm(true);
      expect(await controller.apply(), isNull);
      expect(setup.applied.single.parameters['removeSource'], isFalse);
    });
  }

  for (final capacity in [false, null]) {
    test('capacity $capacity never permits choosing a source removal', () async {
      final setup = _Setup();
      final controller = setup.controller;
      final pending = controller.prepare();
      await setup.ready(capability: capacity, sourceRemoved: false);
      await pending;
      expect(controller.sourceRemovalSupported, isFalse);
      await controller.selectRemoveSource(true);
      expect(controller.removeSource, isFalse);
      expect(setup.analyses, hasLength(1));
      controller.confirm(true);
      expect(await controller.apply(), isNull);
      expect(setup.applied.single.parameters['removeSource'], isFalse);
    });
  }

  test('content-addressed source removal explicitly retains blob file', () async {
    final setup = _Setup();
    final controller = setup.controller;
    await setup.opened();
    final toggled = controller.selectRemoveSource(true);
    await setup.ready(logicalFileRemoved: false);
    await toggled;
    controller.confirm(true);
    expect(await controller.apply(), isNull);
    expect(setup.applied.single.impact['sourceRemoved'], isTrue);
    expect(setup.applied.single.changedPaths, isNot(contains('assets/planche.png')));
  });
}
