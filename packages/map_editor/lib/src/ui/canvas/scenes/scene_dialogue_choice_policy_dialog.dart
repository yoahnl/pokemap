import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showDialog;
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/scene_dialogue_choice_policy_authoring_gateway.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class SceneDialogueChoicePolicyAuthoringButton extends StatefulWidget {
  const SceneDialogueChoicePolicyAuthoringButton({
    super.key,
    this.load,
    this.save,
  });

  final Future<SceneDialogueChoicePolicyEditorData> Function()? load;
  final Future<bool> Function(SceneDialogueChoicePolicy policy)? save;

  @override
  State<SceneDialogueChoicePolicyAuthoringButton> createState() =>
      _SceneDialogueChoicePolicyAuthoringButtonState();
}

class _SceneDialogueChoicePolicyAuthoringButtonState
    extends State<SceneDialogueChoicePolicyAuthoringButton> {
  bool _busy = false;
  String? _message;
  bool _failed = false;

  Future<void> _edit() async {
    final load = widget.load;
    final save = widget.save;
    if (load == null || save == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final data = await load();
      if (!mounted) return;
      final policy = await showDialog<SceneDialogueChoicePolicy>(
        context: context,
        builder: (_) => SceneDialogueChoicePolicyDialog(data: data),
      );
      if (policy == null || !mounted) return;
      final applied = await save(policy);
      if (!mounted) return;
      setState(() {
        _failed = !applied;
        _message = applied
            ? 'Comportement des choix appliqué au brouillon.'
            : 'Le comportement des choix n’a pas été appliqué. Vérifiez les sorties de la scène et le dialogue.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message =
            'Le dialogue n’a pas pu être validé. Enregistrez puis rechargez le projet avant de réessayer.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PokeMapButton(
        key: const ValueKey('scene-dialogue-choice-policy-edit'),
        onPressed: widget.load == null || widget.save == null || _busy
            ? null
            : _edit,
        variant: PokeMapButtonVariant.secondary,
        size: PokeMapButtonSize.small,
        leading: const Icon(CupertinoIcons.list_bullet),
        child: Text(_busy ? 'Chargement des choix…' : 'Comportement des choix'),
      ),
      if (_message != null) ...[
        const SizedBox(height: 8),
        PokeMapDiagnosticCallout(
          severity: _failed
              ? PokeMapDiagnosticSeverity.error
              : PokeMapDiagnosticSeverity.info,
          message: _message!,
        ),
      ],
    ],
  );
}

class SceneDialogueChoicePolicyDialog extends StatefulWidget {
  const SceneDialogueChoicePolicyDialog({super.key, required this.data});

  final SceneDialogueChoicePolicyEditorData data;

  @override
  State<SceneDialogueChoicePolicyDialog> createState() =>
      _SceneDialogueChoicePolicyDialogState();
}

class _SceneDialogueChoicePolicyDialogState
    extends State<SceneDialogueChoicePolicyDialog> {
  int _scopeIndex = 0;
  String _defaultOutcome = '';
  SceneDialogueChoiceCancellationKind _kind =
      SceneDialogueChoiceCancellationKind.disabled;
  String _target = '';

  SceneDialogueChoiceScopeOption get _scope => widget.data.scopes[_scopeIndex];

  @override
  void initState() {
    super.initState();
    if (widget.data.scopes.isNotEmpty) _readPolicy();
  }

  void _readPolicy() {
    final policy = widget.data.policies
        .where(
          (policy) =>
              policy.nodeName == _scope.nodeName &&
              policy.choiceIndex == _scope.choiceIndex,
        )
        .firstOrNull;
    _defaultOutcome = policy?.defaultOutcomeId ?? '';
    _kind =
        policy?.cancellation.kind ??
        SceneDialogueChoiceCancellationKind.disabled;
    _target = policy?.cancellation.outcomeId ?? '';
  }

  List<SceneDialogueChoiceOption> get _targets => switch (_kind) {
    SceneDialogueChoiceCancellationKind.disabled => const [],
    SceneDialogueChoiceCancellationKind.choice => _scope.choices,
    SceneDialogueChoiceCancellationKind.branch => _scope.branches,
  };

  @override
  Widget build(BuildContext context) {
    final empty = widget.data.scopes.isEmpty;
    final canSave =
        !empty &&
        (_kind == SceneDialogueChoiceCancellationKind.disabled ||
            _targets.any((option) => option.outcomeId == _target));
    return PokeMapDialog(
      title: 'Comportement des choix',
      maxWidth: 560,
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        children: [
          PokeMapButton(
            onPressed: () => Navigator.of(context).pop(),
            variant: PokeMapButtonVariant.secondary,
            child: const Text('Fermer'),
          ),
          PokeMapButton(
            key: const ValueKey('scene-choice-policy-confirm'),
            onPressed: canSave
                ? () => Navigator.of(context).pop(
                    SceneDialogueChoicePolicy(
                      nodeName: _scope.nodeName,
                      choiceIndex: _scope.choiceIndex,
                      defaultOutcomeId: _defaultOutcome.isEmpty
                          ? null
                          : _defaultOutcome,
                      cancellation: switch (_kind) {
                        SceneDialogueChoiceCancellationKind.disabled =>
                          const SceneDialogueChoiceCancellation.disabled(),
                        SceneDialogueChoiceCancellationKind.choice =>
                          SceneDialogueChoiceCancellation.choice(_target),
                        SceneDialogueChoiceCancellationKind.branch =>
                          SceneDialogueChoiceCancellation.branch(_target),
                      },
                    ),
                  )
                : null,
            child: const Text('Appliquer au brouillon'),
          ),
        ],
      ),
      child: empty
          ? const PokeMapEmptyState(
              title: 'Aucun choix dans ce dialogue',
              description:
                  'Ajoutez un choix dans le dialogue pour configurer son comportement.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PokeMapDropdownField<int>(
                  key: const ValueKey('scene-choice-scope'),
                  label: 'Bloc de choix',
                  value: _scopeIndex,
                  items: [
                    for (
                      var index = 0;
                      index < widget.data.scopes.length;
                      index++
                    )
                      PokeMapDropdownItem(
                        value: index,
                        label: widget.data.scopes[index].label,
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _scopeIndex = value;
                    _readPolicy();
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  _scope.labels.join(' · '),
                  style: TextStyle(
                    color: context.pokeMapColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                PokeMapDropdownField<String>(
                  key: const ValueKey('scene-choice-default'),
                  label: 'Option sélectionnée au départ',
                  value: _defaultOutcome,
                  items: [
                    const PokeMapDropdownItem(
                      value: '',
                      label: 'Première option',
                    ),
                    for (final option in _scope.choices)
                      PokeMapDropdownItem(
                        value: option.outcomeId,
                        label: option.label,
                      ),
                  ],
                  onChanged: (value) => setState(() => _defaultOutcome = value),
                ),
                const SizedBox(height: 12),
                PokeMapDropdownField<SceneDialogueChoiceCancellationKind>(
                  key: const ValueKey('scene-choice-cancellation'),
                  label: 'Quand le joueur annule',
                  value: _kind,
                  items: [
                    const PokeMapDropdownItem(
                      value: SceneDialogueChoiceCancellationKind.disabled,
                      label: 'Annulation interdite',
                    ),
                    if (_scope.choices.isNotEmpty)
                      const PokeMapDropdownItem(
                        value: SceneDialogueChoiceCancellationKind.choice,
                        label: 'Une option de ce choix',
                      ),
                    if (_scope.branches.isNotEmpty)
                      const PokeMapDropdownItem(
                        value: SceneDialogueChoiceCancellationKind.branch,
                        label: 'Une branche de la scène',
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _kind = value;
                    _target = _targets.firstOrNull?.outcomeId ?? '';
                  }),
                ),
                if (_kind != SceneDialogueChoiceCancellationKind.disabled) ...[
                  const SizedBox(height: 12),
                  PokeMapDropdownField<String>(
                    key: const ValueKey('scene-choice-target'),
                    label: _kind == SceneDialogueChoiceCancellationKind.choice
                        ? 'Option retenue en cas d’annulation'
                        : 'Branche suivie en cas d’annulation',
                    value: _target,
                    items: [
                      for (final option in _targets)
                        PokeMapDropdownItem(
                          value: option.outcomeId,
                          label: option.label,
                        ),
                    ],
                    onChanged: (value) => setState(() => _target = value),
                  ),
                ],
              ],
            ),
    );
  }
}
