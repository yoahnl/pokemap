import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'script_runtime_state.dart';

/// Exécuteur de commandes de script.
///
/// Contient la logique d'exécution de chaque type de commande.
/// Les effets de bord sont délégués au contexte.
class ScriptCommandExecutor {
  ScriptCommandExecutor({
    required ScriptExecutionContext context,
  }) : _context = context;

  final ScriptExecutionContext _context;
  final GameStateMutations _mutations = const GameStateMutations();

  /// Exécute une commande.
  ScriptCommandResult execute(
    ScriptCommand command,
    GameState state,
  ) {
    switch (command.type) {
      case ScriptCommandType.goto:
        return _executeGoto(command.params);
      case ScriptCommandType.end:
        return _executeEnd();
      case ScriptCommandType.setFlag:
        return _executeSetFlag(command.params, state);
      case ScriptCommandType.clearFlag:
        return _executeClearFlag(command.params, state);
      case ScriptCommandType.setVariable:
        return _executeSetVariable(command.params, state);
      case ScriptCommandType.incrementVariable:
        return _executeIncrementVariable(command.params, state);
      case ScriptCommandType.openDialogue:
        return _executeOpenDialogue(command.params, state);
      case ScriptCommandType.waitForDialogue:
        return _executeWaitForDialogue();
      case ScriptCommandType.warpPlayer:
        return _executeWarpPlayer(command.params, state);
      case ScriptCommandType.giveItem:
        return _executeGiveItem(command.params, state);
      case ScriptCommandType.unlockFieldAbility:
        return _executeUnlockFieldAbility(command.params, state);
      case ScriptCommandType.markEventConsumed:
        return _executeMarkEventConsumed(command.params, state);
    }
  }

  ScriptCommandResult _executeGoto(Map<String, String> params) {
    final nodeId = params['nodeId'];
    if (nodeId == null || nodeId.isEmpty) {
      return ScriptCommandResult.error('Missing nodeId parameter');
    }
    return ScriptCommandResult.jumpToNode(nodeId);
  }

  ScriptCommandResult _executeEnd() {
    return ScriptCommandResult.terminated();
  }

  ScriptCommandResult _executeSetFlag(
    Map<String, String> params,
    GameState state,
  ) {
    final flagName = params['flagName'];
    if (flagName == null || flagName.isEmpty) {
      return ScriptCommandResult.error('Missing flagName parameter');
    }

    final newState = _mutations.setFlag(state, flagName);
    _context.onGameStateUpdated(newState);
    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeClearFlag(
    Map<String, String> params,
    GameState state,
  ) {
    final flagName = params['flagName'];
    if (flagName == null || flagName.isEmpty) {
      return ScriptCommandResult.error('Missing flagName parameter');
    }

    final newState = _mutations.clearFlag(state, flagName);
    _context.onGameStateUpdated(newState);
    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeSetVariable(
    Map<String, String> params,
    GameState state,
  ) {
    final variableName = params['variableName'];
    final value = params['value'];
    final type = params['type'] ?? 'string';

    if (variableName == null || variableName.isEmpty) {
      return ScriptCommandResult.error('Missing variableName parameter');
    }
    if (value == null) {
      return ScriptCommandResult.error('Missing value parameter');
    }

    ScriptVariableValue typedValue;
    switch (type) {
      case 'bool':
        typedValue = ScriptVariableValue.bool(value.toLowerCase() == 'true');
        break;
      case 'int':
        typedValue = ScriptVariableValue.int(int.parse(value));
        break;
      default:
        typedValue = ScriptVariableValue.string(value);
    }

    final newState = _mutations.setVariable(state, variableName, typedValue);
    _context.onGameStateUpdated(newState);
    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeIncrementVariable(
    Map<String, String> params,
    GameState state,
  ) {
    final variableName = params['variableName'];
    final deltaStr = params['delta'] ?? '1';

    if (variableName == null || variableName.isEmpty) {
      return ScriptCommandResult.error('Missing variableName parameter');
    }

    final delta = int.tryParse(deltaStr) ?? 1;
    final newState = _mutations.incrementVariable(state, variableName, delta);
    _context.onGameStateUpdated(newState);
    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeOpenDialogue(
    Map<String, String> params,
    GameState state,
  ) {
    final filePath = params['filePath'];
    final startNode = params['startNode'];

    if (filePath == null || filePath.isEmpty) {
      return ScriptCommandResult.error('Missing filePath parameter');
    }

    final dialogueRef = YarnDialogueRef(
      filePath: filePath,
      startNode: startNode?.isNotEmpty ?? false ? startNode : null,
    );

    // Notifier le contexte qu'un dialogue doit être ouvert
    _context.onDialogueOpened?.call(dialogueRef);

    // Suspendre le script en attendant la fin du dialogue
    return ScriptCommandResult.suspended(
      reason: ScriptSuspendReason.waitingForDialogue,
      dialogue: dialogueRef,
    );
  }

  ScriptCommandResult _executeWaitForDialogue() {
    // Cette commande est un no-op car la suspension est gérée par openDialogue
    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeWarpPlayer(
    Map<String, String> params,
    GameState state,
  ) {
    final mapId = params['mapId'];
    final xStr = params['x'] ?? '0';
    final yStr = params['y'] ?? '0';
    final facing = params['facing'];

    if (mapId == null || mapId.isEmpty) {
      return ScriptCommandResult.error('Missing mapId parameter');
    }

    final x = int.tryParse(xStr) ?? 0;
    final y = int.tryParse(yStr) ?? 0;

    EntityFacing? entityFacing;
    if (facing != null && facing.isNotEmpty) {
      entityFacing = EntityFacing.values.firstWhere(
        (e) => e.name == facing,
        orElse: () => EntityFacing.south,
      );
    }

    // Appliquer la mutation
    final newState = _mutations.warpPlayer(state, mapId, x, y, facing: entityFacing);
    _context.onGameStateUpdated(newState);

    // Notifier le runtime pour le warp effectif
    _context.onWarpRequested?.call(mapId, x, y);

    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeGiveItem(
    Map<String, String> params,
    GameState state,
  ) {
    final itemId = params['itemId'];
    final quantityStr = params['quantity'] ?? '1';

    if (itemId == null || itemId.isEmpty) {
      return ScriptCommandResult.error('Missing itemId parameter');
    }

    final quantity = int.tryParse(quantityStr) ?? 1;
    final newState = _mutations.giveItem(state, itemId, quantity);
    _context.onGameStateUpdated(newState);
    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeUnlockFieldAbility(
    Map<String, String> params,
    GameState state,
  ) {
    final abilityName = params['ability'];

    if (abilityName == null || abilityName.isEmpty) {
      return ScriptCommandResult.error('Missing ability parameter');
    }

    final ability = FieldAbility.values.firstWhere(
      (a) => a.name == abilityName,
      orElse: () => throw FormatException('Unknown field ability: $abilityName'),
    );

    final newState = _mutations.unlockFieldAbility(state, ability);
    _context.onGameStateUpdated(newState);
    return ScriptCommandResult.completed();
  }

  ScriptCommandResult _executeMarkEventConsumed(
    Map<String, String> params,
    GameState state,
  ) {
    final eventId = params['eventId'];

    if (eventId == null || eventId.isEmpty) {
      return ScriptCommandResult.error('Missing eventId parameter');
    }

    final newState = _mutations.markEventConsumed(state, eventId);
    _context.onGameStateUpdated(newState);
    return ScriptCommandResult.completed();
  }
}
