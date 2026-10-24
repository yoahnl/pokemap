import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_detail_router.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('registered contact dispatches its typed call command', (
    tester,
  ) async {
    RuntimePlayerPauseCommand? called;
    final snapshot = RuntimePlayerSnapshot(
      revision: 1,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Travel',
      pauseSection: RuntimePlayerPauseSection.contacts,
      actions: const [
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openContacts,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.callContact,
        ),
      ],
      pauseDetails: {
        RuntimePlayerPauseSection.contacts: RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.contacts,
          title: 'Carnet',
          entries: [
            RuntimePlayerDetailEntrySnapshot(id: 'mentor', title: 'Mentor'),
          ],
        ),
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: RuntimePlayerDetailRouter(
            snapshot: snapshot,
            onPauseCommand: (command) => called = command,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mentor'));
    expect(called?.kind, RuntimePlayerPauseCommandKind.callContact);
    expect(called?.contactId, 'mentor');
  });
}
