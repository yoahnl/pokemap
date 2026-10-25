import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/foundation/player_menu_icon.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/src/player/runtime_player_contacts.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });

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

  for (final format in [
    (size: Size(1440, 900), companion: false),
    (size: Size(1024, 768), companion: false),
    (size: Size(768, 1024), companion: false),
    (size: Size(844, 390), companion: false),
    (size: Size(390, 844), companion: false),
    (size: Size(496, 432), companion: true),
  ]) {
    testWidgets('three contact rows remain visible at $format', (tester) async {
      await _pumpContacts(
        tester,
        size: format.size,
        companion: format.companion,
      );
      final body = tester.getRect(
        find.byKey(const ValueKey('runtime-player-detail-contacts')),
      );
      final rows = <Rect>[];
      for (final id in ['private-lea', 'private-professor', 'private-guard']) {
        final finder = find.byKey(ValueKey('contact.$id'));
        expect(finder.hitTestable(), findsOneWidget);
        final rect = tester.getRect(finder);
        rows.add(rect);
        expect(rect.height, greaterThanOrEqualTo(56));
        expect(body.contains(rect.topLeft), isTrue);
        expect(rect.bottom, lessThanOrEqualTo(body.bottom + .1));
      }
      expect(rows[1].top - rows[0].bottom, 8);
      expect(rows[2].top - rows[1].bottom, 8);
      expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'contact cards retain subtitles and dispatch opaque call identities',
    (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pumpContacts(tester, onCommand: commands.add);
      expect(find.text('Laboratoire'), findsOneWidget);
      expect(find.text('Clairière des Sources'), findsOneWidget);
      expect(find.textContaining('private-'), findsNothing);
      final rows = tester
          .widgetList<PlayerMenuSelectableRow>(
            find.byType(PlayerMenuSelectableRow),
          )
          .toList();
      expect(rows.where((row) => row.selected).map((row) => row.id), [
        'contact.private-lea',
      ]);
      await tester.tap(find.byKey(const ValueKey('contact.private-guard')));
      await tester.pumpAndSettle();
      expect(commands.single.kind, RuntimePlayerPauseCommandKind.callContact);
      expect(commands.single.contactId, 'private-guard');
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('contact.private-guard')),
            )
            .selected,
        isTrue,
      );
    },
  );

  testWidgets(
    'unavailable call action disables contacts without invented availability',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await _pumpContacts(tester, enabled: false, onCommand: (_) => calls++);
      final row = find.byKey(const ValueKey('contact.private-lea'));
      expect(
        tester.getSemantics(row).flagsCollection.isEnabled,
        ui.Tristate.isFalse,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Disponible'), findsNothing);
      expect(find.text('Indisponible pour le moment'), findsNothing);
      expect(find.text('Près du pont'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'contact portrait keeps the authored path with a safe missing-image fallback',
    (tester) async {
      await _pumpContacts(tester, portrait: '/missing/authored-contact.png');
      final portrait = tester.widget<PlayerImageBuilder>(
        find.byKey(const ValueKey('contact-portrait-source-private-lea')),
      );
      expect(portrait.path, '/missing/authored-contact.png');
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PlayerMenuIcon &&
              widget.glyph == PlayerMenuGlyph.profile,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

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

Future<void> _pumpContacts(
  WidgetTester tester, {
  Size size = const Size(844, 390),
  bool companion = false,
  bool enabled = true,
  String? portrait,
  void Function(RuntimePlayerPauseCommand)? onCommand,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final snapshot = RuntimePlayerSnapshot(
    revision: 1,
    phase: RuntimePlayerPhase.paused,
    gameTitle: 'Voyage',
    pauseSection: RuntimePlayerPauseSection.contacts,
    actions: [
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.openContacts,
      ),
      if (enabled)
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.callContact,
        ),
    ],
    pauseDetails: {
      RuntimePlayerPauseSection.contacts: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.contacts,
        title: 'Contacts',
        entries: [
          RuntimePlayerDetailEntrySnapshot(
            id: 'private-lea',
            title: 'Léa',
            subtitle: 'Près du pont',
            portraitFilePath: portrait,
          ),
          RuntimePlayerDetailEntrySnapshot(
            id: 'private-professor',
            title: 'Professeur Orme',
            subtitle: 'Laboratoire',
          ),
          RuntimePlayerDetailEntrySnapshot(
            id: 'private-guard',
            title: 'Garde du pont',
            subtitle: 'Clairière des Sources',
          ),
        ],
      ),
    },
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: size.aspectRatio > 1 && !companion
              ? const EdgeInsets.fromLTRB(44, 12, 44, 20)
              : EdgeInsets.zero,
        ),
        child: companion ? PlayerCompanionScope(child: child!) : child!,
      ),
      home: PlayerMenuThemeScope(
        child: Scaffold(
          body: RuntimePlayerPauseShell(
            gameTitle: 'Voyage',
            pauseSection: RuntimePlayerPauseSection.contacts,
            actions: {
              for (final action in PlayerPauseAction.values)
                action: PlayerActionAvailability.enabled,
            },
            onSelected: (_) {},
            onBackToRoot: () {},
            presentation: const PlayerPausePresentation(
              style: ProjectPauseMenuStyle.nightIllustrated,
            ),
            detailOwnsScroll: true,
            detail: RuntimePlayerContacts(
              snapshot: snapshot,
              onPauseCommand: onCommand ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
