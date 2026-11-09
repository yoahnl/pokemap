import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

typedef ScenePeriodicEncounterDraftUpdater =
    Future<bool> Function({
      required String nodeId,
      required bool enabled,
      required String label,
      required Set<PeriodicEncounterOutcome> consumeOnOutcomes,
    });

class PeriodicEncounterAuthoringPanel extends StatefulWidget {
  const PeriodicEncounterAuthoringPanel({
    super.key,
    required this.nodeId,
    required this.payload,
    required this.onUpdate,
  });

  final String nodeId;
  final SceneBattlePayload payload;
  final ScenePeriodicEncounterDraftUpdater? onUpdate;

  @override
  State<PeriodicEncounterAuthoringPanel> createState() =>
      _PeriodicEncounterAuthoringPanelState();
}

class _PeriodicEncounterAuthoringPanelState
    extends State<PeriodicEncounterAuthoringPanel> {
  late final TextEditingController _label;
  late bool _enabled;
  late Set<PeriodicEncounterOutcome> _outcomes;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController();
    _reset();
  }

  @override
  void didUpdateWidget(PeriodicEncounterAuthoringPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId != widget.nodeId ||
        oldWidget.payload != widget.payload) {
      _reset();
    }
  }

  void _reset() {
    final policy = widget.payload.periodicEncounter;
    _enabled = policy != null;
    _label.text = policy?.label ?? 'Rencontre quotidienne';
    _outcomes = {...?policy?.consumeOnOutcomes};
    if (policy == null) {
      _outcomes.addAll({
        PeriodicEncounterOutcome.victory,
        PeriodicEncounterOutcome.captured,
        PeriodicEncounterOutcome.fled,
      });
    }
    _error = null;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final update = widget.onUpdate;
    if (update == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    var saved = false;
    try {
      saved = await update(
        nodeId: widget.nodeId,
        enabled: _enabled,
        label: _label.text.trim(),
        consumeOnOutcomes: Set.of(_outcomes),
      );
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!saved) {
        _error =
            'La rencontre n’a pas pu être modifiée. Le brouillon précédent est conservé.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload.battleKind != 'wild' ||
        widget.payload.demonstration != null) {
      return const SizedBox.shrink();
    }
    final editable = widget.onUpdate != null && !_saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: !editable,
          child: PokeMapToggleTile(
            key: const ValueKey('periodic-encounter-enabled'),
            label: 'Rencontre quotidienne',
            description:
                'Une rencontre disponible une fois par jour civil local.',
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
        ),
        if (_enabled) ...[
          const SizedBox(height: 8),
          PokeMapTextField(
            label: 'Nom de la rencontre',
            controller: _label,
            enabled: editable,
            onChanged: (_) => setState(() {}),
          ),
          for (final outcome in PeriodicEncounterOutcome.values)
            CheckboxListTile(
              key: ValueKey('periodic-encounter-${outcome.name}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: context.pokeMapColors.brandPrimary,
              title: Text(switch (outcome) {
                PeriodicEncounterOutcome.victory =>
                  'Consommer après une victoire',
                PeriodicEncounterOutcome.captured =>
                  'Consommer après une capture',
                PeriodicEncounterOutcome.fled => 'Consommer après une fuite',
              }),
              value: _outcomes.contains(outcome),
              onChanged: !editable
                  ? null
                  : (value) => setState(() {
                      if (value == true) {
                        _outcomes.add(outcome);
                      } else {
                        _outcomes.remove(outcome);
                      }
                    }),
            ),
          const Text(
            'Défaite : la rencontre reste disponible. Choisissez au moins une issue.',
          ),
        ],
        if (_error != null)
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Rencontre quotidienne',
            message: _error!,
          ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey('periodic-encounter-apply'),
          onPressed:
              !editable ||
                  _enabled && (_outcomes.isEmpty || _label.text.trim().isEmpty)
              ? null
              : _apply,
          child: const Text('Appliquer la rencontre quotidienne'),
        ),
      ],
    );
  }
}
