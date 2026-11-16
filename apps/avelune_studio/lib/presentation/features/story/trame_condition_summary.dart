import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameConditionSummary extends StatelessWidget {
  const TrameConditionSummary({
    super.key,
    required this.trame,
    required this.condition,
  });

  final StorylineTrameController trame;
  final ScriptCondition condition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final params = condition.params;
    final group = switch (condition.type) {
      ScriptConditionType.allOf => l10n.trameConditionAll,
      ScriptConditionType.anyOf => l10n.trameConditionAny,
      ScriptConditionType.not => l10n.trameConditionNot,
      _ => null,
    };
    String value(String key) {
      final raw = params[key] ?? '';
      if (key == ScriptConditionParams.factId) {
        return trame.factName(raw) ?? l10n.memoryUnknownFact;
      }
      if (key == ScriptConditionParams.stepId) {
        return trame.view?.milestone(raw)?.milestone.title ?? l10n.trameUnnamed;
      }
      if (key == ScriptConditionParams.mapId) {
        return trame
                .source()
                .maps
                .where((map) => map.id == raw)
                .firstOrNull
                ?.name ??
            l10n.behavioursMissingMap;
      }
      if (key == ScriptConditionParams.value &&
          params[ScriptConditionParams.valueType] ==
              NarrativeValueKind.boolean.wireName) {
        return raw == 'true'
            ? l10n.trameConditionTrue
            : l10n.trameConditionFalse;
      }
      return raw;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group ??
              '${l10n.trameConditionKind(condition.type.name)} : ${params.keys.where((key) => key != ScriptConditionParams.valueType).map(value).join(' · ')}',
        ),
        for (final child in condition.children)
          Padding(
            padding: const EdgeInsets.only(
              left: StudioSpacing.l,
              top: StudioSpacing.s,
            ),
            child: TrameConditionSummary(trame: trame, condition: child),
          ),
      ],
    );
  }
}
