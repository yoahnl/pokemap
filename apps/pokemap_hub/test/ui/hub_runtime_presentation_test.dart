import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  testWidgets('composes Flame view with canonical Flutter battle commands',
      (tester) async {
    final controller = _FakePresentationController()
      ..battle.value = _battleSnapshot();

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: HubRuntimePresentation(
            controller: controller,
            gameView: const ColoredBox(
              key: ValueKey<String>('flame-scene'),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );

    expect(controller.enabled, isTrue);
    expect(find.byKey(const ValueKey<String>('flame-scene')), findsOneWidget);
    expect(find.text('Tonnerre'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('battle-entry-0')));
    expect(controller.battleCommands, hasLength(1));
    expect(controller.battleCommands.single, isA<BattleSelectEntryCommand>());

    await tester.pumpWidget(const SizedBox.shrink());
    expect(controller.enabled, isFalse);
  });
}

final class _FakePresentationController
    implements HubRuntimePresentationController {
  final battle = ValueNotifier<BattleCommandOverlaySnapshot?>(null);
  final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(null);
  final postBattle = ValueNotifier<PostBattlePresentationSnapshot?>(null);
  final notification = ValueNotifier<RuntimeNotificationSnapshot?>(null);
  final battleCommands = <BattlePresentationCommand>[];
  bool enabled = false;

  @override
  ValueListenable<BattleCommandOverlaySnapshot?>
      get battlePresentationListenable => battle;

  @override
  ValueListenable<DialoguePresentationSnapshot?>
      get dialoguePresentationListenable => dialogue;

  @override
  ValueListenable<RuntimeNotificationSnapshot?>
      get notificationPresentationListenable => notification;

  @override
  ValueListenable<PostBattlePresentationSnapshot?>
      get postBattlePresentationListenable => postBattle;

  @override
  bool dispatchBattle(BattlePresentationCommand command) {
    battleCommands.add(command);
    return true;
  }

  @override
  bool dispatchDialogue(DialoguePresentationCommand command) => true;

  @override
  bool dispatchPostBattle(PostBattlePresentationCommand command) => true;

  @override
  void setPlayerPresentationEnabled(bool enabled) {
    this.enabled = enabled;
  }
}

BattleCommandOverlaySnapshot _battleSnapshot() {
  const hud = BattleCommandOverlayHudSnapshot(
    rect: Rect.fromLTWH(12, 12, 150, 64),
    ownerLabel: 'JOUEUR',
    speciesLabel: 'Pikachu',
    level: 30,
    currentHp: 60,
    maxHp: 70,
    isPlayerSide: true,
  );
  return const BattleCommandOverlaySnapshot(
    revision: 3,
    mode: BattleCommandOverlayMode.fight,
    panelRect: Rect.fromLTWH(12, 300, 360, 260),
    enemyHud: hud,
    playerHud: hud,
    battleLabel: 'COMBAT',
    title: 'CAPACITÉS',
    prompt: 'Choisissez.',
    narrationLines: <String>[],
    entries: <BattleCommandOverlayEntry>[
      BattleCommandOverlayEntry(
        index: 0,
        kind: BattleCommandOverlayEntryKind.move,
        primaryLabel: 'Tonnerre',
        secondaryLabel: 'PP 12/15',
        enabled: true,
        selected: true,
        tone: BattleCommandOverlayEntryTone.special,
      ),
    ],
    interactionsEnabled: true,
    canGoBack: true,
  );
}
