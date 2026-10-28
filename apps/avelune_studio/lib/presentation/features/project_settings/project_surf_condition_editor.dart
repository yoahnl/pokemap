import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/project_surf/application/project_surf_controller.dart';
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
  String _kind = 'fact';
  Map<String, String> _items = const {};
  NarrativeFactDefinition? _fact;
  String? _error;
  bool _loading = false;
  ScriptCondition? _currentCondition;
  String? _currentSourceDraft;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    final condition = widget.owner.preview.value.condition;
    _currentCondition = condition;
    _currentSourceDraft = widget.owner.conditionSourceDraft;
    _kind =
        widget.owner.conditionSourceDraft ??
        switch (condition?.type) {
          ScriptConditionType.badgeOwned => 'badge',
          ScriptConditionType.itemQuantityAtLeast => 'item',
          ScriptConditionType.factEquals || null => 'fact',
          _ => 'advanced',
        };
    if (_kind == 'item') unawaited(_loadItems());
    if (_kind == 'fact' &&
        condition != null &&
        widget.owner.conditionSourceDraft == null) {
      final id = condition.params[ScriptConditionParams.factId];
      if (id != null && _fact?.id != id) unawaited(_loadFact(id, apply: false));
    }
  }

  @override
  void didUpdateWidget(ProjectSurfConditionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentCondition != widget.owner.preview.value.condition ||
        _currentSourceDraft != widget.owner.conditionSourceDraft) {
      _sync();
    }
    if (widget.owner.inputError == null) _error = null;
  }

  Future<void> _loadItems() async {
    if (_items.isNotEmpty || _loading) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader = widget.loadItems;
      if (loader == null) {
        throw StateError('Le catalogue des objets est indisponible.');
      }
      final items = await loader();
      if (mounted && generation == _generation) setState(() => _items = items);
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadFact(String id, {bool apply = true}) async {
    if (apply) widget.owner.selectConditionSource('fact');
    final draftRevision = widget.owner.draftRevision;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fact = await widget.owner.port.loadSurfFact(
        widget.owner.session,
        id,
      );
      if (!mounted ||
          generation != _generation ||
          widget.owner.preview.value.accessMode !=
              ProjectSurfAccessMode.condition ||
          widget.owner.draftRevision != draftRevision) {
        return;
      }
      setState(() => _fact = fact);
      if (apply) {
        widget.owner.change(
          condition: ScriptConditionFactory.factEquals(id, fact.initialValue),
        );
      }
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
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
              ? (value) {
                  _generation++;
                  owner.selectConditionSource(value);
                  setState(() {
                    _kind = value;
                    _fact = null;
                    _error = null;
                    _loading = false;
                  });
                  if (value == 'item') unawaited(_loadItems());
                }
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
                ? (value) {
                    if (_kind == 'fact') {
                      unawaited(_loadFact(value));
                    } else if (_kind == 'badge') {
                      owner.change(
                        condition: ScriptConditionFactory.badgeOwned(value),
                      );
                    } else {
                      owner.change(
                        condition: ScriptConditionFactory.itemQuantityAtLeast(
                          value,
                          1,
                        ),
                      );
                    }
                  }
                : null,
          ),
        if (_kind == 'fact' && id != null && _fact?.id == id) ...[
          const SizedBox(height: 8),
          if (_fact!.valueKind == NarrativeValueKind.boolean)
            StudioSelect(
              label: 'Valeur attendue',
              value: condition!.params[ScriptConditionParams.value],
              options: const {'true': 'Activé', 'false': 'Désactivé'},
              onChanged: enabled
                  ? (value) => owner.change(
                      condition: ScriptConditionFactory.factEquals(
                        id,
                        NarrativeValue.boolean(value == 'true'),
                      ),
                    )
                  : null,
            )
          else
            StudioDraftField(
              label: 'Valeur attendue',
              value:
                  owner.conditionInput ??
                  condition!.params[ScriptConditionParams.value] ??
                  '',
              enabled: enabled,
              onChanged: (value) {
                final integer = int.tryParse(value);
                if (_fact!.valueKind == NarrativeValueKind.integer &&
                    (integer == null ||
                        integer < -9007199254740991 ||
                        integer > 9007199254740991)) {
                  setState(
                    () => _error = 'Saisissez un entier compris entre −9007199254740991 et 9007199254740991.',
                  );
                  owner.rejectInput(_error!, value: value);
                  return;
                }
                setState(() => _error = null);
                owner.acceptInput();
                owner.change(
                  condition: ScriptConditionFactory.factEquals(
                    id,
                    _fact!.valueKind == NarrativeValueKind.integer
                        ? NarrativeValue.integer(integer!)
                        : NarrativeValue.string(value),
                  ),
                );
              },
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
            onChanged: (value) {
              final quantity = int.tryParse(value);
              if (quantity == null ||
                  quantity < 1 ||
                  quantity > 9007199254740991) {
                setState(
                  () => _error = 'Saisissez une quantité supérieure à zéro.',
                );
                owner.rejectInput(_error!, value: value);
                return;
              }
              setState(() => _error = null);
              owner.acceptInput();
              owner.change(
                condition: ScriptConditionFactory.itemQuantityAtLeast(
                  id,
                  quantity,
                ),
              );
            },
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
    _generation++;
    super.dispose();
  }
}
