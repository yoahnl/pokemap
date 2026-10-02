import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'character_studio_deletion_fixture.dart';

Future<Map<String, List<int>>> unchangedBytes(
        CharacterDeletionFixture fixture) async =>
    {
      for (final path in [
        'assets/characters.png',
        assetCatalogStorageKey,
        'unrelated.txt',
        'maps/untouched.json',
        'dialogues/untouched.yarn'
      ])
        path: await File('${fixture.root.path}/$path').readAsBytes(),
    };

void verifyResolved(ProjectSnapshot snapshot) {
  expect(snapshot.manifest.characters.map((c) => c.id), ['nox']);
  expect(snapshot.manifest.settings.defaultPlayerCharacterId, 'nox');
  expect(snapshot.manifest.newGame.playerAvatarCharacterIds, ['nox']);
  expect(snapshot.mapById('village')!.entities.single.npc!.characterId, 'nox');
  expect(snapshot.manifest.trainers.single.characterId, 'nox');
  expect(
      snapshot.manifest.cinematics.single.stageContext!.actorAppearanceBindings
          .single.characterId,
      'nox');
  final source = utf8.decode(snapshot.resourceBytes('dialogueSource:intro'));
  expect(source, contains('<<portrait nox neutral>>'));
  expect(source, contains('Élia: Bonjour elia.'));
  final second = utf8.decode(snapshot.resourceBytes('dialogueSource:second'));
  expect(second, contains('<<portrait nox neutral>>'));
  expect(second, contains('Un second dialogue elia.'));
  final compiled = const DialogueAuthoringCompiler().compile(
      entry: snapshot.manifest.dialogues
          .singleWhere((entry) => entry.id == 'intro'),
      source: source);
  expect(compiled.canPublish, true);
  final statements = compiled.document!.nodes
      .expand((node) => node.steps)
      .whereType<RuntimeDialogueLine>();
  expect(statements.single.characterId, 'nox');
  expect(statements.single.portraitStateId, 'neutral');
  expect(snapshot.manifest.characters.single.portraits.single.assetId,
      'elia-neutral');
}

void main() {
  test(
      'JSONL inspects then commits one qualified multi-document deletion and reopens independently',
      () async {
    final fixture = await CharacterDeletionFixture.create();
    addTearDown(fixture.dispose);
    final before = await unchangedBytes(fixture);
    final projectBefore =
        await File('${fixture.root.path}/project.json').readAsBytes();
    final inspected = await fixture.wire('plan', {
      'projectHandle': fixture.opened.projectHandle.value,
      'request': (await fixture.request(inspect: true)).toJson()
    });
    expect(inspected.status, AuthoringResultStatus.success,
        reason: jsonEncode(inspected.toJson()));
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        projectBefore);
    final planned = await fixture.wire('plan', {
      'projectHandle': fixture.opened.projectHandle.value,
      'request': (await fixture.request()).toJson()
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    final confirmation = await fixture.wire('confirm', {
      'projectHandle': fixture.opened.projectHandle.value,
      'planId': planned.data['planId']
    });
    expect(confirmation.status, AuthoringResultStatus.success,
        reason: jsonEncode(confirmation.toJson()));
    final applied = await fixture.wire('apply', {
      'projectHandle': fixture.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'character-wire-delete',
      'confirmationToken': confirmation.data['confirmationToken']
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    verifyResolved(await fixture.independent());
    expect(await unchangedBytes(fixture), before);
    final rawProject = jsonDecode(
        await File('${fixture.root.path}/project.json').readAsString()) as Map;
    expect((rawProject['characters'] as List).single['foreign'], {
      'keep': [1, 'été']
    });
    final rawMap = jsonDecode(
            await File('${fixture.root.path}/maps/village.json').readAsString())
        as Map;
    expect((rawMap['entities'] as List).single['npc']['foreign'],
        {'also': 'unchanged'});
  });

  test(
      'partial deletion promotion recovers project map and Yarn through the existing journal',
      () async {
    var crash = true;
    final fixture =
        await CharacterDeletionFixture.create(faultInjector: (context) {
      if (crash &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.promotionIndex == 0) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(fixture.dispose);
    final before = await unchangedBytes(fixture);
    final planned = await fixture.plan();
    await expectLater(() => fixture.apply(planned, 'character-crash'),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    crash = false;
    final recovered = await fixture.api
        .recover(fixture.opened.projectHandle, operationId: 'character-crash');
    expect((recovered['receipt'] as Map)['status'], 'recovered');
    verifyResolved(await fixture.independent());
    expect(await unchangedBytes(fixture), before);
  });

  test(
      'late Yarn change after initial check refuses deletion before any promotion',
      () async {
    final fixture = await CharacterDeletionFixture.create();
    addTearDown(fixture.dispose);
    final planned = await fixture.plan();
    final confirmed = await fixture.api.confirm(fixture.opened.projectHandle,
        planId: planned['planId'] as String);
    final projectBefore =
        await File('${fixture.root.path}/project.json').readAsBytes();
    final mapBefore =
        await File('${fixture.root.path}/maps/village.json').readAsBytes();
    var initialPassed = false;
    await expectLater(
        () => fixture.api.applyMutation(fixture.opened.projectHandle,
                planId: planned['planId'] as String,
                operationId: 'character-late',
                confirmationToken: confirmed['confirmationToken'] as String,
                precondition: () async {
              initialPassed = true;
              await File('${fixture.root.path}/dialogues/intro.yarn').writeAsString(
                  'title: Start\n---\nChanged after the initial check.\n===\n');
            }),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
    expect(initialPassed, true);
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        projectBefore);
    expect(await File('${fixture.root.path}/maps/village.json').readAsBytes(),
        mapBefore);
  });
}
