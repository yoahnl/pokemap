import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

BattleCommandOverlaySnapshot _snapshot({
  required BattleCommandOverlayMode mode,
  required List<BattleCommandOverlayEntry> entries,
  bool interactionsEnabled = true,
  bool canGoBack = false,
  Size viewportSize = const Size(390, 600),
  double panelHeight = 260,
}) {
  final playerHudRect = Rect.fromLTWH(
    viewportSize.width - 168,
    viewportSize.height - panelHeight - 72,
    152,
    62,
  );
  return BattleCommandOverlaySnapshot(
    mode: mode,
    panelRect: Rect.fromLTWH(
      12,
      viewportSize.height - panelHeight - 14,
      viewportSize.width - 24,
      panelHeight,
    ),
    enemyHud: const BattleCommandOverlayHudSnapshot(
      rect: Rect.fromLTWH(16, 20, 138, 62),
      ownerLabel: 'ENNEMI',
      speciesLabel: 'caterpie',
      level: 4,
      currentHp: 18,
      maxHp: 18,
      isPlayerSide: false,
    ),
    playerHud: BattleCommandOverlayHudSnapshot(
      rect: playerHudRect,
      ownerLabel: 'JOUEUR',
      speciesLabel: 'squirtle',
      level: 25,
      currentHp: 57,
      maxHp: 57,
      isPlayerSide: true,
    ),
    battleLabel: 'COMBAT SAUVAGE',
    title: switch (mode) {
      BattleCommandOverlayMode.root => 'COMMANDS',
      BattleCommandOverlayMode.fight => 'MOVES',
      BattleCommandOverlayMode.bag => 'BAG',
      BattleCommandOverlayMode.bagMedicineTarget => 'TARGET',
      BattleCommandOverlayMode.pokemon => 'POKEMON',
      BattleCommandOverlayMode.continueOnly => 'CONTINUE',
    },
    prompt: 'Choisis une action.',
    narrationLines: const <String>['Les objets indisponibles restent grisés.'],
    entries: entries,
    interactionsEnabled: interactionsEnabled,
    canGoBack: canGoBack,
  );
}

BattleCommandOverlayEntry _entry({
  required int index,
  required BattleCommandOverlayEntryKind kind,
  required String primaryLabel,
  String secondaryLabel = '',
  String? tertiaryLabel,
  String? trailingLabel,
  String? statusLabel,
  bool enabled = true,
  bool selected = false,
  BattleCommandOverlayEntryTone tone = BattleCommandOverlayEntryTone.neutral,
  String? iconAssetPath,
}) {
  return BattleCommandOverlayEntry(
    index: index,
    kind: kind,
    primaryLabel: primaryLabel,
    secondaryLabel: secondaryLabel,
    tertiaryLabel: tertiaryLabel,
    trailingLabel: trailingLabel,
    statusLabel: statusLabel,
    enabled: enabled,
    selected: selected,
    tone: tone,
    iconAssetPath: iconAssetPath,
  );
}

Widget _hostedOverlay({
  required BattleCommandOverlaySnapshot snapshot,
  required ValueChanged<int> onEntrySelected,
  VoidCallback? onBack,
  Widget Function(String imagePath)? itemIconBuilder,
  Size? canvasSize,
}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: canvasSize?.width ?? snapshot.panelRect.right + 12,
        height: canvasSize?.height ?? snapshot.panelRect.bottom + 14,
        child: BattleMobileCommandOverlay(
          snapshot: snapshot,
          onEntrySelected: onEntrySelected,
          onBack: onBack,
          itemIconBuilder: itemIconBuilder,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleMobileCommandOverlay', () {
    testWidgets('renders the battle huds outside the command panel',
        (tester) async {
      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.root,
            entries: <BattleCommandOverlayEntry>[
              _entry(
                index: 0,
                kind: BattleCommandOverlayEntryKind.root,
                primaryLabel: 'FIGHT',
                secondaryLabel: '2 moves',
              ),
            ],
          ),
          onEntrySelected: (_) {},
        ),
      );

      expect(find.byKey(const Key('battle-mobile-enemy-hud')), findsOneWidget);
      expect(find.byKey(const Key('battle-mobile-player-hud')), findsOneWidget);
      expect(find.text('Caterpie'), findsOneWidget);
      expect(find.text('Squirtle'), findsOneWidget);
    });

    testWidgets('bag list uses a real ListView drag without accidental tap',
        (tester) async {
      var tappedIndex = -1;
      final entries = List<BattleCommandOverlayEntry>.generate(
        10,
        (index) => _entry(
          index: index,
          kind: BattleCommandOverlayEntryKind.bag,
          primaryLabel: 'Potion $index',
          secondaryLabel: 'Medicine',
          trailingLabel: 'x${index + 1}',
          statusLabel: 'OK',
          tone: BattleCommandOverlayEntryTone.medicine,
        ),
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.bag,
            entries: entries,
            canGoBack: true,
          ),
          onEntrySelected: (index) => tappedIndex = index,
          onBack: () {},
        ),
      );

      expect(find.byKey(const Key('battle-mobile-entry-list')), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      final initialTop =
          tester.getTopLeft(find.byKey(const Key('battle-mobile-entry-0'))).dy;

      await tester.drag(
        find.byKey(const Key('battle-mobile-entry-list')),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(-1));
      final draggedTop =
          tester.getTopLeft(find.byKey(const Key('battle-mobile-entry-0'))).dy;
      expect(draggedTop, lessThan(initialTop));
    });

    testWidgets('party list uses a real ListView drag without accidental tap',
        (tester) async {
      var tappedIndex = -1;
      final entries = List<BattleCommandOverlayEntry>.generate(
        8,
        (index) => _entry(
          index: index,
          kind: BattleCommandOverlayEntryKind.party,
          primaryLabel: 'pokemon_$index',
          secondaryLabel: '${20 + index}/${40 + index} PV',
          trailingLabel: 'Nv. ${10 + index}',
          statusLabel: index == 0 ? 'Actif' : 'OK',
          tone: BattleCommandOverlayEntryTone.switching,
          selected: index == 1,
        ),
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.pokemon,
            entries: entries,
            canGoBack: true,
          ),
          onEntrySelected: (index) => tappedIndex = index,
          onBack: () {},
        ),
      );

      final initialTop =
          tester.getTopLeft(find.byKey(const Key('battle-mobile-entry-0'))).dy;
      await tester.drag(
        find.byKey(const Key('battle-mobile-entry-list')),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(-1));
      final draggedTop =
          tester.getTopLeft(find.byKey(const Key('battle-mobile-entry-0'))).dy;
      expect(draggedTop, lessThan(initialTop));
    });

    testWidgets('fight mode renders a single tall column of move cards',
        (tester) async {
      final entries = <BattleCommandOverlayEntry>[
        _entry(
          index: 0,
          kind: BattleCommandOverlayEntryKind.move,
          primaryLabel: 'Rain Dance',
          secondaryLabel: 'WATER · Status · No direct damage',
          tone: BattleCommandOverlayEntryTone.support,
        ),
        _entry(
          index: 1,
          kind: BattleCommandOverlayEntryKind.move,
          primaryLabel: 'Aqua Tail',
          secondaryLabel: 'WATER · Physical · Power 90',
          tone: BattleCommandOverlayEntryTone.attack,
        ),
      ];

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.fight,
            entries: entries,
            canGoBack: true,
            panelHeight: 420,
          ),
          onEntrySelected: (_) {},
          onBack: () {},
        ),
      );

      final firstRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-0')));
      final secondRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-1')));

      expect((firstRect.left - secondRect.left).abs(), lessThan(1));
      expect(secondRect.top, greaterThan(firstRect.bottom));
      expect(firstRect.height, greaterThan(68));
      expect(firstRect.width, greaterThan(250));
    });

    testWidgets('shows a back button and invokes it', (tester) async {
      var backCount = 0;

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.bag,
            entries: <BattleCommandOverlayEntry>[
              _entry(
                index: 0,
                kind: BattleCommandOverlayEntryKind.bag,
                primaryLabel: 'Potion',
                secondaryLabel: 'Medicine',
                tone: BattleCommandOverlayEntryTone.medicine,
              ),
            ],
            canGoBack: true,
          ),
          onEntrySelected: (_) {},
          onBack: () => backCount += 1,
        ),
      );

      await tester.tap(find.byKey(const Key('battle-mobile-back-button')));
      await tester.pumpAndSettle();

      expect(backCount, equals(1));
    });

    testWidgets('renders item icons from resolved asset paths', (tester) async {
      const iconPath = '/tmp/runtime-bag-icons/hyper-potion.png';
      final receivedPaths = <String>[];

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.bag,
            entries: <BattleCommandOverlayEntry>[
              _entry(
                index: 0,
                kind: BattleCommandOverlayEntryKind.bag,
                primaryLabel: 'Hyper Potion',
                secondaryLabel: 'Medicine',
                iconAssetPath: iconPath,
                tone: BattleCommandOverlayEntryTone.medicine,
              ),
            ],
          ),
          onEntrySelected: (_) {},
          itemIconBuilder: (path) {
            receivedPaths.add(path);
            return const SizedBox(width: 30, height: 30);
          },
        ),
      );

      expect(
        find.byKey(const Key('battle-mobile-entry-icon-0')),
        findsOneWidget,
      );
      expect(receivedPaths, contains(iconPath));
    });

    testWidgets('disabled entries stay visible but are not tappable',
        (tester) async {
      var tappedIndex = -1;

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.bag,
            entries: <BattleCommandOverlayEntry>[
              _entry(
                index: 0,
                kind: BattleCommandOverlayEntryKind.bag,
                primaryLabel: 'Antidote',
                secondaryLabel: 'Medicine',
                statusLabel: 'Disabled',
                enabled: false,
                tone: BattleCommandOverlayEntryTone.disabled,
              ),
            ],
          ),
          onEntrySelected: (index) => tappedIndex = index,
        ),
      );

      await tester.tap(find.byKey(const Key('battle-mobile-entry-0')));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(-1));
    });

    testWidgets(
        'keeps compact desktop battle chrome inside the panel without overflow',
        (tester) async {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(844, 390),
      );
      final snapshot = BattleCommandOverlaySnapshot(
        mode: BattleCommandOverlayMode.root,
        panelRect: layout.commandPanelRect,
        enemyHud: BattleCommandOverlayHudSnapshot(
          rect: layout.enemyHudRect,
          ownerLabel: 'ENNEMI',
          speciesLabel: 'charmander',
          level: 12,
          currentHp: 34,
          maxHp: 34,
          isPlayerSide: false,
        ),
        playerHud: BattleCommandOverlayHudSnapshot(
          rect: layout.playerHudRect,
          ownerLabel: 'JOUEUR',
          speciesLabel: 'squirtle',
          level: 25,
          currentHp: 57,
          maxHp: 57,
          isPlayerSide: true,
        ),
        battleLabel: 'COMBAT SAUVAGE',
        title: 'COMMANDS',
        prompt: 'Que doit faire le joueur ?',
        narrationLines: const <String>[
          'Les quatre actions principales doivent rester visibles.',
        ],
        entries: <BattleCommandOverlayEntry>[
          _entry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'FIGHT',
            secondaryLabel: 'Attaquer',
          ),
          _entry(
            index: 1,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'BAG',
            secondaryLabel: 'Objets',
          ),
          _entry(
            index: 2,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'POKEMON',
            secondaryLabel: 'Équipe',
          ),
          _entry(
            index: 3,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'RUN',
            secondaryLabel: 'Fuir',
          ),
        ],
        interactionsEnabled: true,
        canGoBack: false,
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: layout.viewportSize,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final lastEntryRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-3')));
      expect(
          lastEntryRect.bottom, lessThanOrEqualTo(snapshot.panelRect.bottom));
    });
  });
}
