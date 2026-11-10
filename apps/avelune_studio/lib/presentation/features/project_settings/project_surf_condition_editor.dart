import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/project_surf/application/project_surf_controller.dart';
import '../../../features/project_surf/application/project_surf_condition_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class ProjectSurfConditionEditor extends StatefulWidget {
  const ProjectSurfConditionEditor({
    super.key,
    required this.owner,
    required this.enabled,
    this.loadItems,
  });
  final ProjectSurfController owner;
  final bool enabled;
  final Future<Map<String, String>> Function()? loadItems;
  @override
  State<ProjectSurfConditionEditor> createState() =>
      _ProjectSurfConditionEditorState();
}

class _ProjectSurfConditionEditorState
    extends State<ProjectSurfConditionEditor> {
  late ProjectSurfConditionController _condition;
  String get _kind => _condition.kind;
  Map<String, String> get _items => _condition.items;
  NarrativeFactDefinition? get _fact => _condition.fact;
  String? get _error => _condition.error;
  bool get _loading => _condition.loading;

  @override
  void initState() {
    super.initState();
    _createCondition();
  }

  void _createCondition() {
    _condition = ProjectSurfConditionController(
      owner: widget.owner,
      loadItems: widget.loadItems,
    );
    _condition.addListener(_changed);
    final condition = _condition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_condition, condition)) {
        unawaited(condition.start());
      }
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ProjectSurfConditionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner ||
        oldWidget.loadItems != widget.loadItems) {
      _condition.removeListener(_changed);
      _condition.dispose();
      _createCondition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final condition = owner.preview.value.condition;
    final enabled = widget.enabled && !_loading && !owner.loadingReferences;
    final references = owner.references;
    final id = switch (_kind) {
      'fact' =>
        condition?.type == ScriptConditionType.factEquals
            ? condition?.params[ScriptConditionParams.factId]
            : null,
      'badge' =>
        condition?.type == ScriptConditionType.badgeOwned
            ? condition?.params[ScriptConditionParams.badgeId]
            : null,
      'item' =>
        condition?.type == ScriptConditionType.itemQuantityAtLeast
            ? condition?.params[ScriptConditionParams.itemId]
            : null,
      _ => null,
    };
    final options = switch (_kind) {
      'fact' => references?.facts ?? const <String, String>{},
      'badge' => references?.badges ?? const <String, String>{},
      'item' => _items,
      _ => const <String, String>{},
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_kind == 'advanced')
          const Text(
            'La condition avancée existante est conservée. Choisissez une source puis une référence pour la remplacer.',
          ),
        StudioSelect(
          key: const ValueKey('surf-condition-kind'),
          label: 'Source de la condition',
          value: _kind,
          options: {
            'fact': 'État du monde',
            'badge': 'Badge obtenu',
            'item': 'Objet dans le sac',
            if (_kind == 'advanced') 'advanced': 'Condition avancée existante',
          },
          onChanged: widget.enabled
              ? (value) => unawaited(_condition.selectSource(value))
              : null,
        ),
        const SizedBox(height: 8),
        if (_kind != 'advanced')
          StudioSelect(
            key: const ValueKey('surf-condition-reference'),
            label: switch (_kind) {
              'fact' => 'État du monde requis',
              'badge' => 'Badge requis',
              _ => 'Objet requis',
            },
            value: id,
            options: options,
            onChanged: enabled
                ? (value) => unawaited(_condition.selectReference(value))
                : null,
          ),
        if (_kind == 'fact' && id != null && _fact?.id == id) ...[
          const SizedBox(height: 8),
          if (_fact!.valueKind == NarrativeValueKind.boolean)
            StudioSelect(
              label: 'Valeur attendue',
              value: condition!.params[ScriptConditionParams.value],
              options: const {'true': 'Activé', 'false': 'Désactivé'},
              onChanged: enabled ? _condition.editValue : null,
            )
          else
            StudioDraftField(
              label: 'Valeur attendue',
              value:
                  owner.conditionInput ??
                  condition!.params[ScriptConditionParams.value] ??
                  '',
              enabled: enabled,
              onChanged: _condition.editValue,
            ),
        ],
        if (_kind == 'item' && id != null) ...[
          const SizedBox(height: 8),
          StudioDraftField(
            label: 'Quantité minimale',
            value:
                owner.conditionInput ??
                condition!.params[ScriptConditionParams.quantity] ??
                '1',
            enabled: enabled,
            onChanged: _condition.editQuantity,
          ),
        ],
        if (owner.loadingReferences || _loading)
          const Text('Chargement des références…'),
        if (owner.referencesError case final error?) ...[
          Text(error),
          StudioButton(
            label: 'Réessayer',
            secondary: true,
            onPressed: owner.loadReferences,
          ),
        ],
        if (_error ?? owner.inputError case final error?)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (!_loading &&
            !owner.loadingReferences &&
            _kind != 'advanced' &&
            options.isEmpty)
          const Text('Aucune référence disponible pour cette source.'),
        if (condition == null)
          const Text(
            'Choisissez une référence avant d’enregistrer l’autorisation conditionnelle.',
          ),
      ],
    );
  }

  @override
  void dispose() {
    _condition.removeListener(_changed);
    _condition.dispose();
    super.dispose();
  }
}
