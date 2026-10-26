import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_renderer_initialization.dart';

void main() {
  test(
    'concurrent renderer users share the backend until shaders are loaded',
    () async {
      var creations = 0;
      var activeBackend = 0;
      final readyBackends = <int>{};
      final loading = Completer<void>();
      final initializer = SpatialRendererInitialization(
        initialize: () async {
          final backend = ++creations;
          activeBackend = backend;
          await loading.future;
          readyBackends.add(backend);
        },
      );
      final viewport = initializer.initialize();
      final actors = initializer.initialize();
      final modelPreview = initializer.initialize();
      expect(identical(viewport, actors), isTrue);
      expect(identical(actors, modelPreview), isTrue);
      expect(creations, 1);
      expect(readyBackends, isEmpty);
      loading.complete();
      await Future.wait([viewport, actors, modelPreview]);
      expect(readyBackends, contains(activeBackend));
      expect(initializer.initialize(), same(viewport));
      await initializer.initialize();
      expect(creations, 1);
      expect(activeBackend, 1);
    },
  );

  test(
    'failed shader initialization propagates to all users and can retry',
    () async {
      var attempts = 0;
      final failure = StateError('shader asset load failed');
      final loading = Completer<void>();
      final initializer = SpatialRendererInitialization(
        initialize: () {
          attempts++;
          return attempts == 1 ? loading.future : Future.value();
        },
      );
      final first = initializer.initialize();
      final second = initializer.initialize();
      final observed = expectLater(
        Future.wait([first, second]),
        throwsA(same(failure)),
      );
      loading.completeError(failure);
      await observed;
      expect(attempts, 1);
      await initializer.initialize();
      await initializer.initialize();
      expect(attempts, 2);
    },
  );

  test(
    'synchronous initialization failures do not poison future attempts',
    () async {
      var attempts = 0;
      final initializer = SpatialRendererInitialization(
        initialize: () {
          attempts++;
          if (attempts == 1) throw StateError('GPU unavailable');
          return Future.value();
        },
      );
      await expectLater(initializer.initialize(), throwsStateError);
      await initializer.initialize();
      expect(attempts, 2);
    },
  );
}
