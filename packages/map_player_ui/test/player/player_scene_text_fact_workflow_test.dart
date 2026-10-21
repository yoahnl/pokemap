import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../../../map_runtime/test/scene_text_fact_transaction_test.dart'
    show TextFactFixture;

void main() {
  testWidgets(
    'native rival naming returns from No to the full source menu and commits only Yes',
    (tester) async {
      final fixture = TextFactFixture(presets: true);
      addTearDown(fixture.controller.dispose);
      final pending = fixture.run();
      Future<void> show() async {
        await tester.pump();
        final snapshot = fixture.controller.worldServiceSnapshot!;
        await tester.pumpWidget(
          MaterialApp(
            theme: PokeMapPlayerTheme.dark(),
            home: Scaffold(
              body: PlayerTextInputOverlay(
                snapshot: snapshot,
                onCommand: fixture.controller.dispatchWorldService,
              ),
            ),
          ),
        );
      }

      await show();
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Gary'), findsOneWidget);
      expect(find.text('Michael'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-option-custom')),
      );
      await show();
      await tester.enterText(
        find.byKey(const ValueKey('scene-interaction-text-field')),
        'Gold',
      );
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-text-submit')),
      );
      await show();
      expect(find.text('Confirmer Gold ?'), findsOneWidget);
      expect(fixture.initial.narrativeFactRuntimeState.valuesByFactId, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-confirm-no')),
      );
      await show();
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Gary'), findsOneWidget);
      expect(find.text('Michael'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-option-preset:1')),
      );
      await show();
      expect(find.text('Confirmer Gary ?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-interaction-text-field')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-confirm-yes')),
      );
      await tester.pump();
      final done = await pending;
      expect(done.success, isTrue);
      expect(
        done.state!.narrativeFactRuntimeState.valueFor('rival'),
        NarrativeValue.string('Gary'),
      );
      expect(fixture.commits, 0);
      expect(fixture.initial.scriptVariables.values, isEmpty);
    },
  );
  testWidgets(
    'confirmation cancellation returns to choices without writing the candidate',
    (tester) async {
      final fixture = TextFactFixture(presets: true);
      addTearDown(fixture.controller.dispose);
      final pending = fixture.run();
      Future<void> show() async {
        await tester.pump();
        await tester.pumpWidget(
          MaterialApp(
            theme: PokeMapPlayerTheme.dark(),
            home: Scaffold(
              body: PlayerTextInputOverlay(
                snapshot: fixture.controller.worldServiceSnapshot!,
                onCommand: fixture.controller.dispatchWorldService,
              ),
            ),
          ),
        );
      }

      await show();
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-option-preset:0')),
      );
      await show();
      expect(find.text('Confirmer Blue ?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scene-interaction-cancel')));
      await show();
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Michael'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scene-interaction-cancel')));
      await tester.pump();
      final done = await pending;
      expect(done.success, isTrue);
      expect(
        done.state!.narrativeFactRuntimeState.valueFor('rival'),
        NarrativeValue.string('Before'),
      );
      expect(fixture.commits, 0);
    },
  );
}
