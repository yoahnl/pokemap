import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import 'fixtures/personalization_studio_v2_fixture.dart';

void main() {
  testWidgets(
    'V10 reorders and relabels root commands without changing runtime indices',
    (tester) async {
      BattlePresentationCommand? command;
      const profile = ProjectBattlePresentationProfile(
        commands: <ProjectBattleCommandProfile>[
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.run,
            label: 'Retraite',
          ),
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.fight,
            label: 'Techniques',
          ),
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.party,
            label: 'Alliés',
          ),
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.bag,
            label: 'Inventaire',
          ),
        ],
      );
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(),
        onCommand: (value) => command = value,
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          profile,
        ),
      );

      expect(find.text('Retraite'), findsOneWidget);
      expect(find.text('Techniques'), findsOneWidget);
      expect(find.text('Alliés'), findsOneWidget);
      expect(find.text('Inventaire'), findsOneWidget);

      await tester.tap(find.text('Retraite'));

      expect(
        command,
        isA<BattleSelectEntryCommand>()
            .having((value) => value.entryIndex, 'runtime index', 3)
            .having(
              (value) => value.expectedMode,
              'mode',
              BattleCommandOverlayMode.root,
            ),
      );
    },
  );

  testWidgets('V10 renders radial commands and falls back in compact portrait',
      (
    tester,
  ) async {
    const profile = ProjectBattlePresentationProfile(
      commandLayout: ProjectBattleCommandLayout.radial,
    );
    final theme = PokeMapPlayerTheme.withBattleProfile(
      PokeMapPlayerTheme.dark(),
      profile,
    );
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(),
      onCommand: (_) {},
      theme: theme,
    );

    expect(
      find.byKey(const ValueKey<String>('battle-panel-commands-radial')),
      findsOneWidget,
    );
    final top = tester.getCenter(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    final right = tester.getCenter(
      find.byKey(const ValueKey<String>('battle-entry-1')),
    );
    final bottom = tester.getCenter(
      find.byKey(const ValueKey<String>('battle-entry-2')),
    );
    expect(top.dy, lessThan(right.dy));
    expect(bottom.dy, greaterThan(right.dy));
    expect(right.dx, greaterThan(top.dx));

    await tester.binding.setSurfaceSize(const Size(390, 760));
    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(),
      onCommand: (_) {},
      theme: theme,
    );

    expect(
      find.byKey(const ValueKey<String>('battle-panel-commands-grid')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('V10 styles HUD, HP and each battle panel independently', (
    tester,
  ) async {
    const profile = ProjectBattlePresentationProfile(
      commandLayout: ProjectBattleCommandLayout.list,
      commandColumns: 1,
      commandShape: ProjectWindowShape.cutCorner,
      commandPadding: 20,
      commandSurfaceColor: '#102030',
      commandBorderColor: '#FFAA00',
      commandTextColor: '#FFFFFF',
      commandSelectionColor: '#00CCAA',
      hudShape: ProjectWindowShape.rectangle,
      enemyHudPosition: ProjectBattleHudPosition.topEnd,
      playerHudPosition: ProjectBattleHudPosition.bottomStart,
      showOwnerLabel: false,
      showLevel: false,
      showExactHp: false,
      hpBarShape: ProjectBattleHpBarShape.segmented,
      hpHealthyColor: '#00AA55',
      hpWarningColor: '#FFAA00',
      hpDangerColor: '#CC2244',
      statusColor: '#8844FF',
      moves: ProjectBattlePanelPresentationProfile(
        layout: ProjectBattleCommandLayout.grid,
        columns: 2,
        shape: ProjectWindowShape.rounded,
        padding: 16,
        surfaceColor: '#334455',
      ),
    );
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (_) {},
      theme: PokeMapPlayerTheme.withBattleProfile(
        PokeMapPlayerTheme.dark(),
        profile,
      ),
    );

    expect(
        find.byKey(const ValueKey<String>('battle-owner-enemy')), findsNothing);
    expect(
        find.byKey(const ValueKey<String>('battle-level-enemy')), findsNothing);
    expect(find.byKey(const ValueKey<String>('battle-exact-hp-enemy')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('battle-hp-segmented-enemy')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('battle-hud-position-enemy-topEnd')),
      findsOneWidget,
    );
    expect(
      find.byKey(
          const ValueKey<String>('battle-hud-position-player-bottomStart')),
      findsOneWidget,
    );

    final panel = find.byKey(const ValueKey<String>('battle-command-panel'));
    final material = tester.widget<Material>(
      find.descendant(of: panel, matching: find.byType(Material)).first,
    );
    expect(material.color, const Color(0xFF334455));
    expect(material.shape, isA<RoundedRectangleBorder>());
  });

  testWidgets('V10 colors the runtime-owned HP thresholds at zero and max', (
    tester,
  ) async {
    const profile = ProjectBattlePresentationProfile(
      hpBarShape: ProjectBattleHpBarShape.flat,
      hpHealthyColor: '#00AA55',
      hpWarningColor: '#FFAA00',
      hpDangerColor: '#CC2244',
      statusColor: '#8844FF',
    );
    final theme = PokeMapPlayerTheme.withBattleProfile(
      PokeMapPlayerTheme.dark(),
      profile,
    );

    for (final state in <({int hp, Color color})>[
      (hp: 0, color: const Color(0xFFCC2244)),
      (hp: 40, color: const Color(0xFFFFAA00)),
      (hp: 100, color: const Color(0xFF00AA55)),
    ]) {
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          enemyHp: state.hp,
          enemyMaxHp: 100,
          enemyStatus: 'PARALYSIE PROLONGÉE',
        ),
        onCommand: (_) {},
        theme: theme,
      );

      final progress = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('battle-hp-flat-enemy'),
          ),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(progress.color, state.color);
      expect(find.text('PARALYSIE PROLONGÉE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders canonical battle data and emits a versioned command',
      (tester) async {
    BattlePresentationCommand? command;
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (value) => command = value,
    );

    expect(find.text('Tonnerre'), findsOneWidget);
    expect(find.byType(PlayerBattleScene), findsOneWidget);
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

  testWidgets('battle style and combat typography stay scoped to combat', (
    tester,
  ) async {
    const typography = PokeMapPlayerTypography(
      bodyFamily: 'Studio Body',
      dialogueFamily: 'Studio Dialogue',
      combatFamily: 'Studio Combat',
    );
    const windows = ProjectPresentationWindowsProfile(
      styles: <ProjectWindowStyleProfile>[
        ProjectWindowStyleProfile(
          id: 'default',
          fillToken: 'surface',
          borderToken: 'outline',
          borderWidth: 1,
          cornerRadius: 16,
          contentPadding: 24,
          shadowElevation: 8,
        ),
        ProjectWindowStyleProfile(
          id: 'battle',
          fillToken: 'battleHudSurface',
          borderToken: 'primary',
          borderWidth: 3,
          cornerRadius: 5,
          contentPadding: 8,
          shadowElevation: 2,
        ),
      ],
      defaultStyleId: 'default',
      pauseMenuStyleId: 'default',
      dialogueStyleId: 'default',
      battleStyleId: 'battle',
      pauseBackdropOpacity: .7,
    );
    final theme = PokeMapPlayerTheme.withWindowProfile(
      PokeMapPlayerTheme.withTypography(
        PokeMapPlayerTheme.dark(),
        typography,
      ),
      windows,
    );

    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (_) {},
      theme: theme,
    );

    final panel = find.byKey(
      const ValueKey<String>('battle-command-panel'),
    );
    final material = tester.widget<Material>(
      find.descendant(of: panel, matching: find.byType(Material)).first,
    );
    final shape = material.shape! as RoundedRectangleBorder;
    final battleContext = tester.element(find.byType(PlayerBattleSurface));
    expect(material.color, battleContext.playerSemanticTheme.battleHudSurface);
    expect(shape.borderRadius, BorderRadius.circular(5));
    expect(shape.side.width, 3);
    expect(tester.widget<Text>(find.text('CAPACITÉS')).style?.fontFamily,
        'Studio Combat');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: theme,
        home: PlayerDialogueSurface(
          data: PersonalizationStudioV2Fixture.dialogue,
          onAction: (_) {},
        ),
      ),
    );
    expect(
      tester
          .widget<Text>(
            find.text(
              'Le monde est peuplé de créatures extraordinaires.',
            ),
          )
          .style
          ?.fontFamily,
      'Studio Dialogue',
    );
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required BattleCommandOverlaySnapshot snapshot,
  required ValueChanged<BattlePresentationCommand> onCommand,
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme ?? PokeMapPlayerTheme.dark(),
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
  int enemyHp = 23,
  int enemyMaxHp = 80,
  String? enemyStatus = 'PAR',
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
      hp: enemyHp,
      maxHp: enemyMaxHp,
      status: enemyStatus,
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

BattleCommandOverlaySnapshot _rootSnapshot() => BattleCommandOverlaySnapshot(
      revision: 12,
      mode: BattleCommandOverlayMode.root,
      panelRect: const Rect.fromLTWH(12, 300, 366, 270),
      enemyHud: _hud(owner: 'ENNEMI', species: 'Roucool', hp: 20, maxHp: 20),
      playerHud: _hud(owner: 'JOUEUR', species: 'Brindibou', hp: 24, maxHp: 30),
      battleLabel: 'COMBAT SAUVAGE',
      title: 'COMMANDES',
      prompt: 'Choisissez une action.',
      narrationLines: const <String>[],
      entries: const <BattleCommandOverlayEntry>[
        BattleCommandOverlayEntry(
          index: 0,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'ATTAQUER',
          secondaryLabel: 'Choisir une capacité',
          enabled: true,
          selected: true,
          tone: BattleCommandOverlayEntryTone.attack,
        ),
        BattleCommandOverlayEntry(
          index: 1,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'SAC',
          secondaryLabel: 'Utiliser un objet',
          enabled: true,
          selected: false,
          tone: BattleCommandOverlayEntryTone.medicine,
        ),
        BattleCommandOverlayEntry(
          index: 2,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'ÉQUIPE',
          secondaryLabel: 'Changer de Pokémon',
          enabled: true,
          selected: false,
          tone: BattleCommandOverlayEntryTone.switching,
        ),
        BattleCommandOverlayEntry(
          index: 3,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'FUITE',
          secondaryLabel: 'Quitter le combat',
          enabled: true,
          selected: false,
          tone: BattleCommandOverlayEntryTone.neutral,
        ),
      ],
      interactionsEnabled: true,
      canGoBack: false,
    );

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
