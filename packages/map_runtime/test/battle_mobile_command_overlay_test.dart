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
  int enemyCurrentHp = 18,
  int enemyMaxHp = 18,
  int? enemyDisplayedHp,
  int? enemyTargetDisplayedHp,
  int? enemyHpTweenDurationMs,
  int enemyHpTweenRevision = 0,
  int playerCurrentHp = 57,
  int playerMaxHp = 57,
  int? playerDisplayedHp,
  int? playerTargetDisplayedHp,
  int? playerHpTweenDurationMs,
  int playerHpTweenRevision = 0,
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
    enemyHud: BattleCommandOverlayHudSnapshot(
      rect: const Rect.fromLTWH(16, 20, 138, 62),
      ownerLabel: 'ENNEMI',
      speciesLabel: 'caterpie',
      level: 4,
      currentHp: enemyCurrentHp,
      maxHp: enemyMaxHp,
      displayedHp: enemyDisplayedHp,
      targetDisplayedHp: enemyTargetDisplayedHp,
      hpTweenDurationMs: enemyHpTweenDurationMs,
      hpTweenRevision: enemyHpTweenRevision,
      isPlayerSide: false,
    ),
    playerHud: BattleCommandOverlayHudSnapshot(
      rect: playerHudRect,
      ownerLabel: 'JOUEUR',
      speciesLabel: 'squirtle',
      level: 25,
      currentHp: playerCurrentHp,
      maxHp: playerMaxHp,
      displayedHp: playerDisplayedHp,
      targetDisplayedHp: playerTargetDisplayedHp,
      hpTweenDurationMs: playerHpTweenDurationMs,
      hpTweenRevision: playerHpTweenRevision,
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

List<BattleCommandOverlayEntry> _rootEntries() {
  return <BattleCommandOverlayEntry>[
    _entry(
      index: 0,
      kind: BattleCommandOverlayEntryKind.root,
      primaryLabel: 'FIGHT',
      secondaryLabel: '2 moves',
    ),
    _entry(
      index: 1,
      kind: BattleCommandOverlayEntryKind.root,
      primaryLabel: 'BAG',
      secondaryLabel: 'Capture',
    ),
    _entry(
      index: 2,
      kind: BattleCommandOverlayEntryKind.root,
      primaryLabel: 'POKEMON',
      secondaryLabel: '1 switch',
    ),
    _entry(
      index: 3,
      kind: BattleCommandOverlayEntryKind.root,
      primaryLabel: 'RUN',
      secondaryLabel: 'Escape',
    ),
  ];
}

BattleCommandOverlaySnapshot _layoutSnapshot({
  required Size viewportSize,
  BattleCommandOverlayMode mode = BattleCommandOverlayMode.root,
  List<BattleCommandOverlayEntry>? entries,
  int enemyCurrentHp = 18,
  int enemyMaxHp = 18,
  int playerCurrentHp = 57,
  int playerMaxHp = 57,
}) {
  final layout = BattleSceneLayout.forViewport(viewportSize: viewportSize);
  return BattleCommandOverlaySnapshot(
    mode: mode,
    panelRect: layout.commandPanelRect,
    enemyHud: BattleCommandOverlayHudSnapshot(
      rect: layout.enemyHudRect,
      ownerLabel: 'ENNEMI',
      speciesLabel: 'charmander',
      level: 4,
      currentHp: enemyCurrentHp,
      maxHp: enemyMaxHp,
      isPlayerSide: false,
    ),
    playerHud: BattleCommandOverlayHudSnapshot(
      rect: layout.playerHudRect,
      ownerLabel: 'JOUEUR',
      speciesLabel: 'squirtle',
      level: 25,
      currentHp: playerCurrentHp,
      maxHp: playerMaxHp,
      isPlayerSide: true,
    ),
    battleLabel: 'COMBAT SAUVAGE',
    title: 'COMMANDS',
    prompt: 'Que doit faire le joueur ?',
    narrationLines: const <String>[
      'Choisis une action.',
    ],
    entries: entries ?? _rootEntries(),
    interactionsEnabled: true,
    canGoBack: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleMobileCommandOverlay', () {
    testWidgets('renders a light prompt card with colored root actions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(
        viewportSize: const Size(390, 844),
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );

      expect(
          find.byKey(const Key('battle-mobile-prompt-card')), findsOneWidget);
      expect(
          find.byKey(const Key('battle-mobile-root-tile-0')), findsOneWidget);
      expect(
          find.byKey(const Key('battle-mobile-root-tile-3')), findsOneWidget);
    });

    testWidgets('keeps compact portrait root actions touch-friendly on iPhone',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _layoutSnapshot(
            viewportSize: const Size(390, 844),
          ),
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );

      final fightTileRect =
          tester.getRect(find.byKey(const Key('battle-mobile-root-tile-0')));
      final runTileRect =
          tester.getRect(find.byKey(const Key('battle-mobile-root-tile-3')));

      expect(fightTileRect.height, greaterThanOrEqualTo(48));
      expect(runTileRect.height, greaterThanOrEqualTo(48));
    });

    testWidgets('uses the compact portrait panel variant', (tester) async {
      const viewportSize = Size(390, 844);
      await tester.binding.setSurfaceSize(viewportSize);
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(viewportSize: viewportSize);

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: viewportSize,
        ),
      );

      expect(
        find.byKey(const Key('battle-mobile-panel-compactPortrait')),
        findsOneWidget,
      );
      final promptRect =
          tester.getRect(find.byKey(const Key('battle-mobile-prompt-card')));
      final firstActionRect =
          tester.getRect(find.byKey(const Key('battle-mobile-root-tile-0')));
      expect(promptRect.bottom, lessThan(firstActionRect.top));
    });

    testWidgets('uses the medium landscape split variant', (tester) async {
      const viewportSize = Size(844, 390);
      await tester.binding.setSurfaceSize(viewportSize);
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(viewportSize: viewportSize);

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: viewportSize,
        ),
      );

      expect(
        find.byKey(const Key('battle-mobile-panel-mediumLandscape')),
        findsOneWidget,
      );
      final promptRect =
          tester.getRect(find.byKey(const Key('battle-mobile-prompt-card')));
      final firstActionRect =
          tester.getRect(find.byKey(const Key('battle-mobile-root-tile-0')));
      expect(promptRect.right, lessThan(firstActionRect.left));
    });

    testWidgets('uses the wide desktop panel variant', (tester) async {
      const viewportSize = Size(1280, 720);
      await tester.binding.setSurfaceSize(viewportSize);
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(viewportSize: viewportSize);

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: viewportSize,
        ),
      );

      expect(
        find.byKey(const Key('battle-mobile-panel-wideDesktop')),
        findsOneWidget,
      );
      final promptRect =
          tester.getRect(find.byKey(const Key('battle-mobile-prompt-card')));
      final firstActionRect =
          tester.getRect(find.byKey(const Key('battle-mobile-root-tile-0')));
      expect(promptRect.right, lessThan(firstActionRect.left));
      expect(promptRect.width, greaterThan(260));
    });

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

    testWidgets('fight mode uses a compact two-column move grid in portrait',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(
        viewportSize: const Size(390, 844),
        mode: BattleCommandOverlayMode.fight,
        entries: <BattleCommandOverlayEntry>[
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
          _entry(
            index: 2,
            kind: BattleCommandOverlayEntryKind.move,
            primaryLabel: 'Bubble Beam',
            secondaryLabel: 'WATER · Special · Power 65',
            tone: BattleCommandOverlayEntryTone.special,
          ),
          _entry(
            index: 3,
            kind: BattleCommandOverlayEntryKind.move,
            primaryLabel: 'Protect',
            secondaryLabel: 'NORMAL · Status · Shields user',
            tone: BattleCommandOverlayEntryTone.support,
          ),
        ],
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );

      final promptRect =
          tester.getRect(find.byKey(const Key('battle-mobile-prompt-card')));
      final firstRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-0')));
      final secondRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-1')));
      final thirdRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-2')));

      expect(find.byKey(const Key('battle-mobile-entry-grid')), findsOneWidget);
      expect(promptRect.height, lessThan(58));
      expect((firstRect.top - secondRect.top).abs(), lessThan(1));
      expect(secondRect.left, greaterThan(firstRect.right));
      expect(thirdRect.top, greaterThan(firstRect.bottom));
      expect(firstRect.height, lessThan(60));
    });

    testWidgets('fight mode keeps four moves visible on compact landscape',
        (tester) async {
      const viewportSize = Size(844, 390);
      await tester.binding.setSurfaceSize(viewportSize);
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(
        viewportSize: viewportSize,
        mode: BattleCommandOverlayMode.fight,
        entries: <BattleCommandOverlayEntry>[
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
          _entry(
            index: 2,
            kind: BattleCommandOverlayEntryKind.move,
            primaryLabel: 'Bubble Beam',
            secondaryLabel: 'WATER · Special · Power 65',
            tone: BattleCommandOverlayEntryTone.special,
          ),
          _entry(
            index: 3,
            kind: BattleCommandOverlayEntryKind.move,
            primaryLabel: 'Protect',
            secondaryLabel: 'NORMAL · Status · Shields user',
            tone: BattleCommandOverlayEntryTone.support,
          ),
        ],
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: viewportSize,
        ),
      );

      final firstRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-0')));
      final fourthRect =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-3')));

      expect(find.byKey(const Key('battle-mobile-entry-grid')), findsOneWidget);
      expect(fourthRect.bottom, lessThanOrEqualTo(snapshot.panelRect.bottom));
      expect(fourthRect.top, greaterThan(firstRect.bottom));
    });

    testWidgets('compact portrait player hud keeps hp numerics visible',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(
        viewportSize: const Size(390, 844),
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );

      expect(
          find.byKey(const Key('battle-mobile-player-hp-bar')), findsOneWidget);
      expect(find.byKey(const Key('battle-mobile-player-hp-value')),
          findsOneWidget);
      expect(find.text('57/57'), findsOneWidget);
      expect(find.text('18/18'), findsNothing);
    });

    testWidgets('bag mode groups categories with compact rows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final snapshot = _layoutSnapshot(
        viewportSize: const Size(390, 844),
        mode: BattleCommandOverlayMode.bag,
        entries: <BattleCommandOverlayEntry>[
          _entry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.bag,
            primaryLabel: 'Potion',
            secondaryLabel: 'Medicine',
            trailingLabel: 'x2',
            statusLabel: 'OK',
            tone: BattleCommandOverlayEntryTone.medicine,
          ),
          _entry(
            index: 1,
            kind: BattleCommandOverlayEntryKind.bag,
            primaryLabel: 'Poke Ball',
            secondaryLabel: 'Capture',
            trailingLabel: 'x5',
            statusLabel: 'OK',
            tone: BattleCommandOverlayEntryTone.capture,
          ),
          _entry(
            index: 2,
            kind: BattleCommandOverlayEntryKind.bag,
            primaryLabel: 'Antidote',
            secondaryLabel: 'Medicine',
            trailingLabel: 'x1',
            statusLabel: 'Unsupported',
            enabled: false,
            tone: BattleCommandOverlayEntryTone.disabled,
          ),
        ],
      );

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: snapshot,
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );

      final captureHeader =
          find.byKey(const Key('battle-mobile-bag-section-Capture'));
      final medicineHeader =
          find.byKey(const Key('battle-mobile-bag-section-Medicine'));
      final firstTile =
          tester.getRect(find.byKey(const Key('battle-mobile-entry-1')));

      expect(captureHeader, findsOneWidget);
      expect(medicineHeader, findsOneWidget);
      expect(
        tester.getTopLeft(captureHeader).dy,
        lessThan(tester.getTopLeft(medicineHeader).dy),
      );
      expect(firstTile.height, lessThan(66));
    });

    testWidgets('player hp bar shrinks and turns red on low health',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _layoutSnapshot(
            viewportSize: const Size(390, 844),
            playerCurrentHp: 57,
            playerMaxHp: 57,
          ),
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final fullWidth = tester
          .getRect(find.byKey(const Key('battle-mobile-player-hp-fill')))
          .width;

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _layoutSnapshot(
            viewportSize: const Size(390, 844),
            playerCurrentHp: 10,
            playerMaxHp: 57,
          ),
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final lowFillFinder =
          find.byKey(const Key('battle-mobile-player-hp-fill-decoration'));
      final lowWidth = tester
          .getRect(find.byKey(const Key('battle-mobile-player-hp-fill')))
          .width;
      final decoration = tester.widget<DecoratedBox>(lowFillFinder).decoration
          as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;

      expect(lowWidth, lessThan(fullWidth * 0.35));
      expect(gradient.colors.last, const Color(0xFFD35B49));
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
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
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

    testWidgets('animates player hp from snapshot tween metadata',
        (tester) async {
      const playerFillKey = Key('battle-mobile-player-hp-fill');
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _layoutSnapshot(
            viewportSize: const Size(390, 844),
            playerCurrentHp: 24,
            playerMaxHp: 57,
          ),
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _hostedOverlay(
          snapshot: _snapshot(
            mode: BattleCommandOverlayMode.root,
            entries: _rootEntries(),
            viewportSize: const Size(390, 844),
            panelHeight: 260,
            playerCurrentHp: 24,
            playerMaxHp: 57,
            playerDisplayedHp: 57,
            playerTargetDisplayedHp: 24,
            playerHpTweenDurationMs: 400,
            playerHpTweenRevision: 1,
          ),
          onEntrySelected: (_) {},
          canvasSize: const Size(390, 844),
        ),
      );
      await tester.pump();

      final startFill = tester.widget<FractionallySizedBox>(
        find.byKey(playerFillKey),
      );
      expect(startFill.widthFactor, closeTo(1.0, 0.001));
      expect(find.text('57/57'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));

      final midFill = tester.widget<FractionallySizedBox>(
        find.byKey(playerFillKey),
      );
      expect(midFill.widthFactor, greaterThan(24 / 57));
      expect(midFill.widthFactor, lessThan(1.0));
      expect(find.text('24/57'), findsNothing);

      await tester.pump(const Duration(milliseconds: 220));

      final endFill = tester.widget<FractionallySizedBox>(
        find.byKey(playerFillKey),
      );
      expect(endFill.widthFactor, closeTo(24 / 57, 0.001));
      expect(find.text('24/57'), findsOneWidget);
    });
  });
}
