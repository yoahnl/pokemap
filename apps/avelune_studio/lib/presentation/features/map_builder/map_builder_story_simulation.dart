import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderStorySimulation extends StatefulWidget {
  const MapBuilderStorySimulation({
    super.key,
    required this.binding,
    required this.record,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;

  @override
  State<MapBuilderStorySimulation> createState() =>
      _MapBuilderStorySimulationState();
}

class _MapBuilderStorySimulationState extends State<MapBuilderStorySimulation> {
  final _values = <String, NarrativeValue>{};
  final _consumed = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final binding = widget.binding;
    final report = binding.simulate(
      NarrativeEventSimulationInput(
        targetEventId: widget.record.id,
        factNarrativeValues: _values,
        consumedNarrativeEventIds: _consumed,
      ),
    );
    if (report == null) return Text(l10n.simulationUnavailable);
    final facts = <String>{
      for (final candidate in report.candidates)
        for (final condition in candidate.conditions)
          if (condition.kind == NarrativeEventSimulationConditionKind.fact)
            condition.targetId,
    };
    final handled = report.candidates
        .where((candidate) => candidate.eventId == report.handledEventId)
        .firstOrNull;
    return Column(
      key: ValueKey('map-story-simulation-${widget.record.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.simulationHint, style: theme.textTheme.bodySmall),
        for (final factId in facts) _fact(factId),
        for (final candidate in report.candidates)
          if (candidate.reusePolicy == NarrativeEventReusePolicy.oneShot)
            StudioToggleRow(
              key: ValueKey('map-story-simulation-played-${candidate.eventId}'),
              label: l10n.simulationAlreadyPlayed(candidate.name),
              value: _consumed.contains(candidate.eventId),
              onChanged: (value) => setState(
                () => value
                    ? _consumed.add(candidate.eventId)
                    : _consumed.remove(candidate.eventId),
              ),
            ),
        const SizedBox(height: StudioSpacing.m),
        StudioNotice(
          key: const ValueKey('map-story-simulation-result'),
          handled == null
              ? l10n.simulationNothingPlays
              : l10n.simulationPlays(handled.name),
        ),
        for (final candidate in report.candidates)
          StudioChoice(
            key: ValueKey('map-story-simulation-case-${candidate.eventId}'),
            label: candidate.name,
            subtitle: candidate.eventId == report.handledEventId
                ? l10n.simulationChosen(candidate.priority, candidate.order)
                : candidate.reasons.isEmpty
                ? l10n.simulationOutranked(candidate.priority, candidate.order)
                : candidate.reasons
                      .map((reason) => l10n.simulationReason(reason.name))
                      .join(', '),
            onTap: null,
          ),
      ],
    );
  }

  Widget _fact(String factId) {
    final l10n = context.l10n;
    final fact = widget.binding.conditionFact(factId);
    final value = _values[factId] ?? fact?.initialValue;
    final label = fact?.label ?? l10n.memoryUnknownFact;
    if (value != null && value.kind == NarrativeValueKind.integer) {
      return MapBuilderNameField(
        key: ValueKey('map-story-simulation-fact-$factId'),
        value: '${value.intValue}',
        label: label,
        enabled: true,
        onCommit: (text) => switch (int.tryParse(text.trim())) {
          final number? => setState(
            () => _values[factId] = NarrativeValue.integer(number),
          ),
          null => null,
        },
      );
    }
    return StudioToggleRow(
      key: ValueKey('map-story-simulation-fact-$factId'),
      label: label,
      value: value?.kind == NarrativeValueKind.boolean && value!.boolValue,
      onChanged: (checked) =>
          setState(() => _values[factId] = NarrativeValue.boolean(checked)),
    );
  }
}
