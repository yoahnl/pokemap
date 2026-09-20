import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'event_view_state.dart';
import 'event_map_loader.dart';
import 'event_labels.dart';
import 'event_trigger_panel.dart';
import 'event_conditions.dart';
import 'event_scene_panel.dart';
import 'event_options_panel.dart';

class EventPageContent extends StatelessWidget {
  const EventPageContent({
    super.key,
    required this.record,
    required this.controller,
    required this.view,
    required this.loader,
    required this.visuals,
    required this.onLocate,
    required this.onScene,
    required this.mutate,
    required this.sceneDirtyIds,
    required this.onMode,
  });
  final NarrativeEventRecord record;
  final EventWorkspaceController controller;
  final EventViewState view;
  final EventMapLoader loader;
  final MapWorkspaceVisuals visuals;
  final ValueChanged<NarrativeEventSourceRef> onLocate;
  final ValueChanged<String> onScene;
  final ValueChanged<bool Function()> mutate;
  final Set<String> sceneDirtyIds;
  final VoidCallback onMode;
  @override
  Widget build(BuildContext context) => switch (view.tab) {
    EventTab.trigger => EventTriggerPanel(
      key: ValueKey('trigger:${record.id}'),
      controller: controller,
      record: record,
      loader: loader,
      visuals: visuals,
      view: view,
      onLocate: onLocate,
      onProducer: onScene,
    ),
    EventTab.conditions => EventConditions(
      key: ValueKey('conditions:${record.id}'),
      expression: eventExpression(record),
      facts: controller.project.facts,
      records: controller.records,
      onChanged: (value) =>
          mutate(() => controller.setExpression(record.id, value)),
    ),
    EventTab.scene => EventScenePanel(
      scenes: controller.project.scenes,
      selectedId: eventSceneId(record),
      dirtyIds: sceneDirtyIds,
      onSelect: (id) => mutate(() => controller.setScene(record.id, id)),
      onOpen: onScene,
      onRemove: () => mutate(() => controller.setScene(record.id, null)),
    ),
    EventTab.options => EventOptionsPanel(
      record: record,
      mode: controller.project.eventRegistry?.mode,
      outcomes: controller.catalog.outcomeSources,
      priorityInput: view.invalidNumbers['${record.id}:priority'],
      orderInput: view.invalidNumbers['${record.id}:order'],
      onReuse: (p) => mutate(() => controller.setReuse(record.id, p)),
      onReset: (p) => mutate(() => controller.setReset(record.id, p)),
      onPriority: (v) =>
          _number('priority', v, (n) => controller.setPriority(record.id, n)),
      onOrder: (v) =>
          _number('order', v, (n) => controller.setOrder(record.id, n)),
      onConfigure: () => mutate(() => controller.configure(record.id)),
      onEnabled: () => mutate(
        () => controller.setEnabled(record.id, record.enabledOrNull != true),
      ),
      onMode: onMode,
    ),
  };

  void _number(String field, String value, bool Function(int) apply) {
    final key = '${record.id}:$field';
    final parsed = int.tryParse(value);
    if (parsed == null) {
      view.invalidNumbers[key] = value;
      mutate(() {
        controller.error =
            'Saisissez un nombre entier pour la priorité et l’ordre.';
        return false;
      });
    } else {
      view.invalidNumbers.remove(key);
      mutate(() => apply(parsed));
    }
  }
}
