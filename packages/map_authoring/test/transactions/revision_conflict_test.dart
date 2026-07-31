import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringRevisionSet', () {
    test('is deterministic across input order and JSON round trips', () {
      final mapA = AuthoringResourceRevision(
        resource: AuthoringResourceRef(kind: 'map', id: 'a'),
        revision: _revision('a'),
      );
      final mapB = AuthoringResourceRevision(
        resource: AuthoringResourceRef(kind: 'map', id: 'b'),
        revision: _revision('b'),
      );

      final first = AuthoringRevisionSet([mapB, mapA]);
      final second = AuthoringRevisionSet([mapA, mapB]);
      final decoded = AuthoringRevisionSet.fromJson(first.toJson());

      expect(first.toJson(), second.toJson());
      expect(first.fingerprint, second.fingerprint);
      expect(decoded.toJson(), first.toJson());
      expect(first.entries.map((entry) => entry.resource.id), ['a', 'b']);
    });

    test('supports explicit absent revisions for create and delete CAS', () {
      final create = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'map', id: 'created'),
        storageKey: 'maps/created.json',
        beforeBytes: null,
        afterBytes: utf8.encode('{"id":"created"}'),
      );
      final delete = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'map', id: 'deleted'),
        storageKey: 'maps/deleted.json',
        beforeBytes: utf8.encode('{"id":"deleted"}'),
        afterBytes: null,
      );
      final changes = AuthoringChangeSet(
        changes: [create, delete],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: create.resource,
            path: r'$',
            after: const {'id': 'created'},
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: delete.resource,
            path: r'$',
            before: const {'id': 'deleted'},
          ),
        ]),
      );

      final before = AuthoringRevisionSet.beforeChangeSet(changes);
      final after = AuthoringRevisionSet.afterChangeSet(changes);

      expect(before.revisionOf(create.resource), isNull);
      expect(before.revisionOf(delete.resource), delete.beforeRevision);
      expect(after.revisionOf(create.resource), create.afterRevision);
      expect(after.revisionOf(delete.resource), isNull);
    });

    test('rejects duplicate resources and malformed fingerprints', () {
      final resource = AuthoringResourceRef(kind: 'map', id: 'same');

      expect(
        () => AuthoringRevisionSet([
          AuthoringResourceRevision(
              resource: resource, revision: _revision('a')),
          AuthoringResourceRevision(
              resource: resource, revision: _revision('b')),
        ]),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRevision(
          resource: resource,
          revision: 'not-a-fingerprint',
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRevision(
          resource: AuthoringResourceRef(
            kind: 'map',
            id: 'same',
            revision: _revision('a'),
          ),
          revision: _revision('b'),
        ),
        throwsArgumentError,
      );
    });

    test('blocks mutation callback when any touched revision changed', () {
      final resourceA = AuthoringResourceRef(kind: 'map', id: 'a');
      final resourceB = AuthoringResourceRef(kind: 'map', id: 'b');
      final expected = AuthoringRevisionSet([
        AuthoringResourceRevision(
            resource: resourceA, revision: _revision('a')),
        AuthoringResourceRevision(
            resource: resourceB, revision: _revision('b')),
      ]);
      final current = AuthoringRevisionSet([
        AuthoringResourceRevision(
            resource: resourceA, revision: _revision('a')),
        AuthoringResourceRevision(
          resource: resourceB,
          revision: _revision('externally-changed'),
        ),
      ]);
      var mutations = 0;

      expect(
        () => expected.guard(current, () => mutations++),
        throwsA(
          isA<AuthoringRevisionConflict>()
              .having((error) => error.code, 'code', 'revision.conflict')
              .having(
                (error) => error.conflicts.single.resource.id,
                'resource',
                'b',
              ),
        ),
      );
      expect(mutations, 0);
    });

    test('treats unexpected presence and missing current entries as conflicts',
        () {
      final resource = AuthoringResourceRef(kind: 'map', id: 'new');
      final expectsAbsent = AuthoringRevisionSet([
        AuthoringResourceRevision(resource: resource, revision: null),
      ]);
      final unexpectedlyPresent = AuthoringRevisionSet([
        AuthoringResourceRevision(
          resource: resource,
          revision: _revision('present'),
        ),
      ]);

      expect(
        () => expectsAbsent.requireMatches(unexpectedlyPresent),
        throwsA(isA<AuthoringRevisionConflict>()),
      );
      expect(
        () =>
            unexpectedlyPresent.requireMatches(AuthoringRevisionSet(const [])),
        throwsA(isA<AuthoringRevisionConflict>()),
      );
    });
  });
}

String _revision(String value) => computeAuthoringBytesFingerprint(
      utf8.encode(value),
      logicalName: 'resource.json',
    );
