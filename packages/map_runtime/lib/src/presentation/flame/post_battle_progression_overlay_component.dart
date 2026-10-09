import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_post_battle_decision_coordinator.dart';
import '../flutter/post_battle_presentation_snapshot.dart';

typedef PostBattleMoveLearningDecisionHandler
    = RuntimePostBattleCoordinatorResult Function(
  BattleMoveLearningDecision decision,
);
typedef PostBattleEvolutionDecisionHandler = RuntimePostBattleCoordinatorResult
    Function(
  BattleEvolutionDecision decision,
);

final class PostBattleProgressionOverlayComponent extends PositionComponent {
  PostBattleProgressionOverlayComponent({
    required RuntimePostBattleCoordinatorResult initialResult,
    required Vector2 viewportSize,
    required this.onMoveLearningDecision,
    required this.onEvolutionDecision,
    required this.onCompleted,
    this.onPresentationSnapshotChanged,
  })  : _transaction = initialResult.transaction,
        _failure = initialResult.failure,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 99,
        ) {
    _publishPresentationSnapshot();
  }

  final PostBattleMoveLearningDecisionHandler onMoveLearningDecision;
  final PostBattleEvolutionDecisionHandler onEvolutionDecision;
  final VoidCallback onCompleted;
  final ValueChanged<PostBattlePresentationSnapshot?>?
      onPresentationSnapshotChanged;

  RuntimePostBattleTransaction? _transaction;
  RuntimePostBattleCoordinatorFailure? _failure;
  final Completer<void> _completion = Completer<void>();
  int _messageIndex = 0;
  int _selectedDecisionIndex = 0;
  bool _isCompleted = false;
  int _presentationRevision = 0;
  PostBattlePresentationSnapshot? _currentPresentationSnapshot;

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
  PostBattlePresentationSnapshot? get currentPresentationSnapshot =>
      _currentPresentationSnapshot;

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
    _publishPresentationSnapshot();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
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
    _syncText();
    try {
      onCompleted();
      if (!_completion.isCompleted) _completion.complete();
    } catch (error, stackTrace) {
      if (!_completion.isCompleted) {
        _completion.completeError(error, stackTrace);
      }
      rethrow;
    }
  }

  void _syncText() => _publishPresentationSnapshot();

  void _publishPresentationSnapshot() {
    final labels = decisionLabels;
    final snapshot = PostBattlePresentationSnapshot(
      revision: ++_presentationRevision,
      messageIndex: _messageIndex,
      messageCount: _messages.length,
      messageKind: currentMessageKind,
      message: _isCompleted ? 'Terminé.' : currentMessageText,
      choices: List<PostBattlePresentationChoice>.unmodifiable(
        <PostBattlePresentationChoice>[
          for (var index = 0; index < labels.length; index++)
            PostBattlePresentationChoice(
              index: index,
              label: labels[index],
              selected: index == _selectedDecisionIndex,
            ),
        ],
      ),
      completed: _isCompleted,
      hasFailure: _failure != null,
    );
    _currentPresentationSnapshot = snapshot;
    onPresentationSnapshotChanged?.call(snapshot);
  }
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
