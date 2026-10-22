import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

class StudioPlaytestPlayerView extends StatefulWidget {
  const StudioPlaytestPlayerView({
    super.key,
    required this.game,
    required this.bundle,
    required this.services,
  });

  final PlayableMapGame game;
  final RuntimeMapBundle bundle;
  final PlayerServiceRuntimeController services;

  @override
  State<StudioPlaytestPlayerView> createState() =>
      _StudioPlaytestPlayerViewState();
}

class _StudioPlaytestPlayerViewState extends State<StudioPlaytestPlayerView>
    with WidgetsBindingObserver {
  final _gameFocus = FocusNode(debugLabel: 'Studio playtest');
  bool _acceptsOverworldInput = false;
  bool _lifecycleActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.game.inputAuthorityListenable.addListener(_handleInputAuthority);
    widget.game.testSpeed.addListener(_restoreTestInputFocus);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _setLifecycleActive(
      lifecycle == null || lifecycle == AppLifecycleState.resumed,
    );
  }

  void _handleInputAuthority() {
    final accepts =
        widget.game.inputAuthorityListenable.value.acceptsOverworldInput;
    if (accepts && !_acceptsOverworldInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _lifecycleActive &&
            widget.game.inputAuthorityListenable.value.acceptsOverworldInput) {
          _gameFocus.requestFocus();
        }
      });
    }
    _acceptsOverworldInput = accepts;
  }

  void _restoreTestInputFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _lifecycleActive &&
          widget.game.inputAuthoritySnapshot.acceptsOverworldInput) {
        _gameFocus.requestFocus();
      }
    });
  }

  void _setLifecycleActive(bool active) {
    _lifecycleActive = active;
    widget.game.setExternalInputLock(
      RuntimeExternalInputLock.lifecycle,
      locked: !active,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _setLifecycleActive(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.game.inputAuthorityListenable.removeListener(_handleInputAuthority);
    widget.game.testSpeed.removeListener(_restoreTestInputFocus);
    _gameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final profile = widget.bundle.manifest.presentation;
    final presentation = profile == null
        ? null
        : RuntimePlayerPresentation.fromProfile(profile);
    final baseTheme = Theme.of(context).brightness == Brightness.dark
        ? PokeMapPlayerTheme.dark()
        : PokeMapPlayerTheme.light();
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget<PlayableMapGame>(
            key: ObjectKey(game),
            game: game,
            focusNode: _gameFocus,
            autofocus: true,
            errorBuilder: (context, error) =>
                Center(child: Text('Erreur du test : $error')),
          ),
          Positioned.fill(
            child: Localizations.override(
              context: context,
              delegates: PokeMapPlayerLocalizations.localizationsDelegates,
              child: Theme(
                data: presentation?.applyTo(baseTheme) ?? baseTheme,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ValueListenableBuilder<DialoguePresentationSnapshot?>(
                      valueListenable: game.dialoguePresentationListenable,
                      builder: (context, snapshot, _) => snapshot == null
                          ? const SizedBox.shrink()
                          : PlayerDialogueOverlay(
                              snapshot: snapshot,
                              onCommand:
                                  game.dispatchDialoguePresentationCommand,
                            ),
                    ),
                    ValueListenableBuilder<BattleCommandOverlaySnapshot?>(
                      valueListenable: game.battleCommandOverlayListenable,
                      builder: (context, snapshot, _) => snapshot == null
                          ? const SizedBox.shrink()
                          : PlayerBattleOverlay(
                              snapshot: snapshot,
                              onCommand: game.dispatchBattlePresentationCommand,
                            ),
                    ),
                    StreamBuilder<RuntimeWorldServiceSnapshot?>(
                      stream: widget.services.worldServiceSnapshots,
                      initialData: widget.services.worldServiceSnapshot,
                      builder: (context, snapshot) {
                        final service = snapshot.data;
                        if (service == null) return const SizedBox.shrink();
                        void command(RuntimeWorldServiceCommand value) {
                          if (_lifecycleActive) {
                            unawaited(
                              widget.services.dispatchWorldService(value),
                            );
                          }
                        }

                        return switch (service.request.kind) {
                          RuntimeWorldServiceKind.heal =>
                            PlayerHealConfirmation(
                              snapshot: service,
                              onCommand: command,
                            ),
                          RuntimeWorldServiceKind.shop => PlayerShopOverlay(
                            snapshot: service,
                            onCommand: command,
                          ),
                          RuntimeWorldServiceKind.pc => PlayerPcOverlay(
                            snapshot: service,
                            onCommand: command,
                          ),
                          RuntimeWorldServiceKind.pokemonGift =>
                            PlayerPokemonGiftOverlay(
                              snapshot: service,
                              onCommand: command,
                            ),
                          RuntimeWorldServiceKind.textInput =>
                            PlayerTextInputOverlay(
                              snapshot: service,
                              onCommand: command,
                            ),
                          RuntimeWorldServiceKind.regionalMap =>
                            PlayerRegionalMapOverlay(
                              snapshot: service,
                              onCommand: command,
                            ),
                          RuntimeWorldServiceKind.partyTrade =>
                            PlayerPartyTradeOverlay(
                              snapshot: service,
                              onCommand: command,
                            ),
                        };
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
