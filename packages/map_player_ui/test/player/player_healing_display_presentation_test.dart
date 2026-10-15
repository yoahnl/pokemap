import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/src/player/player_heal_confirmation.dart';
import 'package:map_player_ui/src/localization/player_localizations.dart';
import 'package:map_player_ui/src/theme/pokemap_player_theme.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final mode in [
    'display',
    'confirmation',
    'ordinary',
    'completed',
    'failed',
    'wrongIdentity',
  ]) {
    testWidgets('native healing display presentation $mode', (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      final snapshot = RuntimeWorldServiceSnapshot(
        revision: 7,
        request: OpenHealService(
          interactionId: 'nurse',
          requiresConfirmation: mode == 'confirmation',
          displayEntityId: mode == 'ordinary'
              ? null
              : mode == 'wrongIdentity'
              ? 'other'
              : 'balls',
        ),
        stage: mode == 'completed'
            ? RuntimeWorldServiceStage.completed
            : mode == 'failed'
            ? RuntimeWorldServiceStage.failed
            : RuntimeWorldServiceStage.applying,
        content: RuntimeHealServiceContent(
          title: 'Native heal',
          message: 'Applying',
          members: const [],
          display: mode == 'ordinary'
              ? null
              : RuntimeHealingDisplaySnapshot(
                  mapId: 'center',
                  entityId: 'balls',
                  memberCount: 3,
                ),
        ),
        actions: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          home: Stack(
            children: [
              const Text('Native world'),
              PlayerHealConfirmation(
                snapshot: snapshot,
                onCommand: commands.add,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Native world'), findsOneWidget);
      expect(
        find.text('Native heal'),
        mode == 'display' ? findsNothing : findsOneWidget,
      );
      expect(
        find.byType(LinearProgressIndicator),
        mode == 'confirmation' || mode == 'ordinary' || mode == 'wrongIdentity'
            ? findsOneWidget
            : findsNothing,
      );
      expect(commands, isEmpty);
    });
  }
}
