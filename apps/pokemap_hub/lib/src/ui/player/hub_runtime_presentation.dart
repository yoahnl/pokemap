import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

/// Port étroit entre le shell Hub et le runtime de session jetable.
abstract interface class HubRuntimePresentationController {
  ValueListenable<BattleCommandOverlaySnapshot?>
      get battlePresentationListenable;
  ValueListenable<DialoguePresentationSnapshot?>
      get dialoguePresentationListenable;
  ValueListenable<PostBattlePresentationSnapshot?>
      get postBattlePresentationListenable;
  ValueListenable<RuntimeNotificationSnapshot?>
      get notificationPresentationListenable;

  void setPlayerPresentationEnabled(bool enabled);
  bool dispatchBattle(BattlePresentationCommand command);
  bool dispatchDialogue(DialoguePresentationCommand command);
  bool dispatchPostBattle(PostBattlePresentationCommand command);
}

/// Adaptateur production vers l'unique `PlayableMapGame` de la session.
final class PlayableMapGamePresentationController
    implements HubRuntimePresentationController {
  const PlayableMapGamePresentationController(this.game);

  final PlayableMapGame game;

  @override
  ValueListenable<BattleCommandOverlaySnapshot?>
      get battlePresentationListenable => game.battleCommandOverlayListenable;

  @override
  ValueListenable<DialoguePresentationSnapshot?>
      get dialoguePresentationListenable => game.dialoguePresentationListenable;

  @override
  ValueListenable<PostBattlePresentationSnapshot?>
      get postBattlePresentationListenable =>
          game.postBattlePresentationListenable;

  @override
  ValueListenable<RuntimeNotificationSnapshot?>
      get notificationPresentationListenable =>
          game.runtimeNotificationListenable;

  @override
  void setPlayerPresentationEnabled(bool enabled) {
    game
      ..setBattleFlutterCommandOverlayPreferred(enabled)
      ..setDialogueFlutterOverlayPreferred(enabled)
      ..setPostBattleFlutterOverlayPreferred(enabled)
      ..setFlutterNotificationsPreferred(enabled);
  }

  @override
  bool dispatchBattle(BattlePresentationCommand command) =>
      game.dispatchBattlePresentationCommand(command);

  @override
  bool dispatchDialogue(DialoguePresentationCommand command) =>
      game.dispatchDialoguePresentationCommand(command);

  @override
  bool dispatchPostBattle(PostBattlePresentationCommand command) =>
      game.dispatchPostBattlePresentationCommand(command);
}

/// Compose la scène Flame et toutes les surfaces joueur Flutter de Phase 6.
class HubRuntimePresentation extends StatefulWidget {
  const HubRuntimePresentation({
    super.key,
    required this.controller,
    required this.gameView,
    this.preferences = const player_ui.PlayerPreferences(),
    this.feedback,
    this.assetPreloader,
    this.itemIconBuilder,
    this.portraitBuilder,
  });

  final HubRuntimePresentationController controller;
  final Widget gameView;
  final player_ui.PlayerPreferences preferences;
  final player_ui.PlayerFeedbackController? feedback;
  final player_ui.PlayerAssetPreloader? assetPreloader;
  final Widget Function(String assetPath)? itemIconBuilder;
  final Widget Function(String speaker)? portraitBuilder;

  @override
  State<HubRuntimePresentation> createState() => _HubRuntimePresentationState();
}

class _HubRuntimePresentationState extends State<HubRuntimePresentation> {
  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(covariant HubRuntimePresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _attach(widget.controller);
    }
  }

  void _attach(HubRuntimePresentationController controller) {
    controller.setPlayerPresentationEnabled(true);
    controller.battlePresentationListenable.addListener(_onBattleChanged);
    controller.dialoguePresentationListenable.addListener(_onDialogueChanged);
    controller.postBattlePresentationListenable
        .addListener(_onPostBattleChanged);
    controller.notificationPresentationListenable
        .addListener(_onNotificationChanged);
    _onBattleChanged();
  }

  void _detach(HubRuntimePresentationController controller) {
    controller.battlePresentationListenable.removeListener(_onBattleChanged);
    controller.dialoguePresentationListenable
        .removeListener(_onDialogueChanged);
    controller.postBattlePresentationListenable
        .removeListener(_onPostBattleChanged);
    controller.notificationPresentationListenable
        .removeListener(_onNotificationChanged);
    controller.setPlayerPresentationEnabled(false);
  }

  void _onBattleChanged() {
    final snapshot = widget.controller.battlePresentationListenable.value;
    if (snapshot == null) return;
    final paths = snapshot.entries
        .map((entry) => entry.iconAssetPath)
        .whereType<String>();
    final preloader = widget.assetPreloader;
    if (preloader != null) {
      unawaited(preloader.preload(paths));
    }
    if (snapshot.phase == BattlePresentationPhase.presentingTurn) {
      _feedback(
        player_ui.PlayerFeedbackEvent(
          id: 'battle:${snapshot.revision}',
          sound: player_ui.PlayerFeedbackSound.battleImpact,
          haptic: player_ui.PlayerFeedbackHaptic.lightImpact,
        ),
      );
    }
  }

  void _onDialogueChanged() {
    final snapshot = widget.controller.dialoguePresentationListenable.value;
    if (snapshot == null) return;
    _feedback(
      player_ui.PlayerFeedbackEvent(
        id: 'dialogue:${snapshot.revision}',
        sound: player_ui.PlayerFeedbackSound.dialogue,
        haptic: snapshot.mode == DialoguePresentationMode.choices
            ? player_ui.PlayerFeedbackHaptic.selection
            : null,
      ),
    );
  }

  void _onPostBattleChanged() {
    final snapshot = widget.controller.postBattlePresentationListenable.value;
    if (snapshot == null) return;
    final isError = snapshot.messageKind == RuntimePostBattleMessageKind.error;
    final isVictory =
        snapshot.messageKind == RuntimePostBattleMessageKind.victory;
    _feedback(
      player_ui.PlayerFeedbackEvent(
        id: 'post-battle:${snapshot.revision}',
        sound: isError
            ? player_ui.PlayerFeedbackSound.error
            : isVictory
                ? player_ui.PlayerFeedbackSound.victory
                : player_ui.PlayerFeedbackSound.confirm,
        haptic: isError
            ? player_ui.PlayerFeedbackHaptic.error
            : isVictory
                ? player_ui.PlayerFeedbackHaptic.success
                : player_ui.PlayerFeedbackHaptic.lightImpact,
      ),
    );
  }

  void _onNotificationChanged() {
    final snapshot = widget.controller.notificationPresentationListenable.value;
    if (snapshot == null) return;
    _feedback(
      player_ui.PlayerFeedbackEvent(
        id: 'notification:${snapshot.revision}',
        sound: snapshot.tone == RuntimeNotificationTone.error
            ? player_ui.PlayerFeedbackSound.error
            : player_ui.PlayerFeedbackSound.notification,
        haptic: snapshot.tone == RuntimeNotificationTone.error
            ? player_ui.PlayerFeedbackHaptic.error
            : player_ui.PlayerFeedbackHaptic.lightImpact,
      ),
    );
  }

  void _feedback(player_ui.PlayerFeedbackEvent event) {
    final feedback = widget.feedback;
    if (feedback != null) {
      unawaited(feedback.handle(event, widget.preferences));
    }
  }

  @override
  void dispose() {
    _detach(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.gameView,
        ValueListenableBuilder<BattleCommandOverlaySnapshot?>(
          valueListenable: widget.controller.battlePresentationListenable,
          builder: (context, snapshot, _) => snapshot == null
              ? const SizedBox.shrink()
              : player_ui.PlayerBattleOverlay(
                  snapshot: snapshot,
                  onCommand: widget.controller.dispatchBattle,
                  itemIconBuilder: widget.itemIconBuilder,
                ),
        ),
        ValueListenableBuilder<DialoguePresentationSnapshot?>(
          valueListenable: widget.controller.dialoguePresentationListenable,
          builder: (context, snapshot, _) => snapshot == null
              ? const SizedBox.shrink()
              : player_ui.PlayerDialogueOverlay(
                  snapshot: snapshot,
                  onCommand: widget.controller.dispatchDialogue,
                  portraitBuilder: widget.portraitBuilder,
                ),
        ),
        ValueListenableBuilder<PostBattlePresentationSnapshot?>(
          valueListenable: widget.controller.postBattlePresentationListenable,
          builder: (context, snapshot, _) => snapshot == null
              ? const SizedBox.shrink()
              : player_ui.PlayerPostBattleOverlay(
                  snapshot: snapshot,
                  onCommand: widget.controller.dispatchPostBattle,
                ),
        ),
        ValueListenableBuilder<RuntimeNotificationSnapshot?>(
          valueListenable: widget.controller.notificationPresentationListenable,
          builder: (context, snapshot, _) => snapshot == null
              ? const SizedBox.shrink()
              : player_ui.PlayerNotificationOverlay(snapshot: snapshot),
        ),
      ],
    );
  }
}
