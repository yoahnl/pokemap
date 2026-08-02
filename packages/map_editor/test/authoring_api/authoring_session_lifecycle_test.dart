import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  group('EditorAuthoringSessionLifecycle', () {
    test('switching A to B retains B in every attached participant', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final reads = _FakeLifecycleParticipant()..open('/canonical/a');
      final mutations = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, reads, mutations);

      await lifecycle.activate('/alias/a');
      reads.open('/canonical/b');
      mutations.open('/canonical/b');
      await lifecycle.activate('/alias/b');

      expect(lifecycle.activeRoot, '/canonical/b');
      expect(reads.liveRoots, equals(<String>{'/canonical/b'}));
      expect(mutations.liveRoots, equals(<String>{'/canonical/b'}));
      expect(
        reads.retainOnlyCalls,
        equals(<String>['/canonical/a', '/canonical/b']),
      );
      expect(
        mutations.retainOnlyCalls,
        equals(<String>['/canonical/a', '/canonical/b']),
      );
    });

    test('ten sequential roots leave only the last root alive', () async {
      final aliases = <String, String>{
        for (var index = 1; index <= 10; index += 1)
          '/alias/$index': '/canonical/$index',
      };
      final reader = _CanonicalReader(aliases);
      final reads = _FakeLifecycleParticipant();
      final mutations = _FakeLifecycleParticipant();
      final lifecycle = _lifecycle(reader, reads, mutations);

      for (var index = 1; index <= 10; index += 1) {
        reads.open('/canonical/$index');
        mutations.open('/canonical/$index');
        await lifecycle.activate('/alias/$index');
      }

      expect(lifecycle.activeRoot, '/canonical/10');
      expect(reads.liveRoots, equals(<String>{'/canonical/10'}));
      expect(mutations.liveRoots, equals(<String>{'/canonical/10'}));
      expect(reads.retainOnlyCalls, hasLength(10));
      expect(mutations.retainOnlyCalls, hasLength(10));
    });

    test('activation canonicalizes the requested project root', () async {
      final reader = _CanonicalReader({
        '/selected/project': '/real/project',
      });
      final participant = _FakeLifecycleParticipant()..open('/real/project');
      final lifecycle = _lifecycle(reader, participant);

      await lifecycle.activate('/selected/project');

      expect(reader.canonicalizeCalls, equals(['/selected/project']));
      expect(lifecycle.activeRoot, '/real/project');
      expect(participant.retainOnlyCalls, equals(['/real/project']));
    });

    test('activating the same canonical root twice is idempotent', () async {
      final reader = _CanonicalReader({
        '/alias/one': '/canonical/project',
        '/alias/two': '/canonical/project',
      });
      final participant = _FakeLifecycleParticipant()
        ..open('/canonical/project');
      final lifecycle = _lifecycle(reader, participant);

      await lifecycle.activate('/alias/one');
      await lifecycle.activate('/alias/two');

      expect(lifecycle.activeRoot, '/canonical/project');
      expect(participant.retainOnlyCalls, equals(['/canonical/project']));
    });

    test('closing the lifecycle repeatedly remains safe and empty', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
      });
      final reads = _FakeLifecycleParticipant()..open('/canonical/a');
      final mutations = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, reads, mutations);
      await lifecycle.activate('/alias/a');

      await lifecycle.closeAll();
      await lifecycle.closeAll();

      expect(lifecycle.activeRoot, isNull);
      expect(reads.liveRoots, isEmpty);
      expect(mutations.liveRoots, isEmpty);
    });

    test('discarding a candidate never closes the active root', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');

      await lifecycle.discard('/alias/a');
      participant.open('/canonical/b');
      await lifecycle.discard('/alias/b');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(participant.liveRoots, equals(<String>{'/canonical/a'}));
      expect(participant.closeProjectCalls, equals(['/canonical/b']));
    });

    test('preparing a candidate authorizes only one non-active root', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
        '/alias/c': '/canonical/c',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');

      await lifecycle.prepareCandidate('/alias/b');
      await lifecycle.prepareCandidate('/alias/c');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(lifecycle.candidateRoot, '/canonical/c');
      expect(
        participant.allowCandidateCalls,
        equals(['/canonical/b', '/canonical/c']),
      );
      expect(participant.closeProjectCalls, contains('/canonical/b'));
    });

    test('reactivating the active root retires an outstanding candidate',
        () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');
      await lifecycle.prepareCandidate('/alias/b');
      participant.open('/canonical/b');

      await lifecycle.activate('/alias/a');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(lifecycle.candidateRoot, isNull);
      expect(participant.liveRoots, equals(<String>{'/canonical/a'}));
      expect(
          participant.retainOnlyCalls,
          equals([
            '/canonical/a',
            '/canonical/a',
          ]));
    });

    test('preparing the active root retires an outstanding candidate',
        () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');
      await lifecycle.prepareCandidate('/alias/b');
      participant.open('/canonical/b');

      await lifecycle.prepareCandidate('/alias/a');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(lifecycle.candidateRoot, isNull);
      expect(participant.liveRoots, equals(<String>{'/canonical/a'}));
    });

    test('one participant failure does not skip cleanup of the others',
        () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final failing = _FakeLifecycleParticipant()..open('/canonical/a');
      final healthy = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, failing, healthy);
      await lifecycle.activate('/alias/a');
      failing
        ..open('/canonical/b')
        ..retainOnlyError = StateError('cannot close A');
      healthy.open('/canonical/b');

      await expectLater(
        lifecycle.activate('/alias/b'),
        throwsA(isA<StateError>()),
      );

      // Admission switches fail closed to B even when one retirement reports
      // an error, so stale work cannot reopen A behind the editor state.
      expect(lifecycle.activeRoot, '/canonical/b');
      expect(failing.retainOnlyCalls.last, '/canonical/b');
      expect(healthy.retainOnlyCalls.last, '/canonical/b');
      expect(healthy.liveRoots, equals(<String>{'/canonical/b'}));
    });

    test('an occupied participant delays completion of activation', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final busy = _FakeLifecycleParticipant()..open('/canonical/a');
      final other = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, busy, other);
      await lifecycle.activate('/alias/a');
      busy.open('/canonical/b');
      other.open('/canonical/b');
      final releaseBusyParticipant = Completer<void>();
      busy.retainOnlyBlocker = releaseBusyParticipant;
      var completed = false;

      final switching = lifecycle.activate('/alias/b').whenComplete(() {
        completed = true;
      });
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(lifecycle.activeRoot, '/canonical/a');

      releaseBusyParticipant.complete();
      await switching;

      expect(completed, isTrue);
      expect(lifecycle.activeRoot, '/canonical/b');
      expect(busy.liveRoots, equals(<String>{'/canonical/b'}));
      expect(other.liveRoots, equals(<String>{'/canonical/b'}));
    });

    test('a discarded late opening closes and returns a typed stale failure',
        () async {
      final active = Directory(
        '${Directory.current.parent.parent.path}/examples/'
        'playable_runtime_host/golden_fangame_slice',
      );
      final candidate = Directory(
        '${Directory.current.parent.parent.path}/selbrume',
      );
      final candidateRoot = await candidate.resolveSymbolicLinks();
      final reader = _GatedProjectReader(candidateRoot);
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
        ..attach(queries);
      addTearDown(lifecycle.closeAll);
      await lifecycle.activate(active.path);

      await lifecycle.prepareCandidate(candidate.path);
      final opening = queries.open(candidate.path);
      await reader.started.future;
      final discarding = lifecycle.discard(candidate.path);
      await Future<void>.delayed(Duration.zero);
      reader.release.complete();

      await expectLater(
        opening,
        throwsA(isA<EditorAuthoringStaleSessionException>()),
      );
      await discarding;
      expect(lifecycle.activeRoot, await active.resolveSymbolicLinks());
      expect(queries.diagnostics.liveSessions, 0);
      expect(queries.diagnostics.openingSessions, 0);
      expect(queries.diagnostics.retiringSessions, 0);
      expect(queries.diagnostics.closeCount, 1);
    });

    test('repository providers attach both editor-private adapters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authoringMutationAdapterProvider);
      final lifecycle = container.read(
        editorAuthoringSessionLifecycleProvider,
      );

      expect(lifecycle.participantCount, 2);
    });
  });
}

EditorAuthoringSessionLifecycle _lifecycle(
  ProjectFileReader reader,
  _FakeLifecycleParticipant first, [
  _FakeLifecycleParticipant? second,
]) {
  final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
    ..attach(first);
  if (second != null) lifecycle.attach(second);
  return lifecycle;
}

final class _CanonicalReader implements ProjectFileReader {
  _CanonicalReader(this.canonicalRoots);

  final Map<String, String> canonicalRoots;
  final List<String> canonicalizeCalls = <String>[];

  @override
  Future<String> canonicalizeDirectory(String path) async {
    canonicalizeCalls.add(path);
    return canonicalRoots[path] ?? path;
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    throw UnsupportedError('Lifecycle tests never read project bytes.');
  }
}

final class _GatedProjectReader implements ProjectFileReader {
  _GatedProjectReader(this.gatedRoot);

  final String gatedRoot;
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  static const _delegate = EditorProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (projectRoot == gatedRoot && !started.isCompleted) {
      started.complete();
      await release.future;
    }
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

final class _FakeLifecycleParticipant
    implements EditorAuthoringLifecycleParticipant {
  final Set<String> liveRoots = <String>{};
  final List<String> retainOnlyCalls = <String>[];
  final List<String> closeProjectCalls = <String>[];
  final List<String> allowCandidateCalls = <String>[];
  int closeAllCalls = 0;
  Object? retainOnlyError;
  Completer<void>? retainOnlyBlocker;

  void open(String canonicalRoot) {
    liveRoots.add(canonicalRoot);
  }

  @override
  Future<void> allowCandidate(String canonicalRoot) async {
    allowCandidateCalls.add(canonicalRoot);
  }

  @override
  Future<void> retainOnly(String canonicalRoot) async {
    retainOnlyCalls.add(canonicalRoot);
    final blocker = retainOnlyBlocker;
    if (blocker != null) await blocker.future;
    final error = retainOnlyError;
    if (error != null) throw error;
    liveRoots.removeWhere((root) => root != canonicalRoot);
  }

  @override
  Future<void> closeProject(String canonicalRoot) async {
    closeProjectCalls.add(canonicalRoot);
    liveRoots.remove(canonicalRoot);
  }

  @override
  Future<void> closeAll() async {
    closeAllCalls += 1;
    liveRoots.clear();
  }
}
