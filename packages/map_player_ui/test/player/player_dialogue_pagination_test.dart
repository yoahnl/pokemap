import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets(
    'long authored text is fully paged before one runtime acknowledgement',
    (tester) async {
      final actions = <PlayerDialogueAction>[];
      final text = [
        for (var index = 0; index < 25; index++)
          'Phrase $index : cette aventure continue au-delà de la prochaine colline.',
      ].join('\n');
      await _pump(tester, text: text, actions: actions);
      expect(find.byType(SingleChildScrollView), findsNothing);
      final parts = <String>[];
      for (var page = 0; page < 100 && actions.isEmpty; page++) {
        final body = tester.widget<Text>(
          find.byKey(const ValueKey('dialogue-page-text')),
        );
        parts.add(body.textSpan!.toPlainText());
        await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
        await tester.pump();
      }
      expect(parts.length, greaterThan(1));
      expect(parts.join(), text);
      expect(
        actions.single,
        isA<PlayerDialogueAdvanceAction>().having(
          (value) => value.snapshotRevision,
          'revision',
          7,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
      expect(actions, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'revealing the typewriter does not acknowledge or skip unseen pages',
    (tester) async {
      final actions = <PlayerDialogueAction>[];
      final text = List.filled(
        14,
        'Un texte qui doit rester entièrement accessible.',
      ).join(' ');
      await _pump(
        tester,
        text: text,
        visible: 'Un texte',
        revealed: false,
        actions: actions,
      );
      await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
      expect(actions, hasLength(1));
      actions.clear();
      await _pump(tester, text: text, actions: actions);
      await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
      await tester.pump();
      expect(actions, isEmpty);
      expect(find.text('2 /'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('rich text and inline icons survive every local page', (
    tester,
  ) async {
    final actions = <PlayerDialogueAction>[];
    const iconKey = ValueKey('authored-dialogue-icon');
    final tail = List.filled(20, 'Le récit se poursuit.').join('\n');
    final span = TextSpan(
      children: [
        const TextSpan(
          text: 'Lueur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const WidgetSpan(
          child: SizedBox(
            width: 20,
            height: 20,
            child: Icon(Icons.star, key: iconKey),
          ),
        ),
        TextSpan(text: '\n$tail'),
      ],
    );
    await _pump(tester, text: span.toPlainText(), actions: actions, span: span);
    final parts = <String>[];
    var iconsSeen = 0;
    for (var page = 0; page < 100 && actions.isEmpty; page++) {
      parts.add(
        tester
            .widget<Text>(find.byKey(const ValueKey('dialogue-page-text')))
            .textSpan!
            .toPlainText(),
      );
      iconsSeen += find.byKey(iconKey).evaluate().length;
      await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
      await tester.pump();
    }
    expect(parts.join(), span.toPlainText());
    expect(iconsSeen, 1);
    expect(actions, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a repeated authored line starts again at its first page', (
    tester,
  ) async {
    final actions = <PlayerDialogueAction>[];
    final text = List.filled(
      20,
      'Une même phrase peut revenir dans le récit.',
    ).join('\n');
    await _pump(tester, text: text, actions: actions);
    final first = tester
        .widget<Text>(find.byKey(const ValueKey('dialogue-page-text')))
        .textSpan!
        .toPlainText();
    for (var page = 0; page < 100 && actions.isEmpty; page++) {
      await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
      await tester.pump();
    }
    expect(actions, hasLength(1));
    await _pump(tester, text: text, actions: actions, revision: 8);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('dialogue-page-text')))
          .textSpan!
          .toPlainText(),
      first,
    );
    await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
    await tester.pump();
    expect(actions, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required String text,
  required List<PlayerDialogueAction> actions,
  String? visible,
  bool revealed = true,
  int revision = 7,
  InlineSpan? span,
}) async {
  await tester.binding.setSurfaceSize(const Size(640, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(reducedMotion: true),
      home: Scaffold(
        body: PlayerDialogueSurface(
          data: PlayerDialogueViewData(
            revision: revision,
            lineSpan: span,
            mode: PlayerDialogueMode.line,
            speaker: 'Guide',
            text: visible ?? text,
            fullText: text,
            isCurrentLineFullyRevealed: revealed,
            isLastContent: true,
            choices: const [],
          ),
          onAction: actions.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
