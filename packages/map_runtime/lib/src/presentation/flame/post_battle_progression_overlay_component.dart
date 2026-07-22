import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_post_battle_decision_coordinator.dart';

typedef PostBattleMoveLearningDecisionHandler
    = RuntimePostBattleCoordinatorResult Function(
  BattleMoveLearningDecision decision,
);
typedef PostBattleEvolutionDecisionHandler = RuntimePostBattleCoordinatorResult
    Function(
  BattleEvolutionDecision decision,
);

/// Real Flame presentation for the ordered FG-048 post-battle flow.
///
/// It owns no progression rules: exact typed decisions are returned to the
/// coordinator callbacks and the resulting immutable transaction is rendered.
final class PostBattleProgressionOverlayComponent extends PositionComponent
    with TapCallbacks {
  PostBattleProgressionOverlayComponent({
    required RuntimePostBattleCoordinatorResult initialResult,
    required Vector2 viewportSize,
    required this.onMoveLearningDecision,
    required this.onEvolutionDecision,
    required this.onCompleted,
  })  : _transaction = initialResult.transaction,
        _failure = initialResult.failure,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 99,
        );

  final PostBattleMoveLearningDecisionHandler onMoveLearningDecision;
  final PostBattleEvolutionDecisionHandler onEvolutionDecision;
  final VoidCallback onCompleted;

  RuntimePostBattleTransaction? _transaction;
  RuntimePostBattleCoordinatorFailure? _failure;
  final Completer<void> _completion = Completer<void>();
  int _messageIndex = 0;
  int _selectedDecisionIndex = 0;
  bool _isCompleted = false;

  RectangleComponent? _scrim;
  RectangleComponent? _panel;
  TextComponent? _title;
  TextBoxComponent<TextPaint>? _message;
  final List<TextComponent> _choiceTexts = <TextComponent>[];

  String get messageSemanticKey => 'post-battle-message';

  List<String> get decisionSemanticKeys {
    final pendingMove = _visiblePendingMove;
    if (pendingMove != null) {
      if (pendingMove.phase == BattleMoveLearningPhase.awaitingDecision) {
        return const <String>[
          'post-battle-choice-learn',
          'post-battle-choice-decline',
        ];
      }
      return <String>[
        for (var index = 0;
            index < (_transaction?.pendingPartyMoveIds.length ?? 0);
            index++)
          'post-battle-choice-replace-$index',
        'post-battle-choice-decline',
      ];
    }
    if (_visiblePendingEvolution != null) {
      return const <String>[
        'post-battle-choice-evolve',
        'post-battle-choice-refuse',
      ];
    }
    return const <String>[];
  }

  List<String> get decisionLabels {
    final pendingMove = _visiblePendingMove;
    if (pendingMove != null) {
      if (pendingMove.phase == BattleMoveLearningPhase.awaitingDecision) {
        return const <String>['Apprendre', 'Ne pas apprendre'];
      }
      return <String>[
        for (final moveId in _transaction!.pendingPartyMoveIds)
          _displayId(moveId),
        'Ne pas apprendre',
      ];
    }
    if (_visiblePendingEvolution != null) {
      return const <String>['Évoluer', 'Refuser'];
    }
    return const <String>[];
  }

  RuntimePostBattleTransaction? get currentTransaction => _transaction;
  RuntimePostBattleCoordinatorFailure? get currentFailure => _failure;
  Future<void> get completionFuture => _completion.future;
  bool get isCompleted => _isCompleted;
  int get selectedDecisionIndex => _selectedDecisionIndex;

  @visibleForTesting
  Rect get debugPanelRect => _layoutMetrics.panelRect;

  @visibleForTesting
  List<Rect> get debugDecisionHitBoxes =>
      List<Rect>.unmodifiable(_layoutMetrics.decisionHitBoxes);

  @visibleForTesting
  Rect get debugMessageRect => _layoutMetrics.messageRect;

  @visibleForTesting
  TextBoxComponent<TextPaint>? get debugMessageComponent => _message;

  @visibleForTesting
  bool debugTapAt(Offset localPosition) => _handleTapAt(localPosition);

  RuntimePostBattleMessage get _currentMessage {
    final messages = _messages;
    return messages[_messageIndex.clamp(0, messages.length - 1)];
  }

  String get currentMessageText => _currentMessage.text;
  RuntimePostBattleMessageKind get currentMessageKind => _currentMessage.kind;

  List<RuntimePostBattleMessage> get _messages {
    final failure = _failure;
    if (failure != null) {
      return <RuntimePostBattleMessage>[failure.presentationMessage];
    }
    final messages = _transaction?.messages;
    if (messages == null || messages.isEmpty) {
      return const <RuntimePostBattleMessage>[
        RuntimePostBattleMessage(
          kind: RuntimePostBattleMessageKind.error,
          text: 'Aucun résultat post-combat disponible.',
        ),
      ];
    }
    return messages;
  }

  PendingBattleMoveLearning? get _visiblePendingMove {
    if (_isCompleted ||
        _failure != null ||
        _messageIndex != _messages.length - 1) {
      return null;
    }
    return _transaction?.pendingMoveLearning;
  }

  PendingBattleEvolution? get _visiblePendingEvolution {
    if (_isCompleted ||
        _failure != null ||
        _messageIndex != _messages.length - 1) {
      return null;
    }
    return _transaction?.pendingEvolution;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final layout = _layoutMetrics;
    _scrim = RectangleComponent(
      size: size.clone(),
      paint: Paint()..color = const Color(0xCC06101D),
      priority: 0,
    );
    _panel = RectangleComponent(
      paint: Paint()..color = const Color(0xFF102033),
      priority: 1,
    );
    _title = TextComponent(
      text: 'APRÈS-COMBAT',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF7FB6FF),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 2,
    );
    _message = TextBoxComponent<TextPaint>(
      text: currentMessageText,
      textRenderer: _messageTextRenderer(layout.messageFontSize),
      boxConfig: TextBoxConfig(
        maxWidth: layout.messageRect.width,
        margins: EdgeInsets.zero,
      ),
      size: Vector2(layout.messageRect.width, layout.messageRect.height),
      priority: 2,
    );
    await addAll(<Component>[_scrim!, _panel!, _title!, _message!]);
    _syncLayout();
    _syncText();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _syncLayout();
  }

  bool moveSelectionUp() => _moveSelection(-1);
  bool moveSelectionDown() => _moveSelection(1);
  bool moveSelectionLeft() => moveSelectionUp();
  bool moveSelectionRight() => moveSelectionDown();

  bool selectDecision(int index) {
    final labels = decisionLabels;
    if (index < 0 || index >= labels.length) return false;
    _selectedDecisionIndex = index;
    _syncText();
    return true;
  }

  bool _moveSelection(int delta) {
    final labels = decisionLabels;
    if (labels.isEmpty) return false;
    _selectedDecisionIndex =
        (_selectedDecisionIndex + delta).clamp(0, labels.length - 1);
    _syncText();
    return true;
  }

  bool validateSelectedChoice() {
    if (_isCompleted) return false;
    final labels = decisionLabels;
    if (labels.isNotEmpty) {
      return _submitDecision();
    }
    if (_messageIndex < _messages.length - 1) {
      _messageIndex += 1;
      _selectedDecisionIndex = 0;
      _syncText();
      return true;
    }
    if (_failure != null || (_transaction?.isReadyToCommit ?? false)) {
      _completeOnce();
      return true;
    }
    return false;
  }

  bool _submitDecision() {
    final transaction = _transaction;
    if (transaction == null) return false;
    final previousMessageCount = _messages.length;
    try {
      final pendingMove = _visiblePendingMove;
      late final RuntimePostBattleCoordinatorResult result;
      if (pendingMove != null) {
        if (pendingMove.phase == BattleMoveLearningPhase.awaitingDecision) {
          result = _selectedDecisionIndex == 0
              ? onMoveLearningDecision(
                  BattleMoveLearningDecision.learn(
                    opportunityId: pendingMove.opportunityId,
                    partySlot: pendingMove.partySlot,
                    moveId: pendingMove.candidate.moveId,
                  ),
                )
              : onMoveLearningDecision(
                  BattleMoveLearningDecision.decline(
                    opportunityId: pendingMove.opportunityId,
                    partySlot: pendingMove.partySlot,
                    moveId: pendingMove.candidate.moveId,
                  ),
                );
        } else {
          final moves = transaction.pendingPartyMoveIds;
          result = _selectedDecisionIndex < moves.length
              ? onMoveLearningDecision(
                  BattleMoveLearningDecision.replace(
                    opportunityId: pendingMove.opportunityId,
                    partySlot: pendingMove.partySlot,
                    moveId: pendingMove.candidate.moveId,
                    replaceMoveIndex: _selectedDecisionIndex,
                    expectedReplacedMoveId: moves[_selectedDecisionIndex],
                  ),
                )
              : onMoveLearningDecision(
                  BattleMoveLearningDecision.decline(
                    opportunityId: pendingMove.opportunityId,
                    partySlot: pendingMove.partySlot,
                    moveId: pendingMove.candidate.moveId,
                  ),
                );
        }
      } else if (_visiblePendingEvolution case final pendingEvolution?) {
        result = _selectedDecisionIndex == 0
            ? onEvolutionDecision(
                BattleEvolutionDecision.accept(
                  opportunityId: pendingEvolution.opportunityId,
                  occurrenceId: pendingEvolution.occurrenceId,
                  partySlot: pendingEvolution.partySlot,
                  sourceSpeciesId: pendingEvolution.sourceSpeciesId,
                  targetSpeciesId: pendingEvolution.targetSpeciesId,
                ),
              )
            : onEvolutionDecision(
                BattleEvolutionDecision.refuse(
                  opportunityId: pendingEvolution.opportunityId,
                  occurrenceId: pendingEvolution.occurrenceId,
                  partySlot: pendingEvolution.partySlot,
                  sourceSpeciesId: pendingEvolution.sourceSpeciesId,
                  targetSpeciesId: pendingEvolution.targetSpeciesId,
                ),
              );
      } else {
        return false;
      }
      _applyResult(result, previousMessageCount: previousMessageCount);
    } catch (error) {
      _applyResult(
        RuntimePostBattleCoordinatorResult.failure(
          failure: RuntimePostBattleCoordinatorFailure(
            code: RuntimePostBattleCoordinatorFailureCode.invalidDecision,
            message: 'La décision post-combat ne peut pas être appliquée.',
            originalState: transaction.originalState,
            cause: error,
          ),
          transaction: transaction,
        ),
        previousMessageCount: previousMessageCount,
      );
    }
    return true;
  }

  void _applyResult(
    RuntimePostBattleCoordinatorResult result, {
    required int previousMessageCount,
  }) {
    _transaction = result.transaction;
    _failure = result.failure;
    _messageIndex = result.failure != null
        ? 0
        : previousMessageCount.clamp(0, _messages.length - 1);
    _selectedDecisionIndex = 0;
    _syncText();
  }

  void _completeOnce() {
    if (_isCompleted) return;
    _isCompleted = true;
    try {
      onCompleted();
      if (!_completion.isCompleted) _completion.complete();
    } catch (error, stackTrace) {
      if (!_completion.isCompleted) {
        _completion.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      _syncText();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _handleTapAt(event.localPosition.toOffset());
  }

  bool _handleTapAt(Offset localPosition) {
    if (_isCompleted) return false;
    final layout = _layoutMetrics;
    final labels = decisionLabels;
    if (labels.isNotEmpty) {
      final index = layout.decisionHitBoxes.indexWhere(
        (hitBox) => hitBox.contains(localPosition),
      );
      if (index < 0 || !selectDecision(index)) return false;
      return validateSelectedChoice();
    }
    if (!layout.panelRect.contains(localPosition)) return false;
    return validateSelectedChoice();
  }

  void _syncLayout() {
    _scrim?.size = size.clone();
    final layout = _layoutMetrics;
    _panel
      ?..position = Vector2(layout.panelRect.left, layout.panelRect.top)
      ..size = Vector2(layout.panelRect.width, layout.panelRect.height);
    _title?.position = layout.titlePosition;
    final message = _message;
    if (message != null) {
      message
        ..position = Vector2(layout.messageRect.left, layout.messageRect.top)
        ..size = Vector2(layout.messageRect.width, layout.messageRect.height)
        ..textRenderer = _messageTextRenderer(layout.messageFontSize)
        ..boxConfig = TextBoxConfig(
          maxWidth: layout.messageRect.width,
          margins: EdgeInsets.zero,
        );
      unawaited(message.redraw());
    }
    _layoutChoices(layout);
  }

  void _syncText() {
    _message?.text = _isCompleted ? 'Terminé.' : currentMessageText;
    for (final component in _choiceTexts) {
      component.removeFromParent();
    }
    _choiceTexts.clear();
    final labels = decisionLabels;
    for (var index = 0; index < labels.length; index++) {
      final selected = index == _selectedDecisionIndex;
      final text = TextComponent(
        text: '${selected ? '▶ ' : '  '}${labels[index]}',
        textRenderer: TextPaint(
          style: TextStyle(
            color: selected ? const Color(0xFF7FB6FF) : Colors.white,
            fontSize: 19,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        priority: 2,
      );
      _choiceTexts.add(text);
      add(text);
    }
    _syncLayout();
  }

  _PostBattleOverlayLayout get _layoutMetrics =>
      _PostBattleOverlayLayout.calculate(
        viewportSize: size,
        decisionCount: decisionLabels.length,
      );

  void _layoutChoices(_PostBattleOverlayLayout layout) {
    for (var index = 0; index < _choiceTexts.length; index++) {
      final hitBox = layout.decisionHitBoxes[index];
      _choiceTexts[index].position = Vector2(
        hitBox.left,
        hitBox.top + math.max(0, (hitBox.height - 24) / 2),
      );
    }
  }
}

final class _PostBattleOverlayLayout {
  const _PostBattleOverlayLayout({
    required this.panelRect,
    required this.titlePosition,
    required this.messageRect,
    required this.messageFontSize,
    required this.decisionHitBoxes,
  });

  factory _PostBattleOverlayLayout.calculate({
    required Vector2 viewportSize,
    required int decisionCount,
  }) {
    final horizontalMargin =
        (viewportSize.x * 0.09).clamp(16.0, 72.0).toDouble();
    final verticalMargin = (viewportSize.y * 0.10).clamp(12.0, 60.0).toDouble();
    final panelRect = Rect.fromLTRB(
      horizontalMargin,
      verticalMargin,
      viewportSize.x - horizontalMargin,
      viewportSize.y - verticalMargin,
    );
    final titlePosition = Vector2(panelRect.left + 24, panelRect.top + 20);
    final messageTop = panelRect.top + 70;
    final messageFontSize = (viewportSize.y / 20).clamp(18.0, 24.0).toDouble();

    final firstChoiceY = decisionCount == 0
        ? panelRect.bottom - 24
        : math.max(
            messageTop + 70,
            panelRect.top + panelRect.height * 0.43,
          );
    final availableChoiceHeight = decisionCount == 0
        ? 0.0
        : math.max(0.0, panelRect.bottom - 20 - firstChoiceY);
    final rowHeight = decisionCount == 0
        ? 0.0
        : math.min(40.0, availableChoiceHeight / decisionCount);
    final choiceLeft = panelRect.left + 24;
    final choiceWidth = math.max(0.0, panelRect.width - 48);
    final messageBottom =
        decisionCount == 0 ? panelRect.bottom - 24 : firstChoiceY - 12;
    final messageRect = Rect.fromLTWH(
      choiceLeft,
      messageTop,
      choiceWidth,
      math.max(0.0, messageBottom - messageTop),
    );
    final decisionHitBoxes = <Rect>[
      for (var index = 0; index < decisionCount; index++)
        Rect.fromLTWH(
          choiceLeft,
          firstChoiceY + index * rowHeight,
          choiceWidth,
          rowHeight,
        ),
    ];
    return _PostBattleOverlayLayout(
      panelRect: panelRect,
      titlePosition: titlePosition,
      messageRect: messageRect,
      messageFontSize: messageFontSize,
      decisionHitBoxes: decisionHitBoxes,
    );
  }

  final Rect panelRect;
  final Vector2 titlePosition;
  final Rect messageRect;
  final double messageFontSize;
  final List<Rect> decisionHitBoxes;
}

TextPaint _messageTextRenderer(double fontSize) {
  return TextPaint(
    style: TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    ),
  );
}

String _displayId(String id) {
  final words = id
      .trim()
      .split(RegExp(r'[-_:]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'Pokémon';
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
