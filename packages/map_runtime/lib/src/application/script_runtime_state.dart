import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

part 'script_runtime_state.freezed.dart';

/// État d'exécution d'un script.
///
/// Contient :
/// - le script en cours
/// - le noeud actuel
/// - l'état de progression dans le noeud (index de commande)
/// - l'état de suspension (en attente de dialogue, etc.)
@freezed
class ScriptExecutionState with _$ScriptExecutionState {
  const factory ScriptExecutionState({
    /// Script en cours d'exécution.
    required ScriptAsset script,

    /// Noeud actuel.
    required String currentNodeId,

    /// Index de la commande en cours dans le noeud.
    @Default(0) int currentCommandIndex,

    /// true si le script est en attente (dialogue, etc.).
    @Default(false) bool isSuspended,

    /// Raison de la suspension.
    ScriptSuspendReason? suspendReason,

    /// Référence au dialogue en cours (si suspendu pour dialogue).
    YarnDialogueRef? pendingDialogue,
  }) = _ScriptExecutionState;
}

/// Raisons de suspension d'un script.
enum ScriptSuspendReason {
  /// En attente de la fin d'un dialogue.
  waitingForDialogue,

  /// En attente d'une confirmation utilisateur.
  waitingForConfirmation,

  /// En attente d'un événement externe.
  waitingForExternal,

  /// En attente de la fin d'un combat (trainer ou wild).
  waitingForBattle,
}

/// Résultat de l'exécution d'une commande.
@freezed
class ScriptCommandResult with _$ScriptCommandResult {
  const factory ScriptCommandResult.completed() =
      ScriptCommandResultCompleted;

  const factory ScriptCommandResult.suspended({
    required ScriptSuspendReason reason,
    YarnDialogueRef? dialogue,
  }) = ScriptCommandResultSuspended;

  const factory ScriptCommandResult.jumpToNode(String nodeId) =
      ScriptCommandResultJumpToNode;

  const factory ScriptCommandResult.terminated() =
      ScriptCommandResultTerminated;

  const factory ScriptCommandResult.error(String message) =
      ScriptCommandResultError;
}

/// Contexte d'exécution d'un script.
///
/// Contient les références nécessaires pour exécuter les commandes :
/// - état de partie (pour lecture/écriture)
/// - références aux dialogues
/// - callbacks pour les effets de bord (warp, etc.)
class ScriptExecutionContext {
  ScriptExecutionContext({
    required this.gameState,
    required this.onGameStateUpdated,
    this.dialogueLoader,
    this.onDialogueOpened,
    this.onWarpRequested,
  });

  /// État de partie actuel.
  GameState gameState;

  /// Callback appelé quand l'état de partie est modifié.
  final void Function(GameState) onGameStateUpdated;

  /// Chargeur de dialogue (optionnel).
  final Future<bool> Function(YarnDialogueRef)? dialogueLoader;

  /// Callback appelé quand un dialogue est ouvert.
  final void Function(YarnDialogueRef)? onDialogueOpened;

  /// Callback appelé pour un warp.
  final void Function(String mapId, int x, int y)? onWarpRequested;
}
