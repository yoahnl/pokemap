import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('renders canonical battle data and emits a versioned command',
      (tester) async {
    BattlePresentationCommand? command;
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (value) => command = value,
    );

    expect(find.text('Tonnerre'), findsOneWidget);
    expect(find.text('ÉLECTRIK · PP 12/15'), findsOneWidget);
    expect(find.text('PAR'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('battle-entry-1')));
    expect(
      command,
      isA<BattleSelectEntryCommand>()
          .having((value) => value.snapshotRevision, 'revision', 9)
          .having(
            (value) => value.expectedMode,
            'mode',
            BattleCommandOverlayMode.fight,
          )
          .having((value) => value.entryIndex, 'index', 1),
    );
  });

  testWidgets('disables unavailable entries and exposes the reason',
      (tester) async {
    var commandCount = 0;
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (_) => commandCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('battle-entry-0')));
    expect(commandCount, 0);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    expect(semantics.label, contains('Vive-Attaque'));
    expect(semantics.hint, contains('PP 0/30'));
  });

  testWidgets('forced replacement has no dismiss action and survives scaling',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(
        phase: BattlePresentationPhase.forcedReplacement,
        mode: BattleCommandOverlayMode.pokemon,
        canGoBack: false,
      ),
      textScaler: const TextScaler.linear(1.8),
      onCommand: (_) {},
    );

    expect(find.text('Remplacement obligatoire'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('battle-back')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required BattleCommandOverlaySnapshot snapshot,
  required ValueChanged<BattlePresentationCommand> onCommand,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: PlayerBattleOverlay(
            snapshot: snapshot,
            onCommand: onCommand,
          ),
        ),
      ),
    ),
  );
  expect(find.byType(PlayerBattleSurface), findsOneWidget);
}

BattleCommandOverlaySnapshot _snapshot({
  BattlePresentationPhase phase = BattlePresentationPhase.choosingCommand,
  BattleCommandOverlayMode mode = BattleCommandOverlayMode.fight,
  bool canGoBack = true,
}) {
  return BattleCommandOverlaySnapshot(
    revision: 9,
    phase: phase,
    forcedReplacement: phase == BattlePresentationPhase.forcedReplacement,
    mode: mode,
    panelRect: const Rect.fromLTWH(12, 300, 366, 270),
    enemyHud: _hud(
      owner: 'ENNEMI',
      species: 'Roucarnage',
      hp: 23,
      maxHp: 80,
      status: 'PAR',
    ),
    playerHud: _hud(
      owner: 'JOUEUR',
      species: 'Pikachu',
      hp: 61,
      maxHp: 72,
    ),
    battleLabel: 'COMBAT DE DRESSEUR',
    title: mode == BattleCommandOverlayMode.pokemon ? 'ÉQUIPE' : 'CAPACITÉS',
    prompt: phase == BattlePresentationPhase.forcedReplacement
        ? 'Choisissez un remplaçant.'
        : 'Choisissez une capacité.',
    narrationLines: const <String>[],
    entries: const <BattleCommandOverlayEntry>[
      BattleCommandOverlayEntry(
        index: 0,
        kind: BattleCommandOverlayEntryKind.move,
        primaryLabel: 'Vive-Attaque',
        secondaryLabel: 'NORMAL · PP 0/30',
        enabled: false,
        selected: false,
        tone: BattleCommandOverlayEntryTone.disabled,
      ),
      BattleCommandOverlayEntry(
        index: 1,
        kind: BattleCommandOverlayEntryKind.move,
        primaryLabel: 'Tonnerre',
        secondaryLabel: 'ÉLECTRIK · PP 12/15',
        statusLabel: 'Super efficace',
        enabled: true,
        selected: true,
        tone: BattleCommandOverlayEntryTone.special,
      ),
    ],
    interactionsEnabled: true,
    canGoBack: canGoBack,
  );
}

BattleCommandOverlayHudSnapshot _hud({
  required String owner,
  required String species,
  required int hp,
  required int maxHp,
  String? status,
}) {
  return BattleCommandOverlayHudSnapshot(
    rect: const Rect.fromLTWH(12, 12, 160, 64),
    ownerLabel: owner,
    speciesLabel: species,
    level: 32,
    currentHp: hp,
    maxHp: maxHp,
    statusLabel: status,
    isPlayerSide: owner == 'JOUEUR',
  );
}
