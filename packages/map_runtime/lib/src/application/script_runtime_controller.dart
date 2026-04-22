import 'package:map_core/map_core.dart';

import 'script_runtime_state.dart';
import 'script_command_executor.dart';

/// Orchestrateur d'exécution de scripts.
///
/// Gère :
/// - le démarrage d'un script
/// - l'avancement dans les noeuds
/// - l'exécution des commandes
/// - la suspension/reprise (dialogues, etc.)
/// - la terminaison
///
/// Ne contient pas la logique d'exécution des commandes
/// (déléguée à [ScriptCommandExecutor]).
class ScriptRuntimeController {
  ScriptRuntimeController({
    required ScriptAsset script,
    required ScriptExecutionContext context,
    String? startNodeId,
  })  : _script = script,
        _context = context,
        _executor = ScriptCommandExecutor(context: context) {
    final startNode = startNodeId ?? script.defaultStartNode;
    _state = ScriptExecutionState(
      script: script,
      currentNodeId: startNode,
      currentCommandIndex: 0,
    );
  }

  final ScriptAsset _script;
  final ScriptExecutionContext _context;
  final ScriptCommandExecutor _executor;
  late ScriptExecutionState _state;

  /// État actuel.
  ScriptExecutionState get state => _state;

  /// true si le script est terminé.
  bool get isTerminated => _state.currentNodeId.isEmpty;

  /// true si le script est en attente.
  bool get isSuspended => _state.isSuspended;

  /// Noeud actuel.
  String get currentNodeId => _state.currentNodeId;

  /// Avance d'une commande.
  ///
  /// Retourne le résultat de la commande exécutée.
  ScriptCommandResult step() {
    if (_state.isSuspended) {
      return ScriptCommandResult.suspended(
        reason: _state.suspendReason!,
        dialogue: _state.pendingDialogue,
      );
    }

    final node = _findNode(_state.currentNodeId);
    if (node == null) {
      return ScriptCommandResult.error(
          'Node not found: ${_state.currentNodeId}');
    }

    if (_state.currentCommandIndex >= node.commands.length) {
      // Fin du noeud, passer au suivant
      return _advanceToNextNode(node);
    }

    final command = node.commands[_state.currentCommandIndex];
    final result = _executor.execute(command, _context.gameState);

    // Mettre à jour l'état
    _state = _applyResult(result, node);

    return result;
  }

  ScriptCommandResult _advanceToNextNode(ScriptNode currentNode) {
    final nextNodeId = currentNode.nextNodeId;
    if (nextNodeId == null) {
      _state = const ScriptExecutionState(
        script: ScriptAsset(id: '', nodes: []),
        currentNodeId: '',
      );
      return const ScriptCommandResult.terminated();
    }

    final nextNode = _findNode(nextNodeId);
    if (nextNode == null) {
      return ScriptCommandResult.error('Next node not found: $nextNodeId');
    }

    _state = _state.copyWith(
      currentNodeId: nextNodeId,
      currentCommandIndex: 0,
    );

    return const ScriptCommandResult.completed();
  }

  ScriptExecutionState _applyResult(
    ScriptCommandResult result,
    ScriptNode node,
  ) {
    return result.map(
      completed: (_) {
        return _state.copyWith(
          currentCommandIndex: _state.currentCommandIndex + 1,
        );
      },
      suspended: (s) {
        return _state.copyWith(
          isSuspended: true,
          suspendReason: s.reason,
          pendingDialogue: s.dialogue,
        );
      },
      jumpToNode: (j) {
        return _state.copyWith(
          currentNodeId: j.nodeId,
          currentCommandIndex: 0,
          isSuspended: false,
          suspendReason: null,
        );
      },
      terminated: (_) {
        return const ScriptExecutionState(
          script: ScriptAsset(id: '', nodes: []),
          currentNodeId: '',
        );
      },
      error: (e) => _state,
    );
  }

  /// Reprend l'exécution après une suspension.
  void resume() {
    if (!_state.isSuspended) return;

    _state = _state.copyWith(
      currentCommandIndex: _state.currentCommandIndex + 1,
      isSuspended: false,
      suspendReason: null,
      pendingDialogue: null,
    );
  }

  ScriptNode? _findNode(String nodeId) {
    return _script.nodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => throw Exception('Node not found: $nodeId'),
    );
  }
}
