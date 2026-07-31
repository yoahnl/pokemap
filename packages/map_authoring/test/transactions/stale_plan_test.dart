import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringPlanStore', () {
    late DateTime now;
    late AuthoringPlanStore store;
    late ProjectSnapshot snapshot;
    late AuthoringActionPlanner planner;

    setUp(() {
      now = DateTime.utc(2026, 7, 31, 12);
      store = AuthoringPlanStore(
        clock: () => now,
        ttl: const Duration(minutes: 5),
      );
      snapshot = _snapshot('base');
      planner = AuthoringActionPlanner(
        store: store,
        tokenFactory: (prefix) => '${prefix}stale-test',
        seedFactory: () => 17,
      );
    });

    test('refuses a plan after an external project revision change', () async {
      final plan = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: _draft,
      );

      expect(
        () => store.resolve(
          plan.planId,
          currentProjectRevision: _snapshot('changed').revision,
        ),
        throwsA(
          isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.stale')
              .having(
                (error) => error.remediation,
                'remediation',
                contains('Create a new plan from the latest project revision.'),
              ),
        ),
      );
    });

    test('refuses an expired plan with useful remediation', () async {
      final plan = await planner.plan(
        request: _request(snapshot.revision),
        snapshot: snapshot,
        build: _draft,
      );
      now = now.add(const Duration(minutes: 5));

      expect(
        () => store.resolve(
          plan.planId,
          currentProjectRevision: snapshot.revision,
        ),
        throwsA(
          isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.expired')
              .having(
                (error) => error.remediation,
                'remediation',
                contains('Create a new plan before applying the mutation.'),
              ),
        ),
      );
    });

    test('rejects a stale expected revision before invoking the builder', () {
      var built = false;

      expect(
        () => planner.plan(
          request: _request(_snapshot('old-client').revision),
          snapshot: snapshot,
          build: (context) {
            built = true;
            return _draft(context);
          },
        ),
        throwsA(
          isA<AuthoringPlanException>().having(
            (error) => error.code,
            'code',
            'plan.stale',
          ),
        ),
      );
      expect(built, isFalse);
      expect(store.length, 0);
    });

    test('reports unknown opaque plan identifiers without leaking state', () {
      expect(
        () => store.resolve(
          'plan_missing',
          currentProjectRevision: snapshot.revision,
        ),
        throwsA(
          isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.unknown')
              .having(
                (error) => error.toString(),
                'safe error',
                isNot(contains(DirectoryLikeAbsolutePath.marker)),
              ),
        ),
      );
    });
  });
}

abstract final class DirectoryLikeAbsolutePath {
  static const marker = '/Users/';
}

AuthoringMutationDraft _draft(AuthoringPlanningContext context) {
  final id = context.generateId('map');
  final resource = AuthoringResourceRef(kind: 'map', id: id);
  final change = AuthoringResourceChange(
    resource: resource,
    storageKey: 'maps/$id.json',
    beforeBytes: utf8.encode('{"name":"Before"}'),
    afterBytes: utf8.encode('{"name":"After"}'),
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [change],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: r'$.name',
          before: 'Before',
          after: 'After',
        ),
      ]),
    ),
  );
}

AuthoringRequest _request(String expectedRevision) {
  return AuthoringRequest(
    requestId: 'req-stale',
    actionId: 'maps.update',
    actionVersion: 1,
    workspaceHandle: 'workspace:test',
    expectedRevision: expectedRevision,
    idempotencyKey: 'idem-stale',
    dryRun: true,
  );
}

ProjectSnapshot _snapshot(String value) {
  final revision = computeAuthoringBytesFingerprint(
    utf8.encode(value),
    logicalName: 'snapshot',
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_stale'),
    revision: revision,
    manifest: ProjectManifest(
      name: 'Stale Plan Fixture',
      maps: const [],
      tilesets: const [],
    ),
    maps: const [],
    resourceFingerprints: {'project': revision},
  );
}
