import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show PlayerInputAction, PlayerInputSource;

import 'player_dialogue_surface.dart';
import 'player_scene_keyboard.dart';
import '../foundation/player_input_scope.dart';
import '../theme/pokemap_player_window_theme.dart';
import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
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
  final _inputFieldKey = GlobalKey();
  final _dialoguePagination = PlayerDialoguePaginationController();
  final _textFocusNode = FocusNode(debugLabel: 'Scene interaction text');
  final _selectedOptionIds = <String>{};
  final _optionFocusNodes = <String, FocusNode>{};
  var _focusedInitialOptions = false;
  var _promptRead = false;
  var _contentWidth = 1.0;
  var _choiceColumns = 1;
  final _reviewedOptions = <String>{};
  SceneInteractionOption? _reviewingOption;
  String? _returnOptionId;
  SceneInteractionValidationIssue? _validationIssue;
  var _terminal = false;
  Timer? _revealTimer;
  var _revealedGraphemes = 0;
  final _naturalHeights = <String, double>{};
  (double, double, int)? _naturalLayoutSignature;

  void _rememberHeight(String id, double height) {
    if (!mounted || _naturalHeights[id] == height) return;
    setState(() => _naturalHeights[id] = height);
  }

  Widget _measure(String id, Widget child) => _SceneContentMeasure(
    epoch: (
      widget.request.requestId,
      widget.request.revision,
      _naturalLayoutSignature,
    ),
    onHeight: (height) => _rememberHeight(id, height),
    child: child,
  );

  double? _requestHeight(SceneInteractionRequest request) => switch (request) {
    SceneChoiceInteractionRequest() => _naturalHeights['options'],
    SceneSelectionInteractionRequest() =>
      _naturalHeights['options'] == null ||
              _naturalHeights['selection-footer'] == null
          ? null
          : _naturalHeights['options']! +
                PlayerSpacing.sm +
                _naturalHeights['selection-footer']!,
    SceneConfirmationInteractionRequest() => _naturalHeights['confirmation'],
    _ => _naturalHeights['form'],
  };

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
      _naturalHeights.clear();
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
  Widget build(BuildContext context) => PlayerMenuThemeScope(
    role: ProjectPresentationSurfaceRole.dialogue,
    child: LayoutBuilder(
      builder: (context, constraints) => FocusScope(
        key: ValueKey((widget.request.requestId, widget.request.revision)),
        autofocus: true,
        child: _buildContent(context, constraints),
      ),
    ),
  );

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final request = widget.request;
    if (request is SceneMessageInteractionRequest) {
      return _buildMessageDialogue(context, request);
    }
    final selection = request is SceneSelectionInteractionRequest;
    final form =
        request is SceneTextInteractionRequest ||
        request is SceneIntegerInteractionRequest;
    final fullScreen =
        selection ||
        form ||
        (PlayerCompanionScope.of(context) &&
            request is SceneChoiceInteractionRequest);
    final centered = request is SceneConfirmationInteractionRequest;
    final panelWidth = fullScreen
        ? constraints.maxWidth
        : centered
        ? 500.0
        : 680.0;
    _contentWidth = math.max(
      1.0,
      math.min(constraints.maxWidth - 32, panelWidth) - 32,
    );
    _choiceColumns =
        (request is SceneChoiceInteractionRequest || selection) &&
            constraints.maxWidth > constraints.maxHeight &&
            _contentWidth >= 480 &&
            MediaQuery.textScalerOf(context).scale(1) < 1.5
        ? 2
        : 1;
    final signature = (
      _contentWidth,
      MediaQuery.textScalerOf(context).scale(1),
      _choiceColumns,
    );
    if (_naturalLayoutSignature != signature) {
      _naturalLayoutSignature = signature;
      _naturalHeights.clear();
    }
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
    final strings = PlayerSceneInteractionStrings.of(context);
    final promptStyle = context.playerMenuTheme.title.copyWith(
      fontSize: centered ? 20 : 24,
    );
    const cancelWidth = 48.0;
    final canCancel =
        widget.allowCancellation &&
        (request is! SceneIntegerInteractionRequest || request.allowCancel);
    if (!_promptRead &&
        _requiresReading(
          context,
          prompt,
          _contentWidth - (canCancel ? cancelWidth + PlayerSpacing.xs : 0),
          3,
          promptStyle,
        )) {
      return _buildReading(
        context,
        request,
        prompt,
        () => setState(() => _promptRead = true),
      );
    }
    final validationMessage = _validationIssue == null
        ? widget.errorMessage
        : strings.validation(_validationIssue!);
    final headerId = 'header-$prompt';
    final errorId = 'error-$validationMessage';
    final headerHeight = _naturalHeights[headerId];
    final requestHeight = _requestHeight(request);
    final errorHeight = validationMessage == null
        ? 0.0
        : _naturalHeights[errorId];
    final naturalHeight =
        headerHeight == null || requestHeight == null || errorHeight == null
        ? null
        : PlayerSpacing.md * 2 +
              headerHeight +
              PlayerSpacing.sm +
              requestHeight +
              (validationMessage == null ? 0 : PlayerSpacing.sm + errorHeight);
    return ColoredBox(
      color: fullScreen
          ? context.playerMenuTheme.backdrop
          : context.playerMenuTheme.shadow.withValues(alpha: centered ? .5 : 0),
      child: Actions(
        key: const ValueKey<String>('scene-interaction-actions'),
        actions: <Type, Action<Intent>>{
          RuntimePlayerLogicalIntent:
              CallbackAction<RuntimePlayerLogicalIntent>(
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
                  alignment: centered || fullScreen
                      ? Alignment.center
                      : Alignment.bottomCenter,
                  child: Padding(
                    padding: fullScreen
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(PlayerSpacing.md),
                    child: SizedBox(
                      key: const ValueKey<String>('scene-interaction-panel'),
                      width: panelWidth,
                      height: math.max(
                        0,
                        math.min(
                          fullScreen
                              ? constraints.maxHeight
                              : math.min(620, naturalHeight ?? 620),
                          constraints.maxHeight -
                              (fullScreen ? 0 : PlayerSpacing.md * 2),
                        ),
                      ),
                      child: PlayerSurfacePaletteScope(
                        role: ProjectPresentationSurfaceRole.dialogue,
                        child: _SceneInteractionPanel(
                          fullScreen: fullScreen,
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
                                  _measure(
                                    headerId,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            prompt,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: promptStyle,
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
                                              width: cancelWidth,
                                              child: IconButton(
                                                key: const ValueKey(
                                                  'scene-interaction-cancel',
                                                ),
                                                tooltip: strings.cancel,
                                                icon: Icon(
                                                  fullScreen
                                                      ? Icons.arrow_back
                                                      : Icons.close,
                                                ),
                                                style: IconButton.styleFrom(
                                                  minimumSize: const Size(
                                                    48,
                                                    48,
                                                  ),
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                4,
                                                              ),
                                                            ),
                                                      ),
                                                  foregroundColor: context
                                                      .playerMenuTheme
                                                      .text,
                                                  backgroundColor: context
                                                      .playerMenuTheme
                                                      .recessed,
                                                ),
                                                onPressed: _terminal
                                                    ? null
                                                    : _cancel,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
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
                                      child: _measure(
                                        errorId,
                                        Semantics(
                                          key: const ValueKey(
                                            'scene-interaction-error',
                                          ),
                                          liveRegion: true,
                                          child: Text(
                                            message,
                                            style: TextStyle(
                                              color:
                                                  context.playerColors.danger,
                                            ),
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
          (_contentWidth - (_choiceColumns - 1) * 8) / _choiceColumns - 48,
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
      onContentHeightChanged: (height) => _rememberHeight('options', height),
      revealChildKey: _choiceRowKey(options),
      onPageReady: () => _focusOptions(request, options),
      children: [
        for (var index = 0; index < options.length; index += _choiceColumns)
          IntrinsicHeight(
            key: ValueKey('scene-choice-row-${options[index].id}'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var column = 0; column < _choiceColumns; column++) ...[
                  if (column > 0) const SizedBox(width: 8),
                  Expanded(
                    child: index + column < options.length
                        ? _choiceButton(
                            request,
                            options[index + column],
                            index + column,
                            strings,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    ),
    SceneIntegerInteractionRequest() => _integerInput(
      context,
      request,
      strings,
    ),
    SceneTextInteractionRequest() => _textInput(context, request, strings),
    SceneConfirmationInteractionRequest() => Align(
      alignment: Alignment.topCenter,
      child: _measure(
        'confirmation',
        Row(
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
      ),
    ),
    SceneSelectionInteractionRequest(:final options) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: PlayerPagedList(
            onContentHeightChanged: (height) =>
                _rememberHeight('options', height),
            revealChildKey: _choiceRowKey(options),
            onPageReady: () => _focusOptions(request, options),
            children: [
              for (
                var index = 0;
                index < options.length;
                index += _choiceColumns
              )
                IntrinsicHeight(
                  key: ValueKey('scene-choice-row-${options[index].id}'),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var column = 0;
                        column < _choiceColumns;
                        column++
                      ) ...[
                        if (column > 0) const SizedBox(width: 8),
                        Expanded(
                          child: index + column < options.length
                              ? _selectionButton(
                                  request,
                                  options[index + column],
                                  index + column,
                                  strings,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PlayerSpacing.sm),
        _measure(
          'selection-footer',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                onPressed: !widget.interactionEnabled || _terminal
                    ? null
                    : () => _submitSelection(request),
              ),
            ],
          ),
        ),
      ],
    ),
    SceneInteractionRequest() => const SizedBox.shrink(),
  };

  Key? _choiceRowKey(List<SceneInteractionOption> options) {
    final first = options.indexWhere(
      (option) => option.enabled && option.id == _returnOptionId,
    );
    final index = first < 0
        ? options.indexWhere((option) => option.enabled)
        : first;
    return index < 0
        ? null
        : ValueKey(
            'scene-choice-row-${options[index ~/ _choiceColumns * _choiceColumns].id}',
          );
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
  ) {
    final node = _optionFocusNodes.putIfAbsent(
      option.id,
      () => FocusNode(
        debugLabel: 'Player action: ${_resolvePrompt(option.label)}',
      ),
    );
    return PlayerMenuSelectableRow(
      key: ValueKey<String>('scene-interaction-option-${option.id}'),
      id: 'scene-choice-${option.id}',
      focusNode: node,
      label: _resolvePrompt(option.label),
      labelMaxLines: 2,
      selected: node.hasFocus,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onFocusChanged: (_) {
        if (mounted) setState(() {});
      },
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
  }

  Widget _integerInput(
    BuildContext context,
    SceneIntegerInteractionRequest request,
    PlayerSceneInteractionStrings strings,
  ) => _SceneInteractionInputForm(
    fieldKey: _inputFieldKey,
    fullScreen: true,
    controllerKeyboard: _usesControllerKeyboard(context),
    controller: _textController,
    numeric: true,
    signed: request.minimum < 0,
    maximum: request.digits + (request.minimum < 0 ? 1 : 0),
    keyboardEnabled: widget.interactionEnabled && !_terminal,
    onKeyboardChanged: () => setState(() => _validationIssue = null),
    measureEpoch: (
      request.requestId,
      request.revision,
      _naturalLayoutSignature,
    ),
    onHeight: (height) => _rememberHeight('form', height),
    field: TextField(
      key: const ValueKey<String>('scene-interaction-integer-field'),
      controller: _textController,
      focusNode: _textFocusNode,
      autofocus: !_usesControllerKeyboard(context),
      readOnly: _usesControllerKeyboard(context),
      canRequestFocus: !_usesControllerKeyboard(context),
      style: context.playerMenuTheme.body,
      cursorColor: context.playerMenuTheme.accent,
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
      decoration: _inputDecoration(
        context,
        strings,
      ).copyWith(helperText: '${request.minimum} – ${request.maximum}'),
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

  bool _usesControllerKeyboard(BuildContext context) =>
      PlayerInputScope.of(context) == PlayerInputSource.controller;

  InputDecoration _inputDecoration(
    BuildContext context,
    PlayerSceneInteractionStrings strings,
  ) {
    final theme = context.playerMenuTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: theme.border),
    );
    return InputDecoration(
      labelText: strings.textFieldLabel,
      counterText: '',
      filled: true,
      fillColor: theme.panel,
      labelStyle: theme.body.copyWith(color: theme.secondary),
      floatingLabelStyle: theme.meta.copyWith(color: theme.secondary),
      helperStyle: theme.meta.copyWith(color: theme.secondary),
      enabledBorder: border,
      border: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: theme.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

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
    BuildContext context,
    SceneTextInteractionRequest request,
    PlayerSceneInteractionStrings strings,
  ) {
    final maximum = request.constraints.maxGraphemes;
    final length = _textController.text.characters.length;
    return _SceneInteractionInputForm(
      fieldKey: _inputFieldKey,
      fullScreen: true,
      controllerKeyboard: _usesControllerKeyboard(context),
      controller: _textController,
      maximum: maximum,
      keyboardEnabled: widget.interactionEnabled && !_terminal,
      onKeyboardChanged: () => setState(() => _validationIssue = null),
      measureEpoch: (
        request.requestId,
        request.revision,
        _naturalLayoutSignature,
      ),
      onHeight: (height) => _rememberHeight('form', height),
      field: TextField(
        key: const ValueKey<String>('scene-interaction-text-field'),
        controller: _textController,
        focusNode: _textFocusNode,
        autofocus: !_usesControllerKeyboard(context),
        readOnly: _usesControllerKeyboard(context),
        canRequestFocus: !_usesControllerKeyboard(context),
        style: context.playerMenuTheme.body,
        cursorColor: context.playerMenuTheme.accent,
        enabled: widget.interactionEnabled && !_terminal,
        textInputAction: TextInputAction.done,
        inputFormatters: <TextInputFormatter>[
          if (maximum != null) _CommittedGraphemeLimitFormatter(maximum),
        ],
        decoration: _inputDecoration(context, strings),
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

class _SceneInteractionPanel extends StatelessWidget {
  const _SceneInteractionPanel({required this.child, required this.fullScreen});
  final Widget child;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    if (context.playerWindowTheme != null) {
      return PlayerPanel(
        role: PlayerPanelRole.dialogue,
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    return Material(
      color: fullScreen ? theme.backdrop : theme.panel,
      borderRadius: BorderRadius.circular(fullScreen ? 0 : 4),
      child: DefaultTextStyle(
        style: theme.body,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _SceneInteractionInputForm extends StatelessWidget {
  const _SceneInteractionInputForm({
    required this.fieldKey,
    required this.measureEpoch,
    required this.onHeight,
    required this.field,
    required this.submit,
    this.counter,
    this.fullScreen = false,
    this.controllerKeyboard = false,
    this.controller,
    this.maximum,
    this.numeric = false,
    this.signed = false,
    this.onKeyboardChanged,
    this.keyboardEnabled = true,
  });
  final bool fullScreen;
  final bool controllerKeyboard;
  final TextEditingController? controller;
  final int? maximum;
  final bool numeric;
  final bool signed;
  final VoidCallback? onKeyboardChanged;
  final bool keyboardEnabled;
  final Widget field;
  final GlobalKey fieldKey;
  final Widget submit;
  final Widget? counter;
  final Object measureEpoch;
  final ValueChanged<double> onHeight;

  Widget _natural(Widget child) => Align(
    alignment: Alignment.topCenter,
    child: _SceneContentMeasure(
      epoch: measureEpoch,
      onHeight: onHeight,
      child: child,
    ),
  );

  Widget _field() => KeyedSubtree(key: fieldKey, child: field);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (fullScreen && constraints.maxHeight >= 160) {
        final compactField =
            controllerKeyboard &&
            constraints.maxWidth >= 400 &&
            constraints.maxHeight < 400;
        final field = compactField
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _field()),
                  if (counter case final content?) ...[
                    const SizedBox(width: 8),
                    SizedBox(width: 100, child: content),
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(),
                  if (counter case final content?)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: content,
                    ),
                ],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controllerKeyboard) ...[
              field,
              const SizedBox(height: 12),
              Expanded(
                child: PlayerSceneKeyboard(
                  controller: controller!,
                  submit: submit,
                  maximum: maximum,
                  numeric: numeric,
                  signed: signed,
                  onChanged: onKeyboardChanged!,
                  enabled: keyboardEnabled,
                ),
              ),
            ] else ...[
              Expanded(child: Center(child: field)),
              const SizedBox(height: 12),
              submit,
            ],
          ],
        );
      }
      if (constraints.hasBoundedHeight &&
          constraints.maxHeight < 160 &&
          constraints.maxWidth >= 400) {
        return _natural(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _field()),
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
          ),
        );
      }
      return _natural(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(),
            if (counter case final content?)
              Padding(
                padding: const EdgeInsets.only(top: PlayerSpacing.xs),
                child: content,
              ),
            const SizedBox(height: PlayerSpacing.sm),
            submit,
          ],
        ),
      );
    },
  );
}

class _SceneContentMeasure extends SingleChildRenderObjectWidget {
  const _SceneContentMeasure({
    required this.epoch,
    required this.onHeight,
    required super.child,
  });

  final Object epoch;
  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _SceneContentMeasureBox(epoch, onHeight);

  @override
  void updateRenderObject(BuildContext context, _SceneContentMeasureBox box) {
    box.onHeight = onHeight;
    if (box.epoch != epoch) {
      box.epoch = epoch;
      box.lastHeight = null;
      box.markNeedsLayout();
    }
  }
}

class _SceneContentMeasureBox extends RenderProxyBox {
  _SceneContentMeasureBox(this.epoch, this.onHeight);

  Object epoch;
  ValueChanged<double> onHeight;
  double? lastHeight;

  @override
  void performLayout() {
    super.performLayout();
    if (lastHeight == size.height) return;
    lastHeight = size.height;
    final measured = size.height;
    final measuredEpoch = epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached && measuredEpoch == epoch) onHeight(measured);
    });
  }
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
