import 'package:map_core/map_core.dart';

import 'dialogue_authoring_service.dart';

final class ScriptAuthoringDiagnostic {
  const ScriptAuthoringDiagnostic({
    required this.code,
    required this.message,
    required this.path,
    this.severity = NarrativeAuthoringDiagnosticSeverity.error,
  });

  final String code;
  final String message;
  final String path;
  final NarrativeAuthoringDiagnosticSeverity severity;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'path': path,
        'severity': severity.name,
      };
}

final class ScriptEffectPreview {
  ScriptEffectPreview({
    required this.nodeId,
    required this.commandIndex,
    required this.type,
    required Map<String, String> parameters,
  }) : parameters = Map.unmodifiable(parameters);

  final String nodeId;
  final int commandIndex;
  final ScriptCommandType type;
  final Map<String, String> parameters;

  Map<String, Object?> toJson() => {
        'nodeId': nodeId,
        'commandIndex': commandIndex,
        'type': type.name,
        'parameters': parameters,
      };
}

final class ScriptSimulationTrace {
  ScriptSimulationTrace({
    required Iterable<ScriptAuthoringDiagnostic> diagnostics,
    required Iterable<String> visitedNodes,
    required Iterable<ScriptEffectPreview> effects,
    required this.terminated,
    required this.truncated,
  })  : diagnostics = List.unmodifiable(diagnostics),
        visitedNodes = List.unmodifiable(visitedNodes),
        effects = List.unmodifiable(effects);

  final List<ScriptAuthoringDiagnostic> diagnostics;
  final List<String> visitedNodes;
  final List<ScriptEffectPreview> effects;
  final bool terminated;
  final bool truncated;

  bool get canRun => diagnostics.every(
        (item) => item.severity != NarrativeAuthoringDiagnosticSeverity.error,
      );

  Map<String, Object?> toJson() => {
        'canRun': canRun,
        'visitedNodes': visitedNodes,
        'effects': [for (final effect in effects) effect.toJson()],
        'terminated': terminated,
        'truncated': truncated,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
      };
}

/// Pure dry simulation: effects are described, never sent to runtime ports.
final class ScriptAuthoringSimulator {
  const ScriptAuthoringSimulator();

  List<ScriptAuthoringDiagnostic> validate(ScriptAsset script) {
    final diagnostics = <ScriptAuthoringDiagnostic>[];
    final nodes = <String, ScriptNode>{};
    for (var nodeIndex = 0; nodeIndex < script.nodes.length; nodeIndex++) {
      final node = script.nodes[nodeIndex];
      if (node.id.trim().isEmpty || nodes.containsKey(node.id)) {
        diagnostics.add(
          ScriptAuthoringDiagnostic(
            code: node.id.trim().isEmpty
                ? 'script.node_id_required'
                : 'script.node_id_duplicate',
            message: 'Script node identities must be nonblank and unique.',
            path: '/nodes/$nodeIndex/id',
          ),
        );
      } else {
        nodes[node.id] = node;
      }
    }
    if (!nodes.containsKey(script.defaultStartNode)) {
      diagnostics.add(
        const ScriptAuthoringDiagnostic(
          code: 'script.start_node_missing',
          message: 'The default start node does not exist.',
          path: '/defaultStartNode',
        ),
      );
    }
    for (var nodeIndex = 0; nodeIndex < script.nodes.length; nodeIndex++) {
      final node = script.nodes[nodeIndex];
      if (node.nextNodeId != null && !nodes.containsKey(node.nextNodeId)) {
        diagnostics.add(
          ScriptAuthoringDiagnostic(
            code: 'script.next_node_missing',
            message: 'The next node does not exist.',
            path: '/nodes/$nodeIndex/nextNodeId',
          ),
        );
      }
      for (var commandIndex = 0;
          commandIndex < node.commands.length;
          commandIndex++) {
        final command = node.commands[commandIndex];
        final path = '/nodes/$nodeIndex/commands/$commandIndex';
        final required = _requiredParameters[command.type] ?? const <String>[];
        for (final key in required) {
          if (command.params[key]?.trim().isEmpty ?? true) {
            diagnostics.add(
              ScriptAuthoringDiagnostic(
                code: 'script.parameter_required',
                message: 'The "$key" parameter is required.',
                path: '$path/params/$key',
              ),
            );
          }
        }
        if (command.type == ScriptCommandType.goto) {
          final target = command.params['nodeId'];
          if (target != null &&
              target.isNotEmpty &&
              !nodes.containsKey(target)) {
            diagnostics.add(
              ScriptAuthoringDiagnostic(
                code: 'script.goto_target_missing',
                message: 'The goto target does not exist.',
                path: '$path/params/nodeId',
              ),
            );
          }
        }
        if (command.type == ScriptCommandType.giveItem) {
          final quantity = int.tryParse(command.params['quantity'] ?? '1');
          if (quantity == null || quantity <= 0) {
            diagnostics.add(
              ScriptAuthoringDiagnostic(
                code: 'script.quantity_invalid',
                message: 'Item quantity must be a positive integer.',
                path: '$path/params/quantity',
              ),
            );
          }
        }
      }
    }
    diagnostics.sort((left, right) {
      final path = left.path.compareTo(right.path);
      return path != 0 ? path : left.code.compareTo(right.code);
    });
    return List.unmodifiable(diagnostics);
  }

  ScriptSimulationTrace simulate(
    ScriptAsset script, {
    int maximumNodeVisits = 128,
  }) {
    if (maximumNodeVisits <= 0) {
      throw ArgumentError.value(
        maximumNodeVisits,
        'maximumNodeVisits',
        'must be positive',
      );
    }
    final diagnostics = validate(script);
    if (diagnostics.any((item) =>
        item.severity == NarrativeAuthoringDiagnosticSeverity.error)) {
      return ScriptSimulationTrace(
        diagnostics: diagnostics,
        visitedNodes: const [],
        effects: const [],
        terminated: false,
        truncated: false,
      );
    }
    final nodes = {for (final node in script.nodes) node.id: node};
    var current = nodes[script.defaultStartNode]!;
    final visited = <String>[];
    final effects = <ScriptEffectPreview>[];
    var terminated = false;
    var truncated = false;
    for (var visit = 0; visit < maximumNodeVisits; visit++) {
      visited.add(current.id);
      String? jump;
      for (var index = 0; index < current.commands.length; index++) {
        final command = current.commands[index];
        if (command.type == ScriptCommandType.goto) {
          jump = command.params['nodeId'];
          break;
        }
        if (command.type == ScriptCommandType.end) {
          terminated = true;
          break;
        }
        effects.add(
          ScriptEffectPreview(
            nodeId: current.id,
            commandIndex: index,
            type: command.type,
            parameters: command.params,
          ),
        );
      }
      if (terminated) break;
      final next = jump ?? current.nextNodeId;
      if (next == null) {
        terminated = true;
        break;
      }
      current = nodes[next]!;
      if (visit == maximumNodeVisits - 1) truncated = true;
    }
    return ScriptSimulationTrace(
      diagnostics: diagnostics,
      visitedNodes: visited,
      effects: effects,
      terminated: terminated,
      truncated: truncated,
    );
  }
}

const Map<ScriptCommandType, List<String>> _requiredParameters = {
  ScriptCommandType.goto: ['nodeId'],
  ScriptCommandType.setFlag: ['flagName'],
  ScriptCommandType.clearFlag: ['flagName'],
  ScriptCommandType.setVariable: ['variableName', 'value'],
  ScriptCommandType.incrementVariable: ['variableName'],
  ScriptCommandType.openDialogue: ['filePath'],
  ScriptCommandType.warpPlayer: ['mapId'],
  ScriptCommandType.giveItem: ['itemId'],
  ScriptCommandType.unlockFieldAbility: ['ability'],
  ScriptCommandType.markEventConsumed: ['eventId'],
};
