import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';

import 'support/selbrume_narrative_authoring_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reconstructs a persisted narrative slice from physical map sources',
      () async {
    final harness =
        await SelbrumeNarrativeAuthoringHarness.createPhysicalFixture();
    addTearDown(harness.dispose);

    final result = await harness.authorVerticalSlice();

    expect(result.initialProject.facts, isEmpty);
    expect(result.initialProject.storylines, isEmpty);
    expect(result.initialProject.dialogues, isEmpty);
    expect(result.initialProject.cinematics, isEmpty);
    expect(result.initialProject.scenes, isEmpty);
    expect(result.initialProject.eventRegistry!.records, isEmpty);
    expect(result.initialProject.worldRules, isEmpty);

    expect(
      result.steps.map((step) => step.domain),
      const <SelbrumeNarrativeAuthoringDomain>[
        SelbrumeNarrativeAuthoringDomain.fact,
        SelbrumeNarrativeAuthoringDomain.storyline,
        SelbrumeNarrativeAuthoringDomain.dialogue,
        SelbrumeNarrativeAuthoringDomain.cinematic,
        SelbrumeNarrativeAuthoringDomain.scene,
        SelbrumeNarrativeAuthoringDomain.worldRule,
        SelbrumeNarrativeAuthoringDomain.event,
        SelbrumeNarrativeAuthoringDomain.validation,
        SelbrumeNarrativeAuthoringDomain.reload,
      ],
    );
    expect(result.steps.every((step) => step.diagnosticsCaptured), isTrue);
    final reloadedEvidence = result.steps.last;
    expect(
      reloadedEvidence.errorCount,
      0,
      reason: reloadedEvidence.diagnosticKeys.join('\n'),
    );

    final project = result.reloadedProject;
    expect(project.facts.map((entry) => entry.id), contains(result.factId));
    expect(
      project.storylines.map((entry) => entry.id),
      contains(result.storylineId),
    );
    expect(
      project.dialogues.map((entry) => entry.id),
      contains(result.dialogueId),
    );
    expect(
      project.cinematics.map((entry) => entry.id),
      contains(result.cinematicId),
    );
    expect(project.scenes.map((entry) => entry.id), contains(result.sceneId));
    expect(
      project.worldRules.map((entry) => entry.id),
      contains(result.worldRuleId),
    );

    final storyline = project.storylines.singleWhere(
      (entry) => entry.id == result.storylineId,
    );
    final chapter = storyline.chapters.singleWhere(
      (entry) => entry.id == result.chapterId,
    );
    final step = chapter.steps.singleWhere(
      (entry) => entry.id == result.stepId,
    );
    expect(step.sceneLinkIds, contains(result.sceneId));

    final event = project.eventRegistry!.records.singleWhere(
      (entry) => entry.id == result.eventId,
    );
    final definition = event.definitionOrNull!;
    expect(definition.sceneId, result.sceneId);
    expect(event.enabledOrNull, isTrue);
    expect(
      definition.source,
      NarrativeEventSourceRef.entityInteract(
        result.mapId,
        result.npcEntityId,
      ),
    );

    expect(result.authoredFingerprint, result.reloadedFingerprint);
    expect(
      File(result.dialogueFilePath).readAsStringSync(),
      contains('<<outcome accepted>>'),
    );
  });

  test('rejects an accidental second Event on the same physical source',
      () async {
    final harness =
        await SelbrumeNarrativeAuthoringHarness.createPhysicalFixture();
    addTearDown(harness.dispose);
    await harness.authorVerticalSlice();

    final duplicate = await harness.attemptDuplicateSourceEvent();

    expect(duplicate.status, NarrativeEventMapCreationStatus.existingLinks);
    expect(duplicate.linkedEvents, hasLength(1));
  });

  test('reconstructs every MVP player service through no-code operations',
      () async {
    final harness =
        await SelbrumeNarrativeAuthoringHarness.createPhysicalFixture();
    addTearDown(harness.dispose);

    final project = await harness.authorPlayerServices();

    final shop = project.shops.single;
    expect(shop.label, 'Comptoir des Brisants');
    expect(
      shop.entries.map((entry) => entry.itemId),
      const <String>['potion', 'antidote', 'poke-ball'],
    );
    expect(project.badges.single.fieldAbilityUnlock, FieldAbility.surf);

    final actionPayloads = project.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .toList();
    final commands = actionPayloads
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneInteractiveCommand>()
        .toList();
    expect(
      commands.map((command) => command.kind),
      containsAll(const <SceneInteractiveCommandKind>[
        SceneInteractiveCommandKind.openShop,
        SceneInteractiveCommandKind.openPc,
        SceneInteractiveCommandKind.warp,
      ]),
    );
    final consequences = actionPayloads
        .map((payload) => payload.consequence)
        .whereType<SceneConsequence>()
        .toList();
    expect(consequences.whereType<SceneHealPartyConsequence>(), hasLength(1));
    expect(
      consequences.whereType<SceneAwardBadgeConsequence>(),
      hasLength(1),
    );
    expect(
      consequences.whereType<SceneUnlockFieldAbilityConsequence>(),
      hasLength(1),
    );
  });

  test('keeps direct JSON and file writes outside the authoring harness', () {
    final source = File(
      'test/support/selbrume_narrative_authoring_harness.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('jsonDecode')));
    expect(source, isNot(contains('jsonEncode')));
    expect(source, isNot(contains('writeAsString')));
    expect(source, isNot(contains("File('project.json')")));
  });
}
