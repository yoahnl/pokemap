import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show PlayerInputAction, PlayerInputSource;

import 'player_dialogue_surface.dart';
import '../foundation/player_components.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_scene_interaction_strings.dart';
import 'runtime_player_actions.dart';

typedef SceneInteractionPromptResolver = String Function(
  SceneInteractionPrompt prompt,
);

class PlayerSceneInteractionSurface extends StatefulWidget {
  const PlayerSceneInteractionSurface({
    super.key,
    required this.request,
    required this.onResult,
    this.promptResolver,
    this.onInputSourceChanged,
    this.allowCancellation = true,
  });

  final SceneInteractionRequest request;
  final ValueChanged<SceneInteractionResult> onResult;
  final SceneInteractionPromptResolver? promptResolver;
  final ValueChanged<PlayerInputSource>? onInputSourceChanged;
  final bool allowCancellation;

  @override
  State<PlayerSceneInteractionSurface> createState() =>
      _PlayerSceneInteractionSurfaceState();
}

class _PlayerSceneInteractionSurfaceState
    extends State<PlayerSceneInteractionSurface> {
  static const _typewriterInterval = Duration(milliseconds: 18);

  final _textController = TextEditingController();
  final _textFocusNode = FocusNode(debugLabel: 'Scene interaction text');
  final _selectedOptionIds = <String>{};
  SceneInteractionValidationIssue? _validationIssue;
  var _terminal = false;
  Timer? _revealTimer;
  var _revealedGraphemes = 0;

  @override
  void didUpdateWidget(covariant PlayerSceneInteractionSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRequest(oldWidget.request, widget.request)) {
      _textController.clear();
      _selectedOptionIds.clear();
      _validationIssue = null;
      _terminal = false;
      _revealTimer?.cancel();
      _revealTimer = null;
      _revealedGraphemes = 0;
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    if (request is SceneMessageInteractionRequest) {
      return _buildMessageDialogue(context, request);
    }
    final strings = PlayerSceneInteractionStrings.of(context);
    final prompt = _resolvePrompt(request.prompt);
    return Actions(
      key: const ValueKey<String>('scene-interaction-actions'),
      actions: <Type, Action<Intent>>{
        RuntimePlayerLogicalIntent: CallbackAction<RuntimePlayerLogicalIntent>(
          onInvoke: _handleLogicalIntent,
        ),
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _cancel,
        },
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.only(
            bottom: MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.all(PlayerSpacing.md),
                  child: ConstrainedBox(
                    key: const ValueKey<String>('scene-interaction-panel'),
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth < 600 ? 520 : 680,
                    ),
                    child: PlayerSurfacePaletteScope(
                      role: ProjectPresentationSurfaceRole.dialogue,
                      child: PlayerPanel(
                      role: PlayerPanelRole.dialogue,
                      elevated: true,
                      child: Semantics(
                        scopesRoute: true,
                        namesRoute: true,
                        explicitChildNodes: true,
                        label: prompt,
                        child: FocusTraversalGroup(
                          key: ValueKey<String>(
                            'scene-interaction-${request.requestId}-${request.revision}',
                          ),
                          policy: OrderedTraversalPolicy(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                prompt,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: PlayerSpacing.md),
                              _buildRequest(context, request, strings),
                              if (_validationIssue
                                  case final issue?) ...<Widget>[
                                const SizedBox(height: PlayerSpacing.sm),
                                Semantics(
                                  key: const ValueKey<String>(
                                    'scene-interaction-error',
                                  ),
                                  liveRegion: true,
                                  child: Text(
                                    strings.validation(issue),
                                    style: TextStyle(
                                      color: context.playerColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.allowCancellation) ...<Widget>[
                                const SizedBox(height: PlayerSpacing.sm),
                                PlayerActionButton(
                                  key: const ValueKey<String>(
                                    'scene-interaction-cancel',
                                  ),
                                  label: strings.cancel,
                                  icon: Icons.close,
                                  secondary: true,
                                  onPressed: _terminal ? null : _cancel,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The paginated dialogue box over the maintained Presentation frame —
  /// BETA-CIN-074. No opaque scrim: the staging stays visible. The first
  /// press completes the typewriter, the next one acknowledges the page
  /// exactly once; keyboard confirm and tap share the same advance.
  Widget _buildMessageDialogue(
    BuildContext context,
    SceneMessageInteractionRequest request,
  ) {
    final fullText = _resolvePrompt(request.prompt);
    final graphemes = fullText.characters;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final revealed =
        reduceMotion ? graphemes.length : _revealedGraphemes;
    final fullyRevealed = revealed >= graphemes.length;
    if (!fullyRevealed && _revealTimer == null) {
      _revealTimer = Timer.periodic(_typewriterInterval, (_) {
        setState(() {
          _revealedGraphemes += 1;
          if (_revealedGraphemes >= graphemes.length) {
            _revealTimer?.cancel();
            _revealTimer = null;
          }
        });
      });
    }
    return Actions(
      key: const ValueKey<String>('scene-interaction-actions'),
      actions: <Type, Action<Intent>>{
        RuntimePlayerLogicalIntent: CallbackAction<RuntimePlayerLogicalIntent>(
          onInvoke: (intent) {
            widget.onInputSourceChanged?.call(intent.source);
            switch (intent.action) {
              case PlayerInputAction.confirm:
                _advanceMessage(request, fullyRevealed: fullyRevealed);
              case PlayerInputAction.back:
                _cancel();
              default:
                break;
            }
            return null;
          },
        ),
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _cancel,
          const SingleActivator(LogicalKeyboardKey.enter): () =>
              _advanceMessage(request, fullyRevealed: fullyRevealed),
          const SingleActivator(LogicalKeyboardKey.space): () =>
              _advanceMessage(request, fullyRevealed: fullyRevealed),
        },
        child: Focus(
          autofocus: true,
          child: PlayerDialogueSurface(
            key: const ValueKey<String>('scene-interaction-message-dialogue'),
            data: PlayerDialogueViewData(
              revision: request.revision,
              mode: PlayerDialogueMode.line,
              speaker: request.speakerName,
              text: fullyRevealed
                  ? fullText
                  : graphemes.take(revealed).toString(),
              fullText: fullText,
              isCurrentLineFullyRevealed: fullyRevealed,
              isLastContent: false,
              choices: const <PlayerDialogueChoiceViewData>[],
            ),
            onAction: (_) =>
                _advanceMessage(request, fullyRevealed: fullyRevealed),
          ),
        ),
      ),
    );
  }

  void _advanceMessage(
    SceneMessageInteractionRequest request, {
    required bool fullyRevealed,
  }) {
    if (_terminal) return;
    if (!fullyRevealed) {
      setState(() {
        _revealTimer?.cancel();
        _revealTimer = null;
        _revealedGraphemes = _resolvePrompt(request.prompt).characters.length;
      });
      return;
    }
    _publish(
      request,
      SceneInteractionResult.acknowledged(
        requestId: request.requestId,
        revision: request.revision,
      ),
    );
  }

  Widget _buildRequest(
    BuildContext context,
    SceneInteractionRequest request,
    PlayerSceneInteractionStrings strings,
  ) =>
      switch (request) {
        SceneMessageInteractionRequest() => throw StateError(
            'Messages render through the dialogue box, never the panel.',
          ),
        SceneChoiceInteractionRequest(:final options) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var index = 0; index < options.length; index++) ...<Widget>[
                _choiceButton(request, options[index], index, strings),
                if (index < options.length - 1)
                  const SizedBox(height: PlayerSpacing.xs),
              ],
            ],
          ),
        SceneTextInteractionRequest() => _textInput(request, strings),
        SceneConfirmationInteractionRequest() => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PlayerActionButton(
                key: const ValueKey<String>('scene-interaction-confirm-yes'),
                label: strings.yes,
                icon: Icons.check,
                autofocus: true,
                onPressed: _terminal
                    ? null
                    : () => _publish(
                          request,
                          SceneInteractionResult.confirmed(
                            requestId: request.requestId,
                            revision: request.revision,
                            value: true,
                          ),
                        ),
              ),
              const SizedBox(height: PlayerSpacing.xs),
              PlayerActionButton(
                key: const ValueKey<String>('scene-interaction-confirm-no'),
                label: strings.no,
                icon: Icons.close,
                secondary: true,
                onPressed: _terminal
                    ? null
                    : () => _publish(
                          request,
                          SceneInteractionResult.confirmed(
                            requestId: request.requestId,
                            revision: request.revision,
                            value: false,
                          ),
                        ),
              ),
            ],
          ),
        SceneSelectionInteractionRequest(:final options) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var index = 0; index < options.length; index++) ...<Widget>[
                _selectionButton(request, options[index], index, strings),
                if (index < options.length - 1)
                  const SizedBox(height: PlayerSpacing.xs),
              ],
              const SizedBox(height: PlayerSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  strings.selectionCount(
                    _selectedOptionIds.length,
                    request.constraints.minSelections,
                    request.constraints.maxSelections,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: PlayerSpacing.sm),
              PlayerActionButton(
                key: const ValueKey<String>(
                  'scene-interaction-selection-submit',
                ),
                label: strings.submit,
                icon: Icons.check,
                onPressed: _terminal ? null : () => _submitSelection(request),
              ),
            ],
          ),
        SceneInteractionRequest() => const SizedBox.shrink(),
      };

  Widget _choiceButton(
    SceneChoiceInteractionRequest request,
    SceneInteractionOption option,
    int index,
    PlayerSceneInteractionStrings strings,
  ) =>
      PlayerActionButton(
        key: ValueKey<String>('scene-interaction-option-${option.id}'),
        label: _resolvePrompt(option.label),
        // An option is prose, not a command word: it must stay readable rather
        // than ellipsize, or the player is choosing blind.
        labelMaxLines: 2,
        icon: Icons.chevron_right,
        autofocus: option.enabled &&
            request.options
                .take(index)
                .every((candidate) => !candidate.enabled),
        disabledReason: option.enabled ? null : strings.optionUnavailable,
        onPressed: !_terminal && option.enabled
            ? () => _publish(
                  request,
                  SceneInteractionResult.choiceSelected(
                    requestId: request.requestId,
                    revision: request.revision,
                    selectedOptionId: option.id,
                  ),
                )
            : null,
      );

  Widget _textInput(
    SceneTextInteractionRequest request,
    PlayerSceneInteractionStrings strings,
  ) {
    final maximum = request.constraints.maxGraphemes;
    final length = _textController.text.characters.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('scene-interaction-text-field'),
          controller: _textController,
          focusNode: _textFocusNode,
          autofocus: true,
          enabled: !_terminal,
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            if (maximum != null) _CommittedGraphemeLimitFormatter(maximum),
          ],
          decoration: InputDecoration(
            labelText: strings.textFieldLabel,
            counterText: '',
          ),
          onChanged: (_) => setState(() => _validationIssue = null),
          onSubmitted: _terminal ? null : (_) => _submitText(request),
        ),
        const SizedBox(height: PlayerSpacing.xs),
        Semantics(
          liveRegion: true,
          child: Text(
            strings.characterCount(length, maximum),
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(height: PlayerSpacing.sm),
        PlayerActionButton(
          key: const ValueKey<String>('scene-interaction-text-submit'),
          label: strings.submit,
          icon: Icons.check,
          onPressed: _terminal ? null : () => _submitText(request),
        ),
      ],
    );
  }

  Widget _selectionButton(
    SceneSelectionInteractionRequest request,
    SceneInteractionOption option,
    int index,
    PlayerSceneInteractionStrings strings,
  ) {
    final selected = _selectedOptionIds.contains(option.id);
    final maximumReached =
        _selectedOptionIds.length >= request.constraints.maxSelections;
    final enabled = option.enabled &&
        (!_terminal &&
            (selected ||
                !maximumReached ||
                request.constraints.maxSelections == 1));
    return PlayerActionButton(
      key: ValueKey<String>('scene-interaction-option-${option.id}'),
      label: _resolvePrompt(option.label),
      labelMaxLines: 2,
      icon: selected ? Icons.check_box : Icons.check_box_outline_blank,
      autofocus: option.enabled &&
          request.options.take(index).every((candidate) => !candidate.enabled),
      selected: selected,
      secondary: !selected,
      trailing: selected ? Text(strings.selected) : null,
      disabledReason: !option.enabled
          ? strings.optionUnavailable
          : maximumReached && !selected
              ? strings.maximumReached
              : null,
      onPressed: enabled ? () => _toggleSelection(request, option.id) : null,
    );
  }

  Object? _handleLogicalIntent(RuntimePlayerLogicalIntent intent) {
    widget.onInputSourceChanged?.call(intent.source);
    switch (intent.action) {
      case PlayerInputAction.up:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.up);
      case PlayerInputAction.down:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.down);
      case PlayerInputAction.left:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.left);
      case PlayerInputAction.right:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.right);
      case PlayerInputAction.confirm:
        final request = widget.request;
        if (_textFocusNode.hasFocus && request is SceneTextInteractionRequest) {
          _submitText(request);
          break;
        }
        final focusContext = FocusManager.instance.primaryFocus?.context;
        if (focusContext != null) {
          Actions.invoke(focusContext, const ActivateIntent());
        }
      case PlayerInputAction.back:
        _cancel();
      case PlayerInputAction.menu:
        break;
    }
    return null;
  }

  void _submitText(SceneTextInteractionRequest request) {
    _publish(
      request,
      SceneInteractionResult.textSubmitted(
        requestId: request.requestId,
        revision: request.revision,
        value: _textController.text,
      ),
    );
  }

  void _toggleSelection(
    SceneSelectionInteractionRequest request,
    String optionId,
  ) {
    setState(() {
      _validationIssue = null;
      if (_selectedOptionIds.remove(optionId)) return;
      if (request.constraints.maxSelections == 1) {
        _selectedOptionIds.clear();
      }
      if (_selectedOptionIds.length < request.constraints.maxSelections) {
        _selectedOptionIds.add(optionId);
      }
    });
  }

  void _submitSelection(SceneSelectionInteractionRequest request) {
    final selected = request.options
        .where((option) => _selectedOptionIds.contains(option.id))
        .map((option) => option.id)
        .toList(growable: false);
    _publish(
      request,
      SceneInteractionResult.selectionSubmitted(
        requestId: request.requestId,
        revision: request.revision,
        selectedOptionIds: selected,
      ),
    );
  }

  void _cancel() {
    if (!widget.allowCancellation) return;
    final request = widget.request;
    _publish(
      request,
      SceneInteractionResult.cancelled(
        requestId: request.requestId,
        revision: request.revision,
        reason: SceneInteractionCancellationReason.user,
      ),
    );
  }

  void _publish(
    SceneInteractionRequest expectedRequest,
    SceneInteractionResult result,
  ) {
    if (_terminal || !_sameRequest(expectedRequest, widget.request)) return;
    final issues = expectedRequest.validateResult(result);
    if (issues.isNotEmpty) {
      setState(() => _validationIssue = issues.first);
      return;
    }
    setState(() {
      _terminal = true;
      _validationIssue = null;
      _revealTimer?.cancel();
      _revealTimer = null;
    });
    widget.onResult(result);
  }

  String _resolvePrompt(SceneInteractionPrompt prompt) {
    var value = widget.promptResolver?.call(prompt) ??
        prompt.fallbackText ??
        prompt.localizationKey;
    for (final entry in prompt.arguments.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  bool _sameRequest(
    SceneInteractionRequest left,
    SceneInteractionRequest right,
  ) =>
      left.requestId == right.requestId &&
      left.revision == right.revision &&
      left.kind == right.kind;
}

final class _CommittedGraphemeLimitFormatter extends TextInputFormatter {
  const _CommittedGraphemeLimitFormatter(this.maximum);

  final int maximum;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    if (newValue.text.characters.length <= maximum) return newValue;
    final text = newValue.text.characters.take(maximum).toString();
    final offset = newValue.selection.extentOffset.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
