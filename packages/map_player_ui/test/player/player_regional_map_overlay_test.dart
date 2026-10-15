import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final size in [const Size(1000, 700), const Size(360, 640)]) {
    testWidgets('contextual map reuses regional view and closes at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final commands = <RuntimeWorldServiceCommand>[];
      final snapshot = RuntimeWorldServiceSnapshot(
        revision: 7,
        request: const OpenRegionalMapService(interactionId: 'wall.map'),
        stage: RuntimeWorldServiceStage.active,
        content: RuntimeRegionalMapServiceContent(
          detail: RuntimePlayerPauseDetailSnapshot(
            section: RuntimePlayerPauseSection.map,
            title: 'Carte',
            regionalMap: RuntimePlayerRegionMapSnapshot(
              regions: [
                RuntimePlayerRegionSnapshot(
                  id: 'kanto',
                  label: 'Kanto',
                  points: const [
                    RuntimePlayerMapPointSnapshot(
                      id: 'route10',
                      label: 'Route 10',
                      status: RuntimePlayerMapPointStatus.current,
                      u: .6,
                      v: .2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: const [
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.close,
          ),
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.cancel,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          home: PlayerRegionalMapOverlay(
            snapshot: snapshot,
            onCommand: commands.add,
            controlProfile: PlayerControlProfile.standard.rebind(
                device: PlayerControlDevice.keyboard,
                control: RuntimeInputControl.secondary,
                inputId: 'keyQ').profile,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RuntimePlayerRegionMap), findsOneWidget);
      expect(find.text('Kanto'), findsWidgets);
      expect(find.text('Route 10'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('regional-map-close')));
      expect(commands.single.action, RuntimeWorldServiceAction.close);
      expect(commands.single.snapshotRevision, 7);
      commands.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(commands, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      expect(commands.single.action, RuntimeWorldServiceAction.cancel);
      expect(commands.single.snapshotRevision, 7);
      expect(tester.takeException(), isNull);
    });
  }
}
