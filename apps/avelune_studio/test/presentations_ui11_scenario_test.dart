import 'dart:async';
import 'dart:io';
import 'package:avelune_studio/platform/rendering/presentation_scenario_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/ui11_runtime_fixture.dart';

void main() {
  late Ui11RuntimeFixture fixture;
  setUp(() async {
    fixture = await Ui11RuntimeFixture.create();
  });
  tearDown(() => fixture.dispose());
  testWidgets(
    'published presentation holds on real cue then continues the real scene',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final before = File('${fixture.root}/project.json').readAsBytesSync();
      final deltas = StreamController<int>();
      final scenario = StudioPresentationScenarioPreview(
        projectRoot: fixture.root,
        revision: fixture.revision,
        project: fixture.project,
        sceneId: 'intro-scene',
        catalog: fixture.media.catalog,
        mediaUris: fixture.media.mediaUris,
        portrait: false,
        frameDeltas: (_) => deltas.stream,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: scenario.surface(),
          ),
        ),
      );
      late Future<void> running;
      await tester.runAsync(() async {
        running = scenario.run();
      });
      await _pumpUntil(
        tester,
        () => scenario.session.frames.value?.frame.timeUs == 0,
      );
      await tester.runAsync(() async {
        deltas.add(750000);
      });
      await _pumpUntil(tester, () => scenario.waitingForInteraction);
      expect(scenario.running, isTrue);
      expect(scenario.statusLabel, 'En attente de votre réponse');
      expect(scenario.session.frames.value!.frame.timeUs, 750000);
      expect(
        scenario.session.pendingRequest!.kind,
        SceneInteractionRequestKind.text,
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(scenario.session.frames.value!.frame.timeUs, 750000);
      await tester.enterText(
        find.byKey(const ValueKey('scene-interaction-text-field')),
        'Avelune',
      );
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-text-submit')),
      );
      await _pumpUntil(tester, () => !scenario.waitingForInteraction);
      await tester.runAsync(() async {
        deltas.add(250000);
      });
      await _pumpUntil(
        tester,
        () => scenario.session.frames.value?.frame.timeUs == 1000000,
      );
      await tester.runAsync(() async {
        deltas.add(2000000);
      });
      await _pumpUntil(
        tester,
        () =>
            scenario.session.pendingRequest?.kind ==
            SceneInteractionRequestKind.message,
      );
      expect(
        scenario.session.pendingRequest!.prompt.fallbackText,
        'La présentation est terminée.',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _pumpUntil(tester, () => scenario.result != null);
      expect(scenario.result!.playerName, 'Avelune');
      expect(scenario.running, isFalse);
      expect(scenario.failure, isNull);
      await tester.runAsync(() async {
        await running;
        await scenario.close();
        await deltas.close();
      });
      expect(File('${fixture.root}/project.json').readAsBytesSync(), before);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 150; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    if (ready()) {
      await tester.pump();
      return;
    }
  }
  throw StateError('Runtime scenario did not reach expected state');
}
