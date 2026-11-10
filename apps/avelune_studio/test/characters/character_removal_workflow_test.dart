import 'dart:async';

import 'package:avelune_studio/features/characters/application/character_removal_controller.dart';
import 'package:avelune_studio/features/characters/coordination/character_removal_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/authoring_resource_fixture.dart';

void main() {
  test('real character removal requires confirmation, preserves source assets and releases management lock', () async {
    final fixture = await AuthoringResourceFixture.create(noMaps: true);
    addTearDown(fixture.dispose);
    final characters = fixture.navigation.characters;
    expect(
      await characters.create(
        'Effaçable',
        fixture.workspace.project!.tilesets.first.id,
        frameWidth: 1,
        frameHeight: 1,
      ),
      isTrue,
    );
    final character = characters.selectedCharacter!;
    final assets = fixture.workspace.project!.tilesets;
    Object? callbackFailure;
    StackTrace? callbackStack;
    var presented = false;
    await runCharacterRemoval(
      navigation: fixture.navigation,
      character: character,
      present: (controller) async {
        presented = true;
        try {
          expect(fixture.navigation.managementDialogActive, isTrue);
          await controller.inspect();
          expect(controller.error, isNull);
          expect(controller.plan, isNotNull);
          expect(controller.canSubmit, isFalse);
          expect(
            (await fixture.reopen()).characters.any(
              (entry) => entry.id == character.id,
            ),
            isTrue,
          );
          controller.confirm(true);
          expect(controller.canSubmit, isTrue);
          expect(await controller.submit(), isNull);
        } catch (error, stack) {
          callbackFailure = error;
          callbackStack = stack;
          rethrow;
        }
      },
    );
    if (callbackFailure != null) {
      Error.throwWithStackTrace(callbackFailure!, callbackStack!);
    }
    expect(presented, isTrue);
    expect(fixture.navigation.managementDialogActive, isFalse);
    final reopened = await fixture.reopen();
    expect(
      reopened.characters.any((entry) => entry.id == character.id),
      isFalse,
    );
    expect(reopened.tilesets, assets);
  });

  test('replacement plan uses the inspected revision and changing a choice revokes confirmation', () async {
    final calls = <(Map<String, Object?>, String)>[];
    final controller = CharacterRemovalController(
      inspectOperation: () async => _plan(
        'r1',
        impact: {
          'requiresResolution': true,
          'clearAllowed': true,
          'replacementCandidates': [
            {'id': 'good', 'compatible': true},
            {'id': 'bad', 'compatible': false},
          ],
        },
      ),
      prepareOperation: (values, revision) async {
        calls.add((values, revision));
        return _plan(revision);
      },
      applyOperation: (_) async => null,
      canApply: () => true,
    );
    addTearDown(controller.dispose);
    await controller.inspect();
    expect(controller.plan, isNull);
    expect(calls, isEmpty);
    await controller.selectResolution('replace');
    expect(calls, isEmpty);
    await controller.selectReplacement('good');
    expect(calls.single.$1, {'resolution': 'replace', 'replacementId': 'good'});
    expect(calls.single.$2, 'r1');
    controller.confirm(true);
    expect(controller.canSubmit, isTrue);
    await controller.selectResolution('clear');
    expect(controller.confirmed, isFalse);
    expect(controller.canSubmit, isFalse);
    expect(calls.last.$1, {'resolution': 'clear'});
    expect(calls.last.$2, 'r1');
  });

  test(
    'disposed removal owner ignores a late inspection and never enables a plan',
    () async {
      final inspection = Completer<ResourceMutationPreparation>();
      var notifications = 0;
      var preparations = 0;
      var applies = 0;
      final controller = CharacterRemovalController(
        inspectOperation: () => inspection.future,
        prepareOperation: (_, _) async {
          preparations++;
          return _plan('unexpected');
        },
        applyOperation: (_) async {
          applies++;
          return null;
        },
        canApply: () => true,
      );
      controller.addListener(() => notifications++);
      final pending = controller.inspect();
      controller.dispose();
      inspection.complete(_plan('r1'));
      await pending;
      expect(controller.inspection, isNull);
      expect(controller.plan, isNull);
      expect(controller.canSubmit, isFalse);
      expect(notifications, 1);
      expect(preparations, 0);
      expect(applies, 0);
    },
  );

  test(
    'superseded prepared plan cannot replace the current revision',
    () async {
      final oldPlan = Completer<ResourceMutationPreparation>();
      var inspections = 0;
      final controller = CharacterRemovalController(
        inspectOperation: () async => _plan('r${++inspections}'),
        prepareOperation: (_, revision) =>
            revision == 'r1' ? oldPlan.future : Future.value(_plan(revision)),
        applyOperation: (_) async => null,
        canApply: () => true,
      );
      addTearDown(controller.dispose);
      final first = controller.inspect();
      await Future<void>.delayed(Duration.zero);
      await controller.inspect();
      expect(controller.plan!.snapshotRevision, 'r2');
      oldPlan.complete(_plan('r1'));
      await first;
      expect(controller.plan!.snapshotRevision, 'r2');
      expect(controller.working, isFalse);
    },
  );

  test('owner gate and pending publication prevent duplicate removal while preserving retry state', () async {
    var allowed = false;
    var calls = 0;
    final result = Completer<String?>();
    final controller = CharacterRemovalController(
      inspectOperation: () async => _plan('r1'),
      prepareOperation: (_, _) async => _plan('r1'),
      applyOperation: (_) {
        calls++;
        return result.future;
      },
      canApply: () => allowed,
    );
    addTearDown(controller.dispose);
    await controller.inspect();
    controller.confirm(true);
    expect(controller.canSubmit, isFalse);
    expect(await controller.submit(), isNotNull);
    expect(calls, 0);
    allowed = true;
    final pending = controller.submit();
    expect(controller.applying, isTrue);
    expect(await controller.submit(), isNotNull);
    expect(calls, 1);
    result.complete('publication.refused');
    expect(await pending, 'publication.refused');
    expect(controller.applying, isFalse);
    expect(controller.plan, isNotNull);
    expect(controller.canSubmit, isTrue);
  });
  test('pending publication freezes analysis choices and confirmation until apply finishes', () async {
    var inspections = 0;
    var preparations = 0;
    final applied = Completer<String?>();
    final controller = CharacterRemovalController(
      inspectOperation: () async {
        inspections++;
        return _plan(
          'r1',
          impact: {
            'requiresResolution': true,
            'replacementCandidates': [
              {'id': 'good', 'compatible': true},
            ],
          },
        );
      },
      prepareOperation: (_, revision) async {
        preparations++;
        return _plan(revision);
      },
      applyOperation: (_) => applied.future,
      canApply: () => true,
    );
    addTearDown(controller.dispose);
    await controller.inspect();
    await controller.selectResolution('replace');
    await controller.selectReplacement('good');
    controller.confirm(true);
    final plan = controller.plan;
    final pending = controller.submit();
    expect(controller.applying, isTrue);
    await controller.inspect();
    await controller.selectResolution('clear');
    await controller.selectReplacement('other');
    await controller.prepare();
    controller.confirm(false);
    expect(inspections, 1);
    expect(preparations, 1);
    expect(controller.plan, same(plan));
    expect(controller.resolution, 'replace');
    expect(controller.replacementId, 'good');
    expect(controller.confirmed, isTrue);
    applied.complete(null);
    expect(await pending, isNull);
    expect(controller.applying, isFalse);
  });
}

ResourceMutationPreparation _plan(
  String revision, {
  Map<String, Object?> impact = const {},
}) => ResourceMutationPreparation(
  sessionId: 'session',
  actionId: 'characterStudio.character.delete',
  parameters: const {},
  snapshotRevision: revision,
  manifestRevision: 'manifest',
  changedPaths: const ['project.json'],
  confirmationRequired: true,
  impact: impact,
);
