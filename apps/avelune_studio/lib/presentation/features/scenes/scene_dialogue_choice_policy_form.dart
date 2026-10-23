import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

class SceneDialogueChoicePolicyForm extends StatefulWidget {
  const SceneDialogueChoicePolicyForm({
    super.key,
    required this.scene,
    required this.nodeId,
    required this.payload,
    required this.document,
    required this.onApply,
  });

  final SceneAsset scene;
  final String nodeId;
  final SceneYarnDialoguePayload payload;
  final RuntimeDialogueDocument document;
  final ValueChanged<SceneDialogueChoicePolicy> onApply;

  @override
  State<SceneDialogueChoicePolicyForm> createState() =>
      _SceneDialogueChoicePolicyFormState();
}

class _SceneDialogueChoicePolicyFormState
    extends State<SceneDialogueChoicePolicyForm> {
  List<SceneDialogueChoiceScope> _scopes = const [];
  final _blocks = <(String, int), RuntimeDialogueChoiceBlock>{};
  Map<String, String> _branches = const {};
  int _scopeIndex = 0;
  String _defaultOutcome = '';
  SceneDialogueChoiceCancellationKind _cancellation =
      SceneDialogueChoiceCancellationKind.disabled;
  String? _target;

  @override
  void initState() {
    super.initState();
    _readDocument();
  }

  @override
  void didUpdateWidget(SceneDialogueChoicePolicyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene ||
        oldWidget.nodeId != widget.nodeId ||
        oldWidget.payload != widget.payload ||
        oldWidget.document != widget.document) {
      if (oldWidget.nodeId != widget.nodeId ||
          oldWidget.document != widget.document) {
        _scopeIndex = 0;
      }
      _readDocument();
    }
  }

  SceneDialogueChoiceScope get _scope => _scopes[_scopeIndex];

  RuntimeDialogueChoiceBlock get _block =>
      _blocks[(_scope.nodeName, _scope.choiceIndex)]!;

  void _readDocument() {
    _scopes = sceneDialogueChoiceScopes(widget.document);
    _blocks.clear();
    for (final node in widget.document.nodes) {
      var index = 0;
      void visit(List<RuntimeDialogueStep> steps) {
        for (final step in steps) {
          if (step is! RuntimeDialogueChoiceBlock) continue;
          _blocks[(node.title, index++)] = step;
          for (final choice in step.choices) {
            visit(choice.steps);
          }
        }
      }

      visit(node.steps);
    }
    final emitted = {
      for (final block in _blocks.values)
        for (final choice in block.choices) choice.outcomeId,
    };
    _branches = {};
    for (final outcome in widget.payload.expectedOutcomes) {
      if (emitted.contains(outcome)) continue;
      final edges = widget.scene.graph.edges.where(
        (edge) =>
            edge.fromNodeId == widget.nodeId &&
            edge.fromPortId == outcome &&
            edge.kind == SceneEdgeKind.dialogueOutcome,
      );
      if (edges.length != 1) continue;
      final target = widget.scene.graph.nodes
          .where((node) => node.id == edges.single.toNodeId)
          .firstOrNull;
      if (target == null) continue;
      final title = target.title?.trim();
      _branches[outcome] = title == null || title.isEmpty
          ? 'Branche ${_branches.length + 1}'
          : title;
    }
    if (_scopeIndex >= _scopes.length) _scopeIndex = 0;
    if (_scopes.isNotEmpty) _readPolicy();
  }

  void _readPolicy() {
    final current = widget.payload.choicePolicies
        .where(
          (policy) =>
              policy.nodeName == _scope.nodeName &&
              policy.choiceIndex == _scope.choiceIndex,
        )
        .firstOrNull;
    _defaultOutcome = current?.defaultOutcomeId ?? '';
    _cancellation =
        current?.cancellation.kind ??
        SceneDialogueChoiceCancellationKind.disabled;
    _target = current?.cancellation.outcomeId;
  }

  Map<String, String> get _choices => {
    for (final choice in _block.choices)
      if (choice.outcomeId != null &&
          widget.payload.expectedOutcomes.contains(choice.outcomeId) &&
          _block.choices
                  .where((other) => other.outcomeId == choice.outcomeId)
                  .length ==
              1)
        choice.outcomeId!: choice.text,
  };

  Map<String, String> get _targets => switch (_cancellation) {
    SceneDialogueChoiceCancellationKind.disabled => const {},
    SceneDialogueChoiceCancellationKind.choice => _choices,
    SceneDialogueChoiceCancellationKind.branch => _branches,
  };

  bool get _defaultValid =>
      _defaultOutcome.isEmpty || _choices.containsKey(_defaultOutcome);

  bool get _targetValid =>
      _cancellation == SceneDialogueChoiceCancellationKind.disabled ||
      _targets.containsKey(_target);

  @override
  Widget build(BuildContext context) {
    if (_scopes.isEmpty) {
      return const StudioNotice(
        'Aucun choix dans ce dialogue. Ajoutez un bloc de choix pour configurer son comportement.',
      );
    }
    final choices = _choices;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('scene-choice-scope'),
          label: 'Bloc de choix',
          value: '$_scopeIndex',
          options: {
            for (var index = 0; index < _scopes.length; index++)
              '$index':
                  '${_scopes[index].nodeName} · Choix ${_scopes[index].choiceIndex + 1} : '
                  '${_blocks[(_scopes[index].nodeName, _scopes[index].choiceIndex)]!.choices.map((choice) => choice.text).join(' / ')}',
          },
          onChanged: (value) => setState(() {
            _scopeIndex = int.parse(value);
            _readPolicy();
          }),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-choice-default'),
          label: 'Option sélectionnée au départ',
          value: _defaultValid ? _defaultOutcome : null,
          options: {'': 'Première option', ...choices},
          onChanged: (value) => setState(() => _defaultOutcome = value),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-choice-cancellation'),
          label: 'Quand le joueur annule',
          value: _cancellation.name,
          options: {
            'disabled': 'Annulation interdite',
            if (choices.isNotEmpty ||
                _cancellation == SceneDialogueChoiceCancellationKind.choice)
              'choice': 'Une option de ce choix',
            if (_branches.isNotEmpty ||
                _cancellation == SceneDialogueChoiceCancellationKind.branch)
              'branch': 'Une branche de la scène',
          },
          onChanged: (value) => setState(() {
            _cancellation = SceneDialogueChoiceCancellationKind.values.byName(
              value,
            );
            _target = _targets.keys.firstOrNull;
          }),
        ),
        if (_cancellation != SceneDialogueChoiceCancellationKind.disabled) ...[
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('scene-choice-target'),
            label: _cancellation == SceneDialogueChoiceCancellationKind.choice
                ? 'Option retenue en cas d’annulation'
                : 'Branche suivie en cas d’annulation',
            value: _targetValid ? _target : null,
            options: _targets,
            onChanged: (value) => setState(() => _target = value),
          ),
        ],
        if (!_defaultValid || !_targetValid) ...[
          const SizedBox(height: 12),
          const StudioNotice(
            'Le réglage existant vise une option qui n’existe plus ou une branche non reliée. Choisissez explicitement son nouveau comportement avant d’appliquer.',
            isError: true,
          ),
        ],
        if (choices.length != _block.choices.length) ...[
          const SizedBox(height: 12),
          const StudioNotice(
            'Seules les options avec une sortie déclarée et unique peuvent être ciblées par ces réglages.',
          ),
        ],
        if (_branches.isEmpty) ...[
          const SizedBox(height: 12),
          const StudioNotice(
            'Aucune branche d’annulation reliée dans cette scène. Reliez une sortie distincte du dialogue pour proposer cette possibilité.',
          ),
        ],
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('scene-choice-apply'),
          label: 'Appliquer le comportement des choix',
          onPressed: _defaultValid && _targetValid
              ? () => widget.onApply(
                  SceneDialogueChoicePolicy(
                    nodeName: _scope.nodeName,
                    choiceIndex: _scope.choiceIndex,
                    defaultOutcomeId: _defaultOutcome.isEmpty
                        ? null
                        : _defaultOutcome,
                    cancellation: switch (_cancellation) {
                      SceneDialogueChoiceCancellationKind.disabled =>
                        const SceneDialogueChoiceCancellation.disabled(),
                      SceneDialogueChoiceCancellationKind.choice =>
                        SceneDialogueChoiceCancellation.choice(_target!),
                      SceneDialogueChoiceCancellationKind.branch =>
                        SceneDialogueChoiceCancellation.branch(_target!),
                    },
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
