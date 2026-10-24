import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show PlayerInputAction, PlayerInputSource;

import 'player_dialogue_surface.dart';
import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_theme.dart';
import '../localization/player_localizations.dart';
import 'player_scene_interaction_strings.dart';
import 'runtime_player_actions.dart';
import 'runtime_prompt_localization.dart';

/// `null` signifie « pas à moi » : l'invite retombe alors sur la résolution
/// produit, puis sur son `fallbackText`.
typedef SceneInteractionPromptResolver = String? Function(
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
    this.interactionEnabled = true,
    this.errorMessage,
  });

  final SceneInteractionRequest request;
  final ValueChanged<SceneInteractionResult> onResult;
  final SceneInteractionPromptResolver? promptResolver;
  final ValueChanged<PlayerInputSource>? onInputSourceChanged;
  final bool allowCancellation;
  final bool interactionEnabled;
  final String? errorMessage;

  @override
  State<PlayerSceneInteractionSurface> createState() =>
      _PlayerSceneInteractionSurfaceState();
}

class _PlayerSceneInteractionSurfaceState
    extends State<PlayerSceneInteractionSurface> {
  static const _typewriterInterval = Duration(milliseconds: 18);

  final _textController = TextEditingController();
  final _dialoguePagination = PlayerDialoguePaginationController();
  final _textFocusNode = FocusNode(debugLabel: 'Scene interaction text');
  final _selectedOptionIds = <String>{};
  final _optionFocusNodes = <String, FocusNode>{};
  var _focusedInitialOptions = false;
  var _promptRead = false;
  var _contentWidth = 1.0;
  final _reviewedOptions = <String>{};
  SceneInteractionOption? _reviewingOption;
  String? _returnOptionId;
  SceneInteractionValidationIssue? _validationIssue;
  var _terminal = false;
  Timer? _revealTimer;
  var _revealedGraphemes = 0;

  @override
  void initState() {
    super.initState();
    _initializeText();
  }

  void _initializeText() {
    final request = widget.request;
    final text = request is SceneTextInteractionRequest
        ? request.initialValue
        : request is SceneIntegerInteractionRequest
        ? '${request.initialValue}'
        : '';
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void didUpdateWidget(covariant PlayerSceneInteractionSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRequest(oldWidget.request, widget.request)) {
      _initializeText();
      for (final node in _optionFocusNodes.values) {
        node.dispose();
      }
      _optionFocusNodes.clear();
      _focusedInitialOptions = false;
      _promptRead = false;
      _reviewingOption = null;
      _reviewedOptions.clear();
      _returnOptionId = null;
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
    _dialoguePagination.dispose();
    for (final node in _optionFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => FocusScope(
      key: ValueKey((widget.request.requestId, widget.request.revision)),
      autofocus: true,
      child: _buildContent(context, constraints),
    ),
  );

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final request = widget.request;
    if (request is SceneMessageInteractionRequest) {
      return _buildMessageDialogue(context, request);
    }
    _contentWidth = math.max(
      1.0,
      math.min(
            constraints.maxWidth - 32,
            constraints.maxWidth < 600 ? 520.0 : 680.0,
          ) -
          32,
    );
    final prompt = _resolvePrompt(request.prompt);
    final reviewing = _reviewingOption;
    if (reviewing != null) {
      return _buildReading(
        context,
        request,
        _resolvePrompt(reviewing.label),
        () => setState(() {
          _reviewedOptions.add(reviewing.id);
          _returnOptionId = reviewing.id;
          _reviewingOption = null;
          _focusedInitialOptions = false;
        }),
      );
    }
    final canCancel =
        widget.allowCancellation &&
        (request is! SceneIntegerInteractionRequest || request.allowCancel);
    if (!_promptRead &&
        _requiresReading(
          context,
          prompt,
          _contentWidth - (canCancel ? 128 : 0),
          3,
          Theme.of(context).textTheme.titleMedium,
        )) {
      return _buildReading(
        context,
        request,
        prompt,
        () => setState(() => _promptRead = true),
      );
    }
    final strings = PlayerSceneInteractionStrings.of(context);
    final validationMessage = _validationIssue == null
        ? widget.errorMessage
        : strings.validation(_validationIssue!);
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
          duration: context.playerMotion.fast,
          padding: EdgeInsets.only(
            bottom: MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(PlayerSpacing.md),
                  child: SizedBox(
                    key: const ValueKey<String>('scene-interaction-panel'),
                    width: constraints.maxWidth < 600 ? 520 : 680,
                    height: math.max(
                      0,
                      math.min(
                        620,
                        constraints.maxHeight - PlayerSpacing.md * 2,
                      ),
                    ),
                    child: PlayerSurfacePaletteScope(
                      role: ProjectPresentationSurfaceRole.dialogue,
                      child: PlayerPanel(
                        role: PlayerPanelRole.dialogue,
                        elevated: true,
                        padding: const EdgeInsets.all(PlayerSpacing.md),
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        prompt,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    if (widget.allowCancellation &&
                                        (request
                                                is! SceneIntegerInteractionRequest ||
                                            request.allowCancel))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: PlayerSpacing.xs,
                                        ),
                                        child: SizedBox(
                                          width: 120,
                                          child: PlayerActionButton(
                                            key: const ValueKey(
                                              'scene-interaction-cancel',
                                            ),
                                            label: strings.cancel,
                                            icon: Icons.close,
                                            secondary: true,
                                            onPressed: _terminal
                                                ? null
                                                : _cancel,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: PlayerSpacing.sm),
                                Expanded(
                                  child: _buildRequest(
                                    context,
                                    request,
                                    strings,
                                  ),
                                ),
                                if (validationMessage case final message?)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: PlayerSpacing.sm,
                                    ),
                                    child: Semantics(
                                      key: const ValueKey(
                                        'scene-interaction-error',
                                      ),
                                      liveRegion: true,
                                      child: Text(
                                        message,
                                        style: TextStyle(
                                          color: context.playerColors.danger,
                                        ),
                                      ),
                                    ),
                                  ),
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

  bool _requiresReading(
    BuildContext context,
    String text,
    double width,
    int lines,
    TextStyle? style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: lines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(1.0, width));
    final result = painter.didExceedMaxLines;
    painter.dispose();
    return result;
  }

  bool _reviewOption(BuildContext context, SceneInteractionOption option) {
    if (_reviewedOptions.contains(option.id) ||
        !_requiresReading(
          context,
          _resolvePrompt(option.label),
          _contentWidth - 96,
          2,
          context.playerTypography.bodyStyle(
            Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
          ),
        )) {
      return false;
    }
    setState(() => _reviewingOption = option);
    return true;
  }

  Widget _buildReading(
    BuildContext context,
    SceneInteractionRequest request,
    String text,
    VoidCallback onRead,
  ) {
    void advance() {
      if (_terminal ||
          !widget.interactionEnabled ||
          _dialoguePagination.advancePage()) {
        return;
      }
      onRead();
    }

    return Actions(
      key: const ValueKey('scene-interaction-actions'),
      actions: <Type, Action<Intent>>{
        RuntimePlayerLogicalIntent: CallbackAction<RuntimePlayerLogicalIntent>(
          onInvoke: (intent) {
            widget.onInputSourceChanged?.call(intent.source);
            if (intent.action == PlayerInputAction.confirm) advance();
            if (intent.action == PlayerInputAction.back) _cancel();
            return null;
          },
        ),
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter): advance,
          const SingleActivator(LogicalKeyboardKey.space): advance,
          const SingleActivator(LogicalKeyboardKey.escape): _cancel,
        },
        child: Focus(
          autofocus: true,
          child: PlayerDialogueSurface(
            key: ValueKey((
              'scene-interaction-reading',
              request.requestId,
              request.revision,
              _reviewingOption?.id,
            )),
            paginationController: _dialoguePagination,
            data: PlayerDialogueViewData(
              revision: request.revision,
              mode: PlayerDialogueMode.line,
              speaker: null,
              text: text,
              fullText: text,
              isCurrentLineFullyRevealed: true,
              isLastContent: _reviewingOption != null,
              choices: const [],
              isAdvanceAvailable: widget.interactionEnabled && !_terminal,
            ),
            onAction: (_) => advance(),
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
    final revealed = reduceMotion ? graphemes.length : _revealedGraphemes;
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
            paginationController: _dialoguePagination,
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
              isAdvanceAvailable: widget.interactionEnabled && !_terminal,
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
    if (_terminal || !widget.interactionEnabled) return;
    if (fullyRevealed && _dialoguePagination.advancePage()) return;
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
  ) => switch (request) {
    SceneMessageInteractionRequest() => throw StateError(
      'Messages render through the dialogue box, never the panel.',
    ),
    SceneChoiceInteractionRequest(:final options) => PlayerPagedList(
      revealChildKey: _firstOptionKey(options),
      onPageReady: () => _focusOptions(request, options),
      children: [
        for (var index = 0; index < options.length; index++)
          _choiceButton(request, options[index], index, strings),
      ],
    ),
    SceneIntegerInteractionRequest() => _integerInput(request, strings),
    SceneTextInteractionRequest() => _textInput(request, strings),
    SceneConfirmationInteractionRequest() => Row(
      children: <Widget>[
        Expanded(
          child: PlayerActionButton(
            key: const ValueKey<String>('scene-interaction-confirm-yes'),
            label: strings.yes,
            icon: Icons.check,
            autofocus: true,
            onPressed: !widget.interactionEnabled || _terminal
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
        ),
        const SizedBox(width: PlayerSpacing.xs),
        Expanded(
          child: PlayerActionButton(
            key: const ValueKey<String>('scene-interaction-confirm-no'),
            label: strings.no,
            icon: Icons.close,
            secondary: true,
            onPressed: !widget.interactionEnabled || _terminal
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
        ),
      ],
    ),
    SceneSelectionInteractionRequest(:final options) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: PlayerPagedList(
            revealChildKey: _firstOptionKey(options),
            onPageReady: () => _focusOptions(request, options),
            children: [
              for (var index = 0; index < options.length; index++)
                _selectionButton(request, options[index], index, strings),
            ],
          ),
        ),
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
          key: const ValueKey<String>('scene-interaction-selection-submit'),
          label: strings.submit,
          icon: Icons.check,
          onPressed: !widget.interactionEnabled || _terminal
              ? null
              : () => _submitSelection(request),
        ),
      ],
    ),
    SceneInteractionRequest() => const SizedBox.shrink(),
  };

  Key? _firstOptionKey(List<SceneInteractionOption> options) {
    final first =
        options
            .where((option) => option.enabled && option.id == _returnOptionId)
            .firstOrNull ??
        options.where((option) => option.enabled).firstOrNull;
    return first == null
        ? null
        : ValueKey('scene-interaction-option-${first.id}');
  }

  void _focusOptions(
    SceneInteractionRequest expected,
    List<SceneInteractionOption> options,
  ) {
    if (!mounted ||
        !_sameRequest(expected, widget.request) ||
        _focusedInitialOptions) {
      return;
    }
    final first =
        options
            .where((option) => option.enabled && option.id == _returnOptionId)
            .firstOrNull ??
        options.where((option) => option.enabled).firstOrNull;
    final node = first == null ? null : _optionFocusNodes[first.id];
    if (node != null && node.canRequestFocus) {
      _focusedInitialOptions = true;
      node.requestFocus();
    }
  }

  Widget _choiceButton(
    SceneChoiceInteractionRequest request,
    SceneInteractionOption option,
    int index,
    PlayerSceneInteractionStrings strings,
  ) => PlayerActionButton(
    key: ValueKey<String>('scene-interaction-option-${option.id}'),
    focusNode: _optionFocusNodes.putIfAbsent(
      option.id,
      () => FocusNode(
        debugLabel: 'Player action: ${_resolvePrompt(option.label)}',
      ),
    ),
    label: _resolvePrompt(option.label),
    labelMaxLines: 2,
    icon: Icons.chevron_right,
    autofocus:
        option.enabled &&
        request.options.take(index).every((candidate) => !candidate.enabled),
    disabledReason: option.enabled ? null : strings.optionUnavailable,
    onPressed: widget.interactionEnabled && !_terminal && option.enabled
        ? () {
            if (_reviewOption(context, option)) return;
            _publish(
              request,
              SceneInteractionResult.choiceSelected(
                requestId: request.requestId,
                revision: request.revision,
                selectedOptionId: option.id,
              ),
            );
          }
        : null,
  );

  Widget _integerInput(
    SceneIntegerInteractionRequest request,
    PlayerSceneInteractionStrings strings,
  ) => _SceneInteractionInputForm(
    field: TextField(
      key: const ValueKey<String>('scene-interaction-integer-field'),
      controller: _textController,
      focusNode: _textFocusNode,
      autofocus: true,
      enabled: widget.interactionEnabled && !_terminal,
      keyboardType: TextInputType.numberWithOptions(
        signed: request.minimum < 0,
      ),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(request.minimum < 0 ? r'^-?[0-9]*$' : r'[0-9]'),
        ),
        LengthLimitingTextInputFormatter(
          request.digits + (request.minimum < 0 ? 1 : 0),
        ),
      ],
      decoration: InputDecoration(
        labelText: strings.textFieldLabel,
        helperText: '${request.minimum} – ${request.maximum}',
      ),
      onChanged: (_) => setState(() => _validationIssue = null),
      onSubmitted: !widget.interactionEnabled || _terminal
          ? null
          : (_) => _submitInteger(request),
    ),
    submit: PlayerActionButton(
      key: const ValueKey<String>('scene-interaction-integer-submit'),
      label: strings.submit,
      icon: Icons.check,
      onPressed: !widget.interactionEnabled || _terminal
          ? null
          : () => _submitInteger(request),
    ),
  );

  void _submitInteger(SceneIntegerInteractionRequest request) {
    final value = int.tryParse(_textController.text);
    if (value == null) {
      setState(
        () => _validationIssue = SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.integerOutOfRange,
          arguments: {
            'minimum': '${request.minimum}',
            'maximum': '${request.maximum}',
          },
        ),
      );
      return;
    }
    _publish(
      request,
      SceneIntegerSubmittedInteractionResult(
        requestId: request.requestId,
        revision: request.revision,
        value: value,
      ),
    );
  }

  Widget _textInput(
    SceneTextInteractionRequest request,
    PlayerSceneInteractionStrings strings,
  ) {
    final maximum = request.constraints.maxGraphemes;
    final length = _textController.text.characters.length;
    return _SceneInteractionInputForm(
      field: TextField(
        key: const ValueKey<String>('scene-interaction-text-field'),
        controller: _textController,
        focusNode: _textFocusNode,
        autofocus: true,
        enabled: widget.interactionEnabled && !_terminal,
        textInputAction: TextInputAction.done,
        inputFormatters: <TextInputFormatter>[
          if (maximum != null) _CommittedGraphemeLimitFormatter(maximum),
        ],
        decoration: InputDecoration(
          labelText: strings.textFieldLabel,
          counterText: '',
        ),
        onChanged: (_) => setState(() => _validationIssue = null),
        onSubmitted: !widget.interactionEnabled || _terminal
            ? null
            : (_) => _submitText(request),
      ),
      counter: Semantics(
        liveRegion: true,
        child: Text(
          strings.characterCount(length, maximum),
          textAlign: TextAlign.end,
        ),
      ),
      submit: PlayerActionButton(
        key: const ValueKey<String>('scene-interaction-text-submit'),
        label: strings.submit,
        icon: Icons.check,
        onPressed: !widget.interactionEnabled || _terminal
            ? null
            : () => _submitText(request),
      ),
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
    final enabled =
        widget.interactionEnabled &&
        option.enabled &&
        (!_terminal &&
            (selected ||
                !maximumReached ||
                request.constraints.maxSelections == 1));
    return PlayerActionButton(
      key: ValueKey<String>('scene-interaction-option-${option.id}'),
      focusNode: _optionFocusNodes.putIfAbsent(
        option.id,
        () => FocusNode(
          debugLabel: 'Player action: ${_resolvePrompt(option.label)}',
        ),
      ),
      label: _resolvePrompt(option.label),
      labelMaxLines: 2,
      icon: selected ? Icons.check_box : Icons.check_box_outline_blank,
      autofocus:
          option.enabled &&
          request.options.take(index).every((candidate) => !candidate.enabled),
      selected: selected,
      secondary: !selected,
      trailing: selected ? Text(strings.selected) : null,
      disabledReason: !option.enabled
          ? strings.optionUnavailable
          : maximumReached && !selected
          ? strings.maximumReached
          : null,
      onPressed: enabled
          ? () {
              if (_reviewOption(context, option)) return;
              _toggleSelection(request, option.id);
            }
          : null,
    );
  }

  Object? _handleLogicalIntent(RuntimePlayerLogicalIntent intent) {
    widget.onInputSourceChanged?.call(intent.source);
    switch (intent.action) {
      case PlayerInputAction.up:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.up,
        );
      case PlayerInputAction.down:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.down,
        );
      case PlayerInputAction.left:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.left,
        );
      case PlayerInputAction.right:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.right,
        );
      case PlayerInputAction.confirm:
        final request = widget.request;
        if (_textFocusNode.hasFocus &&
            request is SceneIntegerInteractionRequest) {
          _submitInteger(request);
          return null;
        }
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
      case PlayerInputAction.bicycle:
      case PlayerInputAction.sprint:
      case PlayerInputAction.menu:
        break;
    }
    return null;
  }

  void _submitText(SceneTextInteractionRequest request) {
    if (!widget.interactionEnabled) return;
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
    if (!widget.interactionEnabled) return;
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
    if (!widget.interactionEnabled) return;
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
    if (widget.request is SceneIntegerInteractionRequest &&
        !(widget.request as SceneIntegerInteractionRequest).allowCancel) {
      return;
    }
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

  /// L'invite telle que le joueur la lit.
  ///
  /// La résolution produit est INTRINSÈQUE, pas injectée : `promptResolver`
  /// existait depuis le début et n'a jamais été branché par aucun site de
  /// production, ce qui est précisément comment chaque invite du runtime a fini
  /// affichée dans la langue où elle avait été tapée. Une couture qu'il faut
  /// penser à remplir finit par ne pas l'être.
  ///
  /// L'ordre est délibéré : un appelant qui fournit un résolveur garde le
  /// dernier mot (le Studio prévisualise autrement), puis les clés que le
  /// produit possède, puis le texte authoré.
  String _resolvePrompt(SceneInteractionPrompt prompt) {
    var value =
        widget.promptResolver?.call(prompt) ??
        localizeRuntimePrompt(prompt, context.playerL10n) ??
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

class _SceneInteractionInputForm extends StatelessWidget {
  const _SceneInteractionInputForm({
    required this.field,
    required this.submit,
    this.counter,
  });
  final Widget field;
  final Widget submit;
  final Widget? counter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.hasBoundedHeight &&
          constraints.maxHeight < 160 &&
          constraints.maxWidth >= 400) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: field),
                const SizedBox(width: PlayerSpacing.sm),
                SizedBox(width: 144, child: submit),
              ],
            ),
            if (counter case final content?)
              Padding(
                padding: const EdgeInsets.only(top: PlayerSpacing.xs),
                child: content,
              ),
          ],
        );
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          field,
          if (counter case final content?)
            Padding(
              padding: const EdgeInsets.only(top: PlayerSpacing.xs),
              child: content,
            ),
          const SizedBox(height: PlayerSpacing.sm),
          submit,
        ],
      );
    },
  );
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
