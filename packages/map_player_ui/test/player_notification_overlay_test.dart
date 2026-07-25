import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('notification is a themed accessible live region',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: const Scaffold(
          body: PlayerNotificationOverlay(
            snapshot: RuntimeNotificationSnapshot(
              revision: 2,
              text: 'Sauvegarde terminée.',
              tone: RuntimeNotificationTone.success,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sauvegarde terminée.'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey<String>('player-notification')),
    );
    expect(semantics.label, 'Sauvegarde terminée.');
  });
}
