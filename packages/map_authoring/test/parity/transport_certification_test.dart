import 'dart:io';

import 'package:map_authoring/map_authoring.dart' show CatalogStorageStore;
import 'package:map_authoring/transport_certification.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('checks a changed persisted value including explicit JSON null',
      () async {
    final root = await Directory.systemTemp.createTemp('pmcp085-test-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/project.json')
      ..writeAsStringSync('{"items":[{"enabled":false}]}');
    final step = AuthoringTransportStep.fromJson({
      'actionId': 'example.update',
      'actionVersion': 1,
      'parameters': <String, Object?>{},
      'observations': [
        {
          'path': 'project.json',
          'at': ['items', 0, 'enabled'],
          'equals': null,
        },
      ],
    });

    final before = await step.observe(root);
    expect(() => step.verify(before, before), throwsFormatException);
    await file.writeAsString('{"items":[{}]}');
    await expectLater(
      () async => step.verify(before, await step.observe(root)),
      throwsFormatException,
    );
    await file.writeAsString('{"items":[{"enabled":null}]}');
    final after = await step.observe(root);
    expect(() => step.verify(before, after), returnsNormally);
    expect(() => step.verify(after, after), throwsFormatException);
  });

  test('rejects observations outside the project and inside receipts', () {
    for (final path in [
      '../project.json',
      '/tmp/file',
      'a/../b',
      '.pokemap/authoring/history.json',
    ]) {
      expect(
        () => AuthoringTransportObservation.fromJson({
          'path': path,
          'exists': true,
        }),
        throwsFormatException,
      );
    }
  });

  test('observes the definition referenced by the current catalog head',
      () async {
    final temporary = await Directory.systemTemp.createTemp('pmcp085-catalog-');
    addTearDown(() => temporary.delete(recursive: true));
    final parent = await temporary.resolveSymbolicLinks();
    final root = await Directory('$parent/project').create();
    final store = await CatalogStorageStore.open(
      projectRoot: root.path,
      trustedAdmissionDirectory: Directory('$parent/admissions'),
    );
    final key = CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'tree');
    final observation = AuthoringTransportObservation.fromJson({
      'path': CatalogStorageStore.headStorageKey,
      'catalogDefinition': key.toJson(),
      'at': ['name'],
      'equals': 'Canopy oak',
    });

    CatalogStorageBuild generation(String name) =>
        CatalogStorageBuilder().build([
          CatalogDefinitionUnit(key: key, payload: {'name': name})
        ]);

    expect(await observation.read(root), {'present': false});
    final previous =
        await store.publish(generation('Tree'), expectedRootRevision: null);
    final before = await observation.read(root);
    expect(before, {'present': true, 'value': 'Tree'});
    expect(() => observation.verify(before, before), throwsFormatException);

    await store.publish(generation('Canopy oak'),
        expectedRootRevision: previous.rootRevision);
    final after = await observation.read(root);
    expect(after, {'present': true, 'value': 'Canopy oak'});
    expect(() => observation.verify(before, after), returnsNormally);
  });

  test('rejects catalog definition observations on unrelated file paths', () {
    expect(
      () => AuthoringTransportObservation.fromJson({
        'path': 'project.json',
        'catalogDefinition': {'kind': 'model3d', 'id': 'tree'},
        'exists': true,
      }),
      throwsFormatException,
    );
  });

  test('admits only explicit supported revision scopes', () {
    final step = {
      'actionId': 'example.update',
      'actionVersion': 1,
      'parameters': <String, Object?>{},
      'observations': [
        {'path': 'project.json', 'exists': true},
      ],
    };
    expect(
      AuthoringTransportStep.fromJson(step).revisionScope,
      AuthoringTransportRevisionScope.auto,
    );
    expect(
      AuthoringTransportStep.fromJson({...step, 'revisionScope': 'project'})
          .revisionScope,
      AuthoringTransportRevisionScope.project,
    );
    for (final scope in ['invalid', null]) {
      expect(
        () =>
            AuthoringTransportStep.fromJson({...step, 'revisionScope': scope}),
        throwsFormatException,
      );
    }
  });

  test('stages a bounded fixture file and rejects links and supplied handles',
      () async {
    final temporary = await Directory.systemTemp.createTemp('pmcp085-input-');
    addTearDown(() => temporary.delete(recursive: true));
    final root = Directory(await temporary.resolveSymbolicLinks());
    final fixture = File('${root.path}/draft.json')
      ..writeAsStringSync('{"id":"draft"}');
    await Link('${root.path}/linked.json').create(fixture.path);
    final artifact = AuthoringTransportArtifact.fromJson({
      'path': 'draft.json',
      'mediaType': 'application/json',
    });
    final resolved = await resolveAuthoringArtifact(root, artifact);
    expect(resolved.reference.byteLength, await fixture.length());
    expect(resolved.reference.mediaType, 'application/json');
    final link = AuthoringTransportArtifact.fromJson({
      'path': 'linked.json',
      'mediaType': 'application/json',
    });
    await expectLater(
        resolveAuthoringArtifact(root, link), throwsFormatException);
    expect(
      () => AuthoringTransportStep.fromJson({
        'actionId': 'smart_tile.preset.draft.import',
        'actionVersion': 1,
        'parameters': {'artifactHandle': resolved.reference.handle},
        'artifact': {'path': artifact.path, 'mediaType': artifact.mediaType},
        'observations': [
          {'path': 'project.json', 'exists': true},
        ],
      }),
      throwsFormatException,
    );
  });

  test('binds independent handles into existing typed parameter slots', () {
    final parameters = {
      'entries': [
        {'id': 'one'},
        {'id': 'two'},
      ],
    };
    final first = {
      'path': 'inputs/one.json',
      'mediaType': 'application/json',
      'parameterPath': ['entries', 0, 'artifactHandle'],
    };
    final second = {
      'path': 'inputs/two.json',
      'mediaType': 'application/json',
      'parameterPath': ['entries', 1, 'artifactHandle'],
    };
    final spec = {
      'actionId': 'asset.import_batch',
      'actionVersion': 1,
      'parameters': parameters,
      'observations': [
        {'path': 'project.json', 'exists': true},
      ],
    };
    final step = AuthoringTransportStep.fromJson({
      ...spec,
      'artifacts': [first, second],
    });
    expect(step.bindArtifactHandles(['handle-one', 'handle-two']), {
      'entries': [
        {'id': 'one', 'artifactHandle': 'handle-one'},
        {'id': 'two', 'artifactHandle': 'handle-two'},
      ],
    });
    expect(parameters['entries']!.first, {'id': 'one'});
    expect(
        () => step.bindArtifactHandles(['handle-one']), throwsFormatException);
    expect(
      () => AuthoringTransportStep.fromJson({
        ...spec,
        'artifacts': [first, first]
      }),
      throwsFormatException,
    );
    expect(
      () => AuthoringTransportStep.fromJson({
        ...spec,
        'artifacts': [
          {
            ...first,
            'parameterPath': ['entries', 2, 'artifactHandle']
          }
        ],
      }),
      throwsFormatException,
    );
  });

  test('only explicit previews can prove an unchanged preimage',
      () {
    final json = {
      'actionId': 'presentation.preset.delete_plan',
      'actionVersion': 1,
      'parameters': {'presetId': 'example'},
      'planOnly': true,
      'observations': [
        {'path': 'project.json', 'exists': true},
      ],
    };
    final present = [
      {'present': true, 'value': null}
    ];
    final absent = [
      {'present': false}
    ];
    for (final action in const [
      'presentation.preset.import_plan',
      'presentation.preset.delete_plan',
      'characterStudio.character.deletePlan',
      'characterStudio.portraitState.deletePlan',
      'characterStudio.animationDefinition.deletePlan',
    ]) {
      final preview = {...json, 'actionId': action};
      final step = AuthoringTransportStep.fromJson(preview);
      expect(() => step.verify(present, present), returnsNormally);
      expect(() => step.verify(absent, present), throwsFormatException);
      expect(
        () => AuthoringTransportStep.fromJson({...preview, 'planOnly': false}),
        throwsFormatException,
      );
    }
    expect(
      () =>
          AuthoringTransportStep.fromJson({...json, 'actionId': 'fact.create'}),
      throwsFormatException,
    );
    expect(
      () => AuthoringTransportStep.fromJson({...json, 'confirm': true}),
      throwsFormatException,
    );
  });

  test('distinguishes missing, default, and scoped catalog preparation', () {
    final scenario = {
      'id': 'catalog',
      'projectRoot': 'fixture',
      'steps': [
        {
          'actionId': 'fact.create',
          'actionVersion': 1,
          'parameters': <String, Object?>{},
          'observations': [
            {'path': 'project.json', 'exists': true},
          ],
        },
      ],
    };
    AuthoringTransportScenario parse(Map<String, Object?> value) =>
        AuthoringTransportScenario.parse({
          'schemaVersion': 1,
          'scenarios': [value]
        }).single;
    expect(parse(scenario).catalogPreparation, isNull);
    expect(parse(scenario).reopen, isFalse);
    expect(parse({...scenario, 'reopen': true}).reopen, isTrue);
    expect(
      () => parse({...scenario, 'reopen': 'true'}),
      throwsFormatException,
    );
    expect(
      parse({...scenario, 'catalogPreparation': <String>[]}).catalogPreparation,
      isEmpty,
    );
    expect(
      parse({
        ...scenario,
        'catalogPreparation': ['resourceIndexes']
      }).catalogPreparation,
      ['resourceIndexes'],
    );
    expect(
      () => parse({
        ...scenario,
        'catalogPreparation': ['resourceIndexes', 'resourceIndexes']
      }),
      throwsFormatException,
    );
  });
}
