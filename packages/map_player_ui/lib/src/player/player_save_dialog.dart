import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_save_strings.dart';
import 'player_control_profile.dart';
import 'runtime_player_actions.dart';

class PlayerSaveDialog extends StatefulWidget {
  const PlayerSaveDialog({
    super.key,
    required this.snapshot,
    required this.onSave,
    required this.onReceiptShown,
    this.returnToTitle = false,
    this.onDiscard,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
  });

  final ValueListenable<RuntimePlayerSnapshot> snapshot;
  final Future<RuntimePlayerCommandResult> Function()? onSave;
  final ValueChanged<RuntimePlayerSaveReceipt> onReceiptShown;
  final bool returnToTitle;
  final Future<RuntimePlayerCommandResult> Function()? onDiscard;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;

  @override
  State<PlayerSaveDialog> createState() => _PlayerSaveDialogState();
}

class _PlayerSaveDialogState extends State<PlayerSaveDialog> {
  final _pendingFocus = FocusNode(skipTraversal: true);
  final _returnFocus = FocusNode();
  late final _initialSnapshot = widget.snapshot.value;
  late final _offersSave =
      _initialSnapshot.isActionEnabled(RuntimePlayerAction.save) &&
          _initialSnapshot.activeSaveAddress != null;
  var _pending = false;
  var _lastOperationSaves = true;
  String? _failure;
  RuntimePlayerSaveReceipt? _receipt;

  @override
  void dispose() {
    _pendingFocus.dispose();
    _returnFocus.dispose();
    super.dispose();
  }

  bool get _canSave =>
      widget.onSave != null &&
      widget.snapshot.value.isActionEnabled(RuntimePlayerAction.save) &&
      _initialSnapshot.activeSaveAddress != null &&
      widget.snapshot.value.activeSaveAddress ==
          _initialSnapshot.activeSaveAddress;

  bool get _canDiscard =>
      widget.onDiscard != null &&
      widget.snapshot.value.isActionEnabled(RuntimePlayerAction.returnToTitle);

  Future<void> _run({required bool save}) async {
    if (_pending || save && !_canSave || !save && !_canDiscard) {
      return;
    }
    final strings = PlayerSaveStrings.of(context);
    final previousReceipt = widget.snapshot.value.saveReceipt;
    setState(() {
      _pending = true;
      _lastOperationSaves = save;
      _failure = null;
      _receipt = null;
    });
    _pendingFocus.requestFocus();
    RuntimePlayerCommandResult result;
    try {
      result = await (save ? widget.onSave!() : widget.onDiscard!());
    } catch (_) {
      result = RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: strings.unexpectedFailure,
      );
    }
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (result.status == RuntimePlayerCommandStatus.accepted &&
        widget.returnToTitle) {
      Navigator.of(context).pop();
      return;
    }
    final receipt = widget.snapshot.value.saveReceipt;
    final saved = result.status == RuntimePlayerCommandStatus.accepted &&
        receipt != null &&
        identical(result.saveReceipt, receipt) &&
        receipt.trigger == GameSessionCheckpointTrigger.manual &&
        !identical(receipt, previousReceipt) &&
        receipt.address == _initialSnapshot.activeSaveAddress;
    setState(() {
      _pending = false;
      if (saved) {
        _receipt = receipt;
      } else {
        _failure = result.safeMessage ??
            widget.snapshot.value.failure?.safeMessage ??
            (result.status == RuntimePlayerCommandStatus.accepted
                ? strings.missingReceipt
                : strings.unexpectedFailure);
      }
    });
    if (saved) widget.onReceiptShown(receipt);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_pending) _returnFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = PlayerSaveStrings.of(context);
    final tokens = context.playerMenuTheme;
    final hasResult = _receipt != null || _failure != null;
    return PopScope(
      canPop: !_pending,
      child: RuntimePlayerActions(
        onBack: () => unawaited(Navigator.of(context).maybePop()),
        onMenu: () {},
        onInputSourceChanged: (_) {},
        child: RuntimePlayerInputBindings(
          controlProfile: widget.controlProfile,
          hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
          child: Actions(
            actions: {
              ActivateIntent:
                  CallbackAction<ActivateIntent>(onInvoke: (_) => null),
            },
            child: Focus(
              focusNode: _pendingFocus,
              child: Dialog(
                key: ValueKey(widget.returnToTitle
                    ? 'runtime-exit-dialog'
                    : 'runtime-save-dialog'),
                insetPadding: const EdgeInsets.all(PlayerSpacing.lg),
                constraints: const BoxConstraints(maxWidth: 640),
                backgroundColor: tokens.base.withValues(alpha: 0),
                elevation: 0,
                child: SizedBox(
                  width: 640,
                  child: PlayerMenuPanel(
                    key: const ValueKey('runtime-save-panel'),
                    primary: true,
                    child: LayoutBuilder(
                        builder: (context, constraints) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (hasResult)
                                          Semantics(
                                            key: const ValueKey(
                                                'runtime-save-result'),
                                            container: true,
                                            liveRegion: true,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  _receipt != null
                                                      ? strings.success
                                                      : _lastOperationSaves
                                                          ? strings.failure
                                                          : strings.exitFailure,
                                                  style: tokens.title,
                                                ),
                                                if (_failure
                                                    case final failure?) ...[
                                                  const SizedBox(
                                                      height: PlayerSpacing.md),
                                                  Text(failure,
                                                      style: tokens.body),
                                                ],
                                                if (_receipt
                                                    case final receipt?) ...[
                                                  const SizedBox(
                                                      height: PlayerSpacing.md),
                                                  Text(
                                                      strings.target(
                                                          receipt.address),
                                                      style: tokens.body),
                                                ],
                                              ],
                                            ),
                                          )
                                        else ...[
                                          Text(
                                            widget.returnToTitle
                                                ? strings.exitTitle
                                                : strings.title,
                                            style: tokens.title,
                                          ),
                                          const SizedBox(
                                              height: PlayerSpacing.lg),
                                          _summary(context, strings),
                                          if (widget.returnToTitle) ...[
                                            const SizedBox(
                                                height: PlayerSpacing.md),
                                            Text(strings.exitWarning,
                                                style: tokens.body),
                                          ],
                                        ],
                                        if (_pending) ...[
                                          const SizedBox(
                                              height: PlayerSpacing.lg),
                                          Semantics(
                                            liveRegion: true,
                                            label: _lastOperationSaves
                                                ? strings.saving
                                                : strings.exiting,
                                            excludeSemantics: true,
                                            child: Row(
                                              children: [
                                                SizedBox.square(
                                                  dimension: PlayerSpacing.lg,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: tokens.accent,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width: PlayerSpacing.sm),
                                                Expanded(
                                                  child: Text(
                                                    _lastOperationSaves
                                                        ? strings.saving
                                                        : strings.exiting,
                                                    style: tokens.body,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: PlayerSpacing.lg),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxHeight: constraints.maxHeight / 2),
                                  child: SingleChildScrollView(
                                    child: ValueListenableBuilder<
                                        RuntimePlayerSnapshot>(
                                      valueListenable: widget.snapshot,
                                      builder: (context, snapshot, _) =>
                                          _actions(context, strings),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context, PlayerSaveStrings strings) {
    final profile = _initialSnapshot.playerProfile;
    final address = _initialSnapshot.activeSaveAddress;
    final previous = _initialSnapshot.continueSave;
    final localizations = MaterialLocalizations.of(context);
    final previousMatches = previous != null &&
        address != null &&
        previous.address.gameId == address.gameId &&
        previous.address.profileId == address.profileId &&
        previous.address.slotId == address.slotId;
    final updatedAt = previousMatches ? previous.updatedAt.toLocal() : null;
    final lines = [
      if (profile != null) strings.player(profile.playerName),
      if (profile?.locationName case final name? when name.trim().isNotEmpty)
        strings.location(name),
      if (profile?.playtimeSeconds case final seconds?)
        strings.playtime(seconds),
      if (updatedAt != null)
        strings.lastSave(
          localizations.formatMediumDate(updatedAt),
          localizations.formatTimeOfDay(TimeOfDay.fromDateTime(updatedAt)),
        ),
      if (address != null) strings.target(address),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < lines.length; index++) ...[
          if (index > 0) const SizedBox(height: PlayerSpacing.xs),
          Text(lines[index], style: context.playerMenuTheme.body),
        ],
      ],
    );
  }

  Widget _actions(BuildContext context, PlayerSaveStrings strings) {
    final canSubmit = _failure != null && !_lastOperationSaves
        ? widget.onDiscard != null &&
            widget.snapshot.value
                .isActionEnabled(RuntimePlayerAction.returnToTitle)
        : _canSave;
    final buttons = <Widget>[
      PlayerActionButton(
        key: ValueKey(_receipt != null || _failure != null
            ? 'runtime-save-return'
            : widget.returnToTitle
                ? 'runtime-exit-stay'
                : 'runtime-save-cancel'),
        label: _receipt != null || _failure != null
            ? strings.back
            : widget.returnToTitle
                ? strings.stay
                : strings.cancel,
        icon: Icons.arrow_back_rounded,
        onPressed: _pending ? null : () => Navigator.of(context).pop(),
        autofocus: true,
        focusNode: _returnFocus,
        secondary: true,
        labelMaxLines: 3,
      ),
      if (_receipt == null && _failure == null && widget.returnToTitle)
        PlayerActionButton(
          key: const ValueKey('runtime-exit-discard'),
          label: strings.discard,
          icon: Icons.logout_rounded,
          onPressed: _pending || !_canDiscard
              ? null
              : () => unawaited(_run(save: false)),
          disabledReason:
              widget.onDiscard == null ? strings.discardUnavailable : null,
          secondary: true,
          labelMaxLines: 3,
        ),
      if (_receipt == null &&
          (!widget.returnToTitle || _offersSave || _failure != null))
        PlayerActionButton(
          key: ValueKey(
              _failure != null ? 'runtime-save-retry' : 'runtime-save-confirm'),
          label: _failure != null
              ? strings.retry
              : widget.returnToTitle
                  ? strings.saveAndExit
                  : strings.confirm,
          icon: _failure != null ? Icons.refresh_rounded : Icons.save_outlined,
          onPressed: _pending || !canSubmit
              ? null
              : () => unawaited(
                  _run(save: _failure == null || _lastOperationSaves)),
          disabledReason: widget.returnToTitle && widget.onSave == null
              ? strings.saveAndExitUnavailable
              : _canSave
                  ? null
                  : widget.snapshot.value
                          .unavailableReasonFor(RuntimePlayerAction.save) ??
                      strings.saveUnavailable,
          labelMaxLines: 3,
        ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 480 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < buttons.length; index++) ...[
              if (index > 0) const SizedBox(height: PlayerSpacing.sm),
              buttons[index],
            ],
          ],
        );
      }
      return Row(
        children: [
          for (var index = 0; index < buttons.length; index++) ...[
            if (index > 0) const SizedBox(width: PlayerSpacing.sm),
            Expanded(child: buttons[index]),
          ],
        ],
      );
    });
  }
}
