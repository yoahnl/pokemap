import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringActionPlanner', () {
    test('plans a real-project change without writing fixture bytes', () async {
      final fixtureManifest = File(_fixtureManifestPath());
      final beforeFixtureBytes = await fixtureManifest.readAsBytes();
      final snapshot = _snapshot();
      final store = AuthoringPlanStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      var token = 0;
      final planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '$prefix${token++}',
        seedFactory: () => 73,
      );

      final plan = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: _draft,
        validateProjectedState: (snapshot, draft) {
          expect(snapshot.manifest.name, 'Planning Fixture');
          expect(draft.changeSet.changes, hasLength(1));
        },
      );

      expect(await fixtureManifest.readAsBytes(), beforeFixtureBytes);
      expect(plan.planId, 'plan_0');
      expect(plan.receiptId, 'receipt_1');
      expect(plan.seed, 73);
      expect(plan.baseRevision, snapshot.revision);
      expect(plan.changeSet.diff.entries, hasLength(1));
      expect(plan.changeSet.affectedResources.single.id, startsWith('map_'));
      expect(plan.referenceImpact, {
        'runtimeBlocking': false,
        'directDependents': <Object?>[],
      });
      expect(plan.artifacts.single.uri, 'artifact://preview/plan');
      expect(plan.toJson()['workspaceHandle'], 'workspace:fixture');
      expect(plan.toJson(), isNot(containsPair('projectHandle', anything)));
      expect(plan.toPlannedReceipt().status, AuthoringReceiptStatus.planned);
      expect(plan.toPlannedReceipt().afterRevision, plan.projectedRevision);
    });

    test('stores generated IDs seed diff impact and artifacts exactly once',
        () async {
      final snapshot = _snapshot();
      final store = AuthoringPlanStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      var builds = 0;
      final planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '${prefix}stable',
        seedFactory: () => 991,
      );

      final planned = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: (context) {
          builds++;
          return _draft(context);
        },
      );
      final first = store.resolve(
        planned.planId,
        currentProjectRevision: snapshot.revision,
      );
      final second = store.resolve(
        planned.planId,
        currentProjectRevision: snapshot.revision,
      );

      expect(builds, 1);
      expect(first, same(planned));
      expect(second, same(planned));
      expect(second.toJson(), first.toJson());
      expect(second.seed, 991);
      expect(
        second.preview['generatedId'],
        first.changeSet.affectedResources.single.id,
      );
      expect(second.toPlannedReceipt().toJson(),
          first.toPlannedReceipt().toJson());
    });

    test('validates projected state before publishing a plan', () async {
      final snapshot = _snapshot();
      final store = AuthoringPlanStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      final planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '${prefix}invalid',
        seedFactory: () => 1,
      );

      await expectLater(
        () => planner.plan(
          request: _request(snapshot.revision),
          snapshot: snapshot,
          build: _draft,
          validateProjectedState: (_, __) {
            throw const FormatException('invalid projected project');
          },
        ),
        throwsA(isA<FormatException>()),
      );
      expect(store.length, 0);
    });
  });

  group('AuthoringChangeSet', () {
    test('rejects duplicate resources and storage keys', () {
      final first = _change('first', 'maps/shared.json');
      final sameResource = _change('first', 'maps/other.json');
      final sameStorage = _change('second', 'maps/shared.json');

      expect(
        () => AuthoringChangeSet(
          changes: [first, sameResource],
          diff: _diffFor([first, sameResource]),
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringChangeSet(
          changes: [first, sameStorage],
          diff: _diffFor([first, sameStorage]),
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsafe storage keys and inconsistent fingerprints', () {
      for (final storageKey in [
        '../project.json',
        '/tmp/project.json',
        r'maps\outside.json',
        'C:/tmp/project.json',
        './maps/map.json',
        '.pokemap/authoring/private.json',
      ]) {
        expect(
          () => _change('unsafe', storageKey),
          throwsArgumentError,
          reason: storageKey,
        );
      }

      expect(
        () => AuthoringResourceChange(
          resource: AuthoringResourceRef(kind: 'map', id: 'wrong-hash'),
          storageKey: 'maps/wrong-hash.json',
          beforeBytes: utf8.encode('{"value":0}'),
          afterBytes: utf8.encode('{"value":1}'),
          beforeRevision: 'sha256:${List.filled(64, 'a').join()}',
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceChange(
          resource: AuthoringResourceRef(
            kind: 'map',
            id: 'stale-ref',
            revision: 'sha256:${List.filled(64, 'a').join()}',
          ),
          storageKey: 'maps/stale-ref.json',
          beforeBytes: utf8.encode('{"value":0}'),
          afterBytes: utf8.encode('{"value":1}'),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a diff that does not describe every changed resource', () {
      final change = _change('changed', 'maps/changed.json');
      final other = AuthoringResourceRef(kind: 'map', id: 'other');

      expect(
        () => AuthoringChangeSet(
          changes: [change],
          diff: AuthoringDiff([
            AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: other,
              path: r'$.name',
              before: 'Before',
              after: 'After',
            ),
          ]),
        ),
        throwsArgumentError,
      );
    });
  });
}

AuthoringMutationDraft _draft(AuthoringPlanningContext context) {
  final generatedId = context.generateId('map');
  final change = _change(generatedId, 'maps/$generatedId.json');
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [change],
      diff: _diffFor([change]),
    ),
    preview: {'generatedId': generatedId},
    referenceImpact: const {
      'runtimeBlocking': false,
      'directDependents': <Object?>[],
    },
    artifacts: [
      AuthoringArtifactRef(
        id: 'preview',
        mediaType: 'application/json',
        uri: 'artifact://preview/plan',
      ),
    ],
  );
}

AuthoringResourceChange _change(String id, String storageKey) {
  return AuthoringResourceChange(
    resource: AuthoringResourceRef(kind: 'map', id: id),
    storageKey: storageKey,
    beforeBytes: utf8.encode('{"id":"$id","name":"Before"}'),
    afterBytes: utf8.encode('{"id":"$id","name":"After"}'),
  );
}

AuthoringDiff _diffFor(Iterable<AuthoringResourceChange> changes) {
  return AuthoringDiff([
    for (final change in changes)
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: change.resource,
        path: r'$.name',
        before: 'Before',
        after: 'After',
      ),
  ]);
}

AuthoringRequest _request(String revision) {
  return AuthoringRequest(
    requestId: 'req-plan',
    actionId: 'maps.update',
    actionVersion: 1,
    workspaceHandle: 'workspace:fixture',
    parameters: const {'mapId': 'map-a'},
    expectedRevision: revision,
    idempotencyKey: 'idem-plan',
    dryRun: true,
  );
}

ProjectSnapshot _snapshot() {
  final revision = computeAuthoringBytesFingerprint(
    utf8.encode('planning snapshot'),
    logicalName: 'snapshot',
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_planning'),
    revision: revision,
    manifest: ProjectManifest(
      name: 'Planning Fixture',
      maps: const [],
      tilesets: const [],
    ),
    maps: const [],
    resourceFingerprints: {'project': revision},
  );
}

String _fixtureManifestPath() {
  return [
    Directory.current.parent.parent.path,
    'examples',
    'playable_runtime_host',
    'p3_narrative_smoke_slice',
    'project.json',
  ].join(Platform.pathSeparator);
}
