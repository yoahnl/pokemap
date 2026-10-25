import 'dart:async';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:avelune_studio/features/rendering/application/studio_rendering_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => AveluneFrameRate.setLimit(60));
  tearDown(() => AveluneFrameRate.setLimit(60));

  test('startup reads once and applies the persisted global limit', () async {
    final store = _Store(value: 90);
    final preferences = StudioRenderingPreferences(store);
    addTearDown(preferences.dispose);

    final first = preferences.load();
    final second = preferences.load();
    await Future.wait([first, second]);

    expect(store.reads, 1);
    expect(preferences.loaded, isTrue);
    expect(preferences.limit, 90);
    expect(AveluneFrameRate.limit, 90);
    expect(store.writes, isEmpty);
  });

  test('missing preferences use sixty frames per second', () async {
    final preferences = StudioRenderingPreferences(_Store());
    addTearDown(preferences.dispose);

    await preferences.load();

    expect(preferences.limit, 60);
    expect(preferences.error, isNull);
  });

  test('a changed limit is visible while persistence is pending', () async {
    final store = _Store(controlWrites: true);
    final preferences = StudioRenderingPreferences(store);
    addTearDown(preferences.dispose);
    await preferences.load();

    final saving = preferences.setLimit(45);
    expect(preferences.limit, 45);
    expect(AveluneFrameRate.limit, 45);
    expect(preferences.saving, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(store.writes, [45]);

    store.pending.single.complete();
    await saving;

    expect(preferences.saving, isFalse);
    expect(preferences.error, isNull);
    expect(store.reads, 1);
  });

  test('failed persistence restores the last durable limit', () async {
    final store = _Store(value: 90, controlWrites: true);
    final preferences = StudioRenderingPreferences(store);
    addTearDown(preferences.dispose);
    await preferences.load();

    final saving = preferences.setLimit(30);
    final rejected = expectLater(saving, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    store.pending.single.completeError(StateError('Disk unavailable'));
    await rejected;

    expect(preferences.limit, 90);
    expect(AveluneFrameRate.limit, 90);
    expect(preferences.saving, isFalse);
    expect(preferences.error, isNotNull);
    expect(store.value, 90);
  });

  test('repeating a pending choice waits for the same durable write', () async {
    final store = _Store(controlWrites: true);
    final preferences = StudioRenderingPreferences(store);
    addTearDown(preferences.dispose);
    await preferences.load();
    final first = preferences.setLimit(45);
    final firstRejected = first.then((_) => false, onError: (Object _) => true);
    var completed = false;
    final repeated = preferences.setLimit(45).whenComplete(() {
      completed = true;
    });
    final repeatedRejected = repeated.then(
      (_) => false,
      onError: (Object _) => true,
    );
    await Future<void>.delayed(Duration.zero);
    final completedBeforeWrite = completed;
    store.pending.single.completeError(StateError('Disk unavailable'));
    final failures = await Future.wait([firstRejected, repeatedRejected]);

    expect(completedBeforeWrite, isFalse);
    expect(store.writes, [45]);
    expect(failures, [true, true]);
    expect(preferences.limit, 60);
  });

  test(
    'rapid changes write in order without reverting the latest preview',
    () async {
      final store = _Store(controlWrites: true);
      final preferences = StudioRenderingPreferences(store);
      addTearDown(preferences.dispose);
      await preferences.load();

      final first = preferences.setLimit(30);
      final second = preferences.setLimit(120);
      expect(preferences.limit, 120);
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [30]);
      store.pending[0].complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, [30, 120]);
      expect(preferences.limit, 120);
      expect(preferences.saving, isTrue);
      store.pending[1].complete();
      await second;

      expect(store.value, 120);
      expect(preferences.saving, isFalse);
      expect(store.reads, 1);
    },
  );

  test(
    'a newer failure rolls back to the preceding successful write',
    () async {
      final store = _Store(controlWrites: true);
      final preferences = StudioRenderingPreferences(store);
      addTearDown(preferences.dispose);
      await preferences.load();

      final first = preferences.setLimit(45);
      final second = preferences.setLimit(90);
      final rejected = expectLater(second, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      store.pending[0].complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      store.pending[1].completeError(StateError('Disk unavailable'));
      await rejected;

      expect(preferences.limit, 45);
      expect(AveluneFrameRate.limit, 45);
      expect(store.value, 45);
    },
  );

  test(
    'same value does not write and unsupported values are rejected',
    () async {
      final store = _Store();
      final preferences = StudioRenderingPreferences(store);
      addTearDown(preferences.dispose);
      await preferences.load();

      await preferences.setLimit(60);
      await expectLater(preferences.setLimit(59), throwsArgumentError);

      expect(store.writes, isEmpty);
      expect(preferences.limit, 60);
      expect(AveluneFrameRate.limit, 60);
    },
  );

  test(
    'load failure is visible and does not overwrite persisted bytes',
    () async {
      final store = _Store(readError: const FormatException('Invalid file'));
      final preferences = StudioRenderingPreferences(store);
      addTearDown(preferences.dispose);

      await preferences.load();

      expect(preferences.loaded, isTrue);
      expect(preferences.limit, 60);
      expect(preferences.error, isNotNull);
      expect(store.writes, isEmpty);
    },
  );

  test(
    'each supported choice persists through the same loaded controller',
    () async {
      final store = _Store();
      final preferences = StudioRenderingPreferences(store);
      addTearDown(preferences.dispose);
      await preferences.load();

      for (final value in [30, 45, 60, 90, 120]) {
        await preferences.setLimit(value);
        expect(AveluneFrameRate.limit, value);
      }

      expect(store.reads, 1);
      expect(store.writes, [30, 45, 60, 90, 120]);
    },
  );
}

final class _Store implements StudioRenderingPreferencesStore {
  _Store({this.value, this.controlWrites = false, this.readError});

  int? value;
  final bool controlWrites;
  final Object? readError;
  int reads = 0;
  final writes = <int>[];
  final pending = <Completer<void>>[];

  @override
  Future<int?> load() async {
    reads++;
    if (readError case final error?) throw error;
    return value;
  }

  @override
  Future<void> save(int limit) async {
    writes.add(limit);
    if (controlWrites) {
      final completion = Completer<void>();
      pending.add(completion);
      await completion.future;
    }
    value = limit;
  }
}
