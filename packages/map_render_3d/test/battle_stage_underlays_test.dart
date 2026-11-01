import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/battle_stage_underlays.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('doubles ordering keeps shadows behind all actor bundles', () {
    final parts = <({String label, BattleStageDrawOrder order})>[];
    for (var actor = 0; actor < 4; actor++) {
      for (var part = -1; part < 3; part++) {
        parts.add((
          label: '$actor:$part',
          order: BattleStageDrawOrder(
            shadow: part == -1,
            actorDepth: actor < 2 ? 10 : 5,
            actorIndex: actor,
            partIndex: part,
          ),
        ));
      }
    }
    parts.shuffle();
    parts.sort((a, b) => a.order.compareTo(b.order));
    expect(parts.map((part) => part.label), [
      '0:-1',
      '1:-1',
      '2:-1',
      '3:-1',
      '0:0',
      '0:1',
      '0:2',
      '1:0',
      '1:1',
      '1:2',
      '2:0',
      '2:1',
      '2:2',
      '3:0',
      '3:1',
      '3:2',
    ]);
  });

  test('generated mask has a soft halo and reuses its owned source', () async {
    final budget = RuntimeResourceBudget();
    final cache = BattleStageShadowMaskCache(resourceBudget: budget);
    const ellipse = ui.Size(40, 4);
    cache.sync({ellipse});
    await cache.settled;
    final image = cache.imageFor(ellipse)!;
    expect(image.width, 52);
    expect(image.height, 16);
    expect(budget.residentBytes, 52 * 16 * 4);
    expect(budget.transientBytes, 0);
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    final center = bytes[(8 * 52 + 26) * 4 + 3];
    final halo = bytes[(4 * 52 + 26) * 4 + 3];
    expect(center, greaterThan(halo));
    expect(halo, greaterThan(0));
    expect(center, lessThan(255));
    cache.sync({ellipse});
    await cache.settled;
    expect(cache.imageFor(ellipse), same(image));
    expect(cache.generatedMasks, 1);
    cache.close(imports: (_) => Future.value());
    await cache.settled;
    expect(image.debugDisposed, isTrue);
    expect(budget.residentBytes, 0);
  });

  test('source retirement waits for conversion clones to settle', () async {
    final budget = RuntimeResourceBudget();
    final cache = BattleStageShadowMaskCache(resourceBudget: budget);
    const ellipse = ui.Size(12, 2);
    cache.sync({ellipse});
    await cache.settled;
    final image = cache.imageFor(ellipse)!;
    final imports = Completer<void>();
    cache.sync({});
    cache.releaseRetiredAfter((_) => imports.future);
    expect(cache.activeMasks, 0);
    expect(image.debugDisposed, isFalse);
    expect(budget.residentBytes, greaterThan(0));
    imports.complete();
    await cache.settled;
    expect(image.debugDisposed, isTrue);
    expect(budget.residentBytes, 0);
    cache.close(imports: (_) => Future.value());
  });

  test(
    'replacement mask waits for retirement under a tight shared budget',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(
          maximumResidentBytes: 26 * 14 * 4,
        ),
      );
      final errors = <Object>[];
      final cache = BattleStageShadowMaskCache(
        resourceBudget: budget,
        onError: (error, _) => errors.add(error),
      );
      cache.sync({const ui.Size(12, 2)});
      await cache.settled;
      final previous = cache.imageFor(const ui.Size(12, 2))!;
      final imports = Completer<void>();
      cache.sync({const ui.Size(14, 2)});
      cache.releaseRetiredAfter((_) => imports.future);
      await Future<void>.delayed(Duration.zero);
      expect(cache.generatedMasks, 1);
      expect(previous.debugDisposed, isFalse);
      imports.complete();
      await cache.settled;
      expect(previous.debugDisposed, isTrue);
      expect(cache.generatedMasks, 2);
      expect(cache.imageFor(const ui.Size(14, 2)), isNotNull);
      expect(errors, isEmpty);
      cache.close(imports: (_) => Future.value());
      await cache.settled;
      expect(budget.residentBytes, 0);
    },
  );

  test(
    'closing during generation releases late image and reservation',
    () async {
      final budget = RuntimeResourceBudget();
      final started = Completer<void>();
      final finish = Completer<ui.Image>();
      final cache = BattleStageShadowMaskCache(
        resourceBudget: budget,
        generate: (_) {
          started.complete();
          return finish.future;
        },
      );
      cache.sync({const ui.Size(12, 2)});
      await started.future;
      cache.close(imports: (_) => Future.value());
      expect(budget.residentBytes, greaterThan(0));
      final image = _image();
      finish.complete(image);
      await cache.settled;
      expect(image.debugDisposed, isTrue);
      expect(cache.activeMasks, 0);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
    },
  );

  test(
    'admission refusal never generates or retains a shadow source',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 8),
      );
      var generated = 0;
      final errors = <Object>[];
      final cache = BattleStageShadowMaskCache(
        resourceBudget: budget,
        generate: (_) async {
          generated++;
          return _image();
        },
        onError: (error, _) => errors.add(error),
      );
      cache.sync({const ui.Size(12, 2)});
      await cache.settled;
      expect(errors.single, isA<RuntimeResourceAdmissionException>());
      expect(generated, 0);
      expect(cache.activeMasks, 0);
      expect(budget.residentBytes, 0);
      cache.close(imports: (_) => Future.value());
    },
  );
}

ui.Image _image() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(2, 2);
  picture.dispose();
  return image;
}
