import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_contacts.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'contacts paginate and call the chosen identity at $size text $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final commands = <RuntimePlayerPauseCommand>[];
          final snapshot = RuntimePlayerSnapshot(
            revision: 3,
            phase: RuntimePlayerPhase.paused,
            gameTitle: 'Voyage',
            pauseSection: RuntimePlayerPauseSection.contacts,
            actions: const [
              RuntimePlayerActionAvailability.enabled(
                RuntimePlayerAction.callContact,
              ),
            ],
            pauseDetails: {
              RuntimePlayerPauseSection.contacts:
                  RuntimePlayerPauseDetailSnapshot(
                    section: RuntimePlayerPauseSection.contacts,
                    title: 'Contacts',
                    entries: List.generate(
                      18,
                      (index) => RuntimePlayerDetailEntrySnapshot(
                        id: 'person-$index',
                        title: 'Contact $index',
                      ),
                    ),
                  ),
            },
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: PokeMapPlayerTheme.dark(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: PlayerMenuThemeScope(
                  child: RuntimePlayerContacts(
                    snapshot: snapshot,
                    onPauseCommand: commands.add,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(Scrollable), findsNothing);
          final chosen = find.byKey(const ValueKey('contact.person-17'));
          for (var page = 0; chosen.evaluate().isEmpty && page < 20; page++) {
            await tester.tap(find.byKey(const ValueKey('player-page-next')));
            await tester.pumpAndSettle();
          }
          expect(chosen.hitTestable(), findsOneWidget);
          await tester.tap(chosen);
          expect(commands.single.contactId, 'person-17');
          expect(
            commands.single.kind,
            RuntimePlayerPauseCommandKind.callContact,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

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
