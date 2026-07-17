import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class EventBuilderV2ProjectList extends StatelessWidget {
  const EventBuilderV2ProjectList({
    super.key,
    required this.groups,
    required this.projectEventCount,
    required this.selectedStableKey,
    required this.controls,
    required this.projectIsEmpty,
    required this.hasNoMatchingEvents,
    required this.onSelectEvent,
    required this.onCreateEvent,
  });

  final List<NarrativeEventProjectGroup> groups;
  final int projectEventCount;
  final String? selectedStableKey;
  final Widget controls;
  final bool projectIsEmpty;
  final bool hasNoMatchingEvents;
  final ValueChanged<NarrativeEventProjectSummary> onSelectEvent;
  final VoidCallback? onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final body = projectIsEmpty
        ? const PokeMapEmptyState(
            title: 'Aucun événement dans ce projet',
            description:
                'Créez un événement puis reliez-le à un élément déjà placé sur une map.',
            icon: Icon(CupertinoIcons.bolt_horizontal_circle),
          )
        : hasNoMatchingEvents
            ? const PokeMapEmptyState(
                title: 'Aucun résultat',
                description:
                    'Modifiez la recherche ou affichez un autre statut.',
                icon: Icon(CupertinoIcons.search),
              )
            : ListView.separated(
                key: const ValueKey('event-builder-v2-event-list-scroll'),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _ProjectGroup(
                    group: group,
                    selectedStableKey: selectedStableKey,
                    onSelectEvent: onSelectEvent,
                  );
                },
              );

    return PokeMapPanel(
      expandChild: true,
      borderRadius: 8,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Événements, $projectEventCount dans le projet',
                    child: const Text(
                      'Événements',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                PokeMapIconButton(
                  onPressed: onCreateEvent,
                  icon: const Icon(CupertinoIcons.add),
                  tooltip: 'Nouvel événement',
                  size: 30,
                ),
              ],
            ),
            const SizedBox(height: 8),
            controls,
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: PokeMapButton(
            key: const ValueKey('event-builder-v2-new-event'),
            onPressed: onCreateEvent,
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.add),
            child: const Text('Nouvel événement'),
          ),
        ),
      ),
      child: body,
    );
  }
}

class _ProjectGroup extends StatelessWidget {
  const _ProjectGroup({
    required this.group,
    required this.selectedStableKey,
    required this.onSelectEvent,
  });

  final NarrativeEventProjectGroup group;
  final String? selectedStableKey;
  final ValueChanged<NarrativeEventProjectSummary> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    final label = _groupLabel(group);
    return Semantics(
      container: true,
      label: '$label, ${group.events.length} événements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
            child: Row(
              children: [
                Icon(_groupIcon(group.kind), size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${group.events.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          for (final event in group.events)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: PokeMapSidebarItem(
                key: ValueKey('event-builder-v2-event-${event.stableKey}'),
                label: event.title,
                icon: Icon(_eventIcon(event)),
                compact: true,
                trailing: PokeMapStatusLabel(
                  label: _statusLabel(event),
                  tone: _statusTone(event),
                  icon: event.readOnly
                      ? CupertinoIcons.lock_fill
                      : CupertinoIcons.circle_fill,
                ),
                selected: selectedStableKey == event.stableKey,
                onTap: () => onSelectEvent(event),
              ),
            ),
        ],
      ),
    );
  }
}

String _groupLabel(NarrativeEventProjectGroup group) {
  return switch (group.kind) {
    NarrativeEventProjectGroupKind.map => group.label,
    NarrativeEventProjectGroupKind.outcomes => 'Événements globaux',
    NarrativeEventProjectGroupKind.drafts => 'Brouillons à terminer',
    NarrativeEventProjectGroupKind.missingReferences => 'Références à réparer',
    NarrativeEventProjectGroupKind.legacyCompatibility =>
      'Ancien format à convertir',
  };
}

IconData _groupIcon(NarrativeEventProjectGroupKind kind) => switch (kind) {
      NarrativeEventProjectGroupKind.map => CupertinoIcons.map,
      NarrativeEventProjectGroupKind.outcomes => CupertinoIcons.globe,
      NarrativeEventProjectGroupKind.drafts => CupertinoIcons.pencil,
      NarrativeEventProjectGroupKind.missingReferences =>
        CupertinoIcons.exclamationmark_triangle,
      NarrativeEventProjectGroupKind.legacyCompatibility =>
        CupertinoIcons.archivebox,
    };

IconData _eventIcon(NarrativeEventProjectSummary event) {
  if (event.readOnly) return CupertinoIcons.archivebox;
  if (!event.source.available) return CupertinoIcons.exclamationmark_triangle;
  return CupertinoIcons.bolt_horizontal_circle;
}

String _statusLabel(NarrativeEventProjectSummary event) {
  if (event.readOnly) return 'Ancien';
  return switch (event.status) {
    NarrativeEventProjectStatus.draftIncomplete => 'Brouillon',
    NarrativeEventProjectStatus.configuredDisabledReady => 'Inactif',
    NarrativeEventProjectStatus.configuredEnabledReady => 'Actif',
    NarrativeEventProjectStatus.attentionRequired => 'Attention',
    NarrativeEventProjectStatus.sourceMissing => 'Manquant',
    NarrativeEventProjectStatus.referenceInvalid => 'À réparer',
    NarrativeEventProjectStatus.migrationAssistanceRequired ||
    NarrativeEventProjectStatus.migrationBlocked ||
    NarrativeEventProjectStatus.legacyOnly =>
      'Ancien',
    NarrativeEventProjectStatus.unsupported => 'Indisponible',
    NarrativeEventProjectStatus.claimInvalid => 'Conversion',
  };
}

PokeMapTone _statusTone(
  NarrativeEventProjectSummary event,
) {
  if (event.readOnly) return PokeMapTone.warning;
  if (event.enabled == true) return PokeMapTone.success;
  return switch (event.severity) {
    NarrativeEventProjectSummarySeverity.info => PokeMapTone.neutral,
    NarrativeEventProjectSummarySeverity.warning => PokeMapTone.warning,
    NarrativeEventProjectSummarySeverity.error => PokeMapTone.danger,
  };
}
