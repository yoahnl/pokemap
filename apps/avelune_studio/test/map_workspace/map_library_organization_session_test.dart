import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_library_organization_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'organization is single-flight and preserves groups and assignments',
    () async {
      final pending = Completer<String?>();
      var calls = 0, changes = 0;
      const proposedGroups = [
        ProjectMapGroup(
          id: 'folder',
          name: 'Dossier',
          type: MapGroupType.special,
        ),
      ];
      const assignments = [
        <String, Object?>{'mapId': 'a', 'groupId': 'folder'},
      ];
      final session = MapLibraryOrganizationSession(
        changed: () => changes++,
        action: () => ({groups, required assignments}) {
          calls++;
          expect(groups, same(proposedGroups));
          expect(assignments.single['mapId'], 'a');
          expect(assignments.single['groupId'], 'folder');
          return pending.future;
        },
      );
      addTearDown(session.dispose);
      final first = session.submit(
        groups: proposedGroups,
        assignments: assignments,
      );
      expect(session.busy, isTrue);
      expect(await session.submit(assignments: assignments), isNotNull);
      expect(calls, 1);
      pending.complete(null);
      expect(await first, isNull);
      expect(session.busy, isFalse);
      expect(session.error, isNull);
      expect(changes, 2);
    },
  );

  test('publication failure stays visible and can be retried', () async {
    var calls = 0;
    final session = MapLibraryOrganizationSession(
      changed: () {},
      action: () => ({groups, required assignments}) async {
        if (calls++ == 0) throw StateError('catalogue indisponible');
        return null;
      },
    );
    addTearDown(session.dispose);
    expect(
      await session.submit(assignments: const []),
      contains('catalogue indisponible'),
    );
    expect(session.error, contains('catalogue indisponible'));
    expect(session.busy, isFalse);
    expect(await session.submit(assignments: const []), isNull);
    expect(session.error, isNull);
    expect(calls, 2);
  });

  test(
    'closed organization ignores pending callbacks and cannot publish again',
    () async {
      final pending = Completer<String?>();
      var calls = 0, changes = 0;
      final session = MapLibraryOrganizationSession(
        changed: () => changes++,
        action: () => ({groups, required assignments}) {
          calls++;
          return pending.future;
        },
      );
      final first = session.submit(assignments: const []);
      session.dispose();
      pending.complete(null);
      expect(await first, contains('fermé'));
      expect(changes, 1);
      expect(await session.submit(assignments: const []), isNotNull);
      expect(calls, 1);
    },
  );
}
