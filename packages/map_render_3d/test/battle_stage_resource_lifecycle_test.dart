import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a tight-budget swap waits for an obsolete in-flight import', () async {
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumResidentBytes: 36),
    );
    final first = _image();
    final next = _image();
    addTearDown(first.dispose);
    addTearDown(next.dispose);
    final entered = Completer<void>();
    final finish = Completer<void>();
    final failures = <Object>[];
    var imports = 0;
    final cache = BattleStageTextureCache(
      resourceBudget: budget,
      importer: (image) async {
        if (++imports == 1) {
          entered.complete();
          await finish.future;
        }
        return SpatialActorTexture.fromImage(image);
      },
      onError: (error, _) => failures.add(error),
    );
    addTearDown(cache.close);
    cache.sync({first});
    await entered.future;
    cache.sync({next});
    await Future<void>.delayed(Duration.zero);
    final importsBeforeCompletion = imports;
    final errorsBeforeCompletion = List.of(failures);
    finish.complete();
    await cache.settled;
    expect(importsBeforeCompletion, 1);
    expect(errorsBeforeCompletion, isEmpty);
    expect(failures, isEmpty);
    expect(cache.textureFor(first), isNull);
    expect(cache.textureFor(next), isNotNull);
    expect(cache.diagnostics.failedTextures, 0);
    expect(imports, 2);
    cache.close();
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
  });

  test(
    'source retirement does not wait for an unrelated pending import',
    () async {
      final first = _image();
      final second = _image();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final finishFirst = Completer<void>();
      final finishSecond = Completer<void>();
      var calls = 0;
      final cache = BattleStageTextureCache(
        importer: (image) async {
          await (++calls == 1 ? finishFirst.future : finishSecond.future);
          return SpatialActorTexture.fromImage(image);
        },
      );
      cache.sync({first, second});
      await Future<void>.delayed(Duration.zero);
      var secondSettled = false;
      final secondRequest = cache
          .sourceSettled(second)
          .then((_) => secondSettled = true);
      finishFirst.complete();
      await cache.sourceSettled(first);
      expect(secondSettled, isFalse);
      expect(cache.textureFor(first), isNotNull);
      finishSecond.complete();
      await secondRequest;
      cache.close();
    },
  );

  test(
    'close cancels a replacement waiting for an obsolete conversion',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 36),
      );
      final first = _image();
      final next = _image();
      addTearDown(first.dispose);
      final entered = Completer<void>();
      final finish = Completer<void>();
      var imports = 0;
      final failures = <Object>[];
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) async {
          imports++;
          entered.complete();
          await finish.future;
          return SpatialActorTexture.fromImage(image);
        },
        onError: (error, _) => failures.add(error),
      );
      cache.sync({first});
      await entered.future;
      cache.sync({next});
      next.dispose();
      cache.close();
      expect(budget.residentBytes, 36);
      expect(next.debugGetOpenHandleStackTraces(), hasLength(1));
      finish.complete();
      await cache.settled;
      expect(imports, 1);
      expect(failures, isEmpty);
      expect(cache.diagnostics.pendingTextures, 0);
      expect(next.debugGetOpenHandleStackTraces(), isEmpty);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.isDisposed, isFalse);
    },
  );

  test(
    'imports reserve shared bytes and retain source clone through conversion',
    () async {
      final budget = RuntimeResourceBudget();
      final sourceLease = await budget.acquire(residentBytes: 16);
      sourceLease.commit();
      final source = _image();
      final entered = Completer<ui.Image>();
      final finish = Completer<void>();
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) async {
          entered.complete(image);
          await finish.future;
          return SpatialActorTexture.fromImage(image);
        },
      );
      cache.sync({source});
      source.dispose();
      final borrowed = await entered.future;
      expect(borrowed.debugDisposed, isFalse);
      expect(budget.residentBytes, 52);
      expect(cache.diagnostics.residentBytes, 36);
      expect(budget.transientBytes, 16);
      finish.complete();
      await cache.settled;
      expect(borrowed.debugDisposed, isTrue);
      expect(cache.textureFor(source), isNotNull);
      expect(cache.diagnostics.completedImports, 1);
      expect(budget.transientBytes, 0);
      cache.sync({});
      expect(budget.residentBytes, 52);
      expect(cache.diagnostics.retiredTextures, 1);
      cache.releaseRetired();
      expect(budget.residentBytes, 16);
      cache.close();
      sourceLease.release();
      expect(budget.residentBytes, 0);
    },
  );

  test(
    'admission rejection never starts conversion and leaves no reservation',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 51),
      );
      final sourceLease = await budget.acquire(residentBytes: 16);
      sourceLease.commit();
      final source = _image();
      addTearDown(source.dispose);
      var imports = 0;
      final failures = <Object>[];
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) {
          imports++;
          return SpatialActorTexture.fromImage(image);
        },
        onError: (error, _) => failures.add(error),
      );
      cache.sync({source});
      await cache.settled;
      expect(imports, 0);
      expect(cache.diagnostics.failedTextures, 1);
      expect(failures.single, isA<RuntimeResourceAdmissionException>());
      expect(budget.residentBytes, 16);
      expect(budget.transientBytes, 0);
      cache.close();
      sourceLease.release();
      expect(budget.residentBytes, 0);
    },
  );

  test(
    'obsolete error cannot poison a replacement request for the same image',
    () async {
      final source = _image();
      addTearDown(source.dispose);
      final budget = RuntimeResourceBudget();
      final first = Completer<SpatialActorTexture>();
      var calls = 0;
      final failures = <Object>[];
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) {
          calls++;
          return calls == 1
              ? first.future
              : SpatialActorTexture.fromImage(image);
        },
        onError: (error, _) => failures.add(error),
      );
      cache.sync({source});
      await Future<void>.delayed(Duration.zero);
      cache.sync({});
      cache.sync({source});
      first.completeError(StateError('obsolete import'));
      await cache.settled;
      expect(calls, 2);
      expect(failures, isEmpty);
      expect(cache.diagnostics.failedTextures, 0);
      expect(cache.textureFor(source), isNotNull);
      expect(budget.residentBytes, 36);
      cache.close();
      expect(budget.residentBytes, 0);
    },
  );

  test(
    'close during conversion holds reservation until conversion finishes',
    () async {
      final source = _image();
      addTearDown(source.dispose);
      final budget = RuntimeResourceBudget();
      final finish = Completer<void>();
      late ui.Image owned;
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) async {
          owned = image;
          await finish.future;
          return SpatialActorTexture.fromImage(image);
        },
      );
      cache.sync({source});
      await Future<void>.delayed(Duration.zero);
      cache.close();
      expect(budget.residentBytes, 36);
      expect(owned.debugDisposed, isFalse);
      finish.complete();
      await cache.settled;
      expect(owned.debugDisposed, isTrue);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(cache.textureFor(source), isNull);
      expect(cache.diagnostics.completedImports, 0);
    },
  );

  test(
    'obsolete success is discarded while replacement stays pending',
    () async {
      final source = _image();
      addTearDown(source.dispose);
      final budget = RuntimeResourceBudget();
      final first = Completer<void>();
      final next = Completer<void>();
      var calls = 0;
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) async {
          calls++;
          await (calls == 1 ? first.future : next.future);
          return SpatialActorTexture.fromImage(image);
        },
      );
      cache.sync({source});
      await Future<void>.delayed(Duration.zero);
      cache.sync({});
      cache.sync({source});
      await Future<void>.delayed(Duration.zero);
      first.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cache.textureFor(source), isNull);
      expect(cache.diagnostics.completedImports, 0);
      expect(cache.diagnostics.pendingTextures, 1);
      expect(budget.residentBytes, 36);
      next.complete();
      await cache.settled;
      expect(cache.textureFor(source), isNotNull);
      cache.sync({source});
      await cache.settled;
      expect(calls, 2);
      cache.close();
      expect(budget.residentBytes, 0);
    },
  );

  test(
    'queued conversion borrows source safely and cancellation never imports it',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
      );
      final blocker = await budget.acquire();
      final source = _image();
      var imports = 0;
      final failures = <Object>[];
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) {
          imports++;
          return SpatialActorTexture.fromImage(image);
        },
        onError: (error, _) => failures.add(error),
      );
      cache.sync({source});
      source.dispose();
      expect(budget.pendingDecodes, 1);
      cache.close();
      blocker.release();
      await cache.settled;
      expect(imports, 0);
      expect(failures, isEmpty);
      expect(budget.pendingDecodes, 0);
      expect(budget.activeDecodes, 0);
      expect(budget.residentBytes, 0);
      expect(cache.diagnostics.pendingTextures, 0);
    },
  );

  test(
    'a tight-budget swap waits for mesh retirement before one new admission',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 36),
      );
      final first = _image();
      final next = _image();
      addTearDown(first.dispose);
      addTearDown(next.dispose);
      var imports = 0;
      final failures = <Object>[];
      final cache = BattleStageTextureCache(
        resourceBudget: budget,
        importer: (image) {
          imports++;
          return SpatialActorTexture.fromImage(image);
        },
        onError: (error, _) => failures.add(error),
      );
      cache.sync({first});
      await cache.settled;
      expect(imports, 1);
      cache.sync({next});
      await Future<void>.delayed(Duration.zero);
      expect(budget.residentBytes, 36);
      expect(cache.diagnostics.retiredTextures, 1);
      expect(cache.diagnostics.pendingTextures, 1);
      expect(cache.diagnostics.failedTextures, 0);
      expect(failures, isEmpty);
      expect(imports, 1);
      cache.releaseRetired();
      await cache.settled;
      expect(cache.textureFor(next), isNotNull);
      expect(imports, 2);
      expect(budget.residentBytes, 36);
      cache.sync({next});
      cache.releaseRetired();
      await cache.settled;
      expect(imports, 2);
      expect(failures, isEmpty);
      final cancelled = _image();
      cache.sync({cancelled});
      cancelled.dispose();
      expect(cancelled.debugGetOpenHandleStackTraces(), hasLength(1));
      cache.close();
      await cache.settled;
      expect(imports, 2);
      expect(cache.diagnostics.pendingTextures, 0);
      expect(cache.diagnostics.failedTextures, 0);
      expect(failures, isEmpty);
      expect(cancelled.debugGetOpenHandleStackTraces(), isEmpty);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
    },
  );

  test(
    'successive battles release reservations without disposing shared budget',
    () async {
      final budget = RuntimeResourceBudget();
      for (var battle = 0; battle < 4; battle++) {
        final first = _image();
        final next = _image();
        final cache = BattleStageTextureCache(resourceBudget: budget);
        cache.sync({first});
        await cache.settled;
        cache.sync({next});
        expect(cache.diagnostics.retiredTextures, 1);
        cache.releaseRetired();
        await cache.settled;
        expect(cache.diagnostics.activeTextures, 1);
        expect(cache.diagnostics.evictions, 1);
        cache.close();
        first.dispose();
        next.dispose();
        expect(budget.residentBytes, 0);
        expect(budget.transientBytes, 0);
        expect(budget.activeDecodes, 0);
        expect(budget.isDisposed, isFalse);
      }
    },
  );
}

ui.Image _image() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 2, 2), ui.Paint());
  final picture = recorder.endRecording();
  try {
    return picture.toImageSync(2, 2);
  } finally {
    picture.dispose();
  }
}
