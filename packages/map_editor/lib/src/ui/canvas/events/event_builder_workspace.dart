import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderWorkspace extends StatefulWidget {
  const EventBuilderWorkspace({
    super.key,
    required this.readModel,
  });

  final EventBuilderReadModel readModel;

  @override
  State<EventBuilderWorkspace> createState() => _EventBuilderWorkspaceState();
}

class _EventBuilderWorkspaceState extends State<EventBuilderWorkspace> {
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(EventBuilderWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readModel != widget.readModel) {
      _syncSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selected = _selectedEvent();
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-workspace'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.bolt_horizontal_circle,
                tone: PokeMapTone.quest,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Événements',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Déclenchez des scènes depuis la carte, sous conditions, '
                      'puis suivez leurs conséquences.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const PokeMapBadge(
                label: 'Lecture seule',
                variant: PokeMapBadgeVariant.info,
                icon: Icon(CupertinoIcons.eye),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapStatusTile(
                label: 'Total',
                value: '${widget.readModel.events.length}',
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.quest,
              ),
              PokeMapStatusTile(
                label: 'Diagnostics',
                value: '${widget.readModel.diagnostics.length}',
                icon: CupertinoIcons.exclamationmark_triangle,
                tone: widget.readModel.diagnostics.isEmpty
                    ? PokeMapTone.success
                    : PokeMapTone.warning,
              ),
              PokeMapStatusTile(
                label: 'Portée',
                value: widget.readModel.mapTitle ?? 'Map active',
                icon: CupertinoIcons.map,
                tone: PokeMapTone.map,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.readModel.events.isEmpty
                ? const _EventBuilderEmptyState()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _EventListPanel(
                          events: widget.readModel.events,
                          selectedEventId: selected?.eventId,
                          onSelect: (eventId) {
                            setState(() => _selectedEventId = eventId);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EventDetailsPanel(event: selected),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _syncSelection() {
    final events = widget.readModel.events;
    if (events.isEmpty) {
      _selectedEventId = null;
      return;
    }
    final selectedStillExists =
        events.any((event) => event.eventId == _selectedEventId);
    if (!selectedStillExists) {
      _selectedEventId = events.first.eventId;
    }
  }

  EventBuilderEventSummary? _selectedEvent() {
    for (final event in widget.readModel.events) {
      if (event.eventId == _selectedEventId) {
        return event;
      }
    }
    return widget.readModel.events.isEmpty
        ? null
        : widget.readModel.events.first;
  }
}

class _EventBuilderEmptyState extends StatelessWidget {
  const _EventBuilderEmptyState();

  @override
  Widget build(BuildContext context) {
    return const PokeMapPanel(
      expandChild: true,
      child: PokeMapEmptyState(
        icon: Icon(CupertinoIcons.bolt_horizontal_circle),
        title: 'Aucun événement sur cette map',
        description: 'Le Builder d’événements affichera ici les déclencheurs '
            'authorés depuis la carte active.',
      ),
    );
  }
}

class _EventListPanel extends StatelessWidget {
  const _EventListPanel({
    required this.events,
    required this.selectedEventId,
    required this.onSelect,
  });

  final List<EventBuilderEventSummary> events;
  final String? selectedEventId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Liste de la map',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lecture seule depuis le contrat Event Builder.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('event-builder-event-list'),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = events[index];
                return _EventListCard(
                  event: event,
                  selected: event.eventId == selectedEventId,
                  onTap: () => onSelect(event.eventId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventListCard extends StatelessWidget {
  const _EventListCard({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final EventBuilderEventSummary event;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final conditionCount = event.conditions.length;
    final diagnosticCount = event.diagnostics.length;
    return PokeMapCard(
      key: ValueKey('event-builder-event-card-${event.eventId}'),
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PokeMapBadge(
                label: event.statusLabel,
                variant: _statusVariant(event.status),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _InlineInfo(
            icon: CupertinoIcons.bolt,
            label: event.trigger.label,
          ),
          const SizedBox(height: 5),
          _InlineInfo(
            icon: CupertinoIcons.play_rectangle,
            label: event.sceneAction.label,
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapBadge(
                label:
                    '$conditionCount condition${conditionCount > 1 ? 's' : ''}',
                variant: PokeMapBadgeVariant.neutral,
              ),
              PokeMapBadge(
                label:
                    '$diagnosticCount diagnostic${diagnosticCount > 1 ? 's' : ''}',
                variant: diagnosticCount == 0
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.warning,
              ),
              if (event.conditionEditingLocked)
                const PokeMapBadge(
                  label: 'Conditions verrouillées',
                  variant: PokeMapBadgeVariant.warning,
                  icon: Icon(CupertinoIcons.lock),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventDetailsPanel extends StatelessWidget {
  const _EventDetailsPanel({required this.event});

  final EventBuilderEventSummary? event;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selected = event;
    if (selected == null) {
      return const PokeMapPanel(
        expandChild: true,
        child: PokeMapEmptyState(
          icon: Icon(CupertinoIcons.sidebar_right),
          title: 'Sélectionnez un événement',
        ),
      );
    }

    return PokeMapPanel(
      key: const ValueKey('event-builder-event-details'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.bolt_horizontal_circle,
                tone: PokeMapTone.quest,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.displayName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID technique',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      selected.technicalId,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PokeMapBadge(
                label: selected.statusLabel,
                variant: _statusVariant(selected.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Déclencheur',
            children: [
              _DetailLine(label: 'Type', value: selected.trigger.label),
              _DetailLine(label: 'Source', value: selected.trigger.sourceLabel),
            ],
          ),
          _DetailSection(
            title: 'Conditions',
            children: [
              if (selected.conditionEditingMessage != null)
                _DiagnosticNotice(
                  title: 'Conditions verrouillées',
                  message: selected.conditionEditingMessage!,
                  tone: PokeMapTone.warning,
                ),
              if (selected.conditions.isEmpty)
                const _MutedText('Aucune condition')
              else
                for (final condition in selected.conditions)
                  _DetailLine(
                    label: condition.isEditable ? 'Condition' : 'Condition lue',
                    value: condition.label,
                  ),
            ],
          ),
          _DetailSection(
            title: 'Action principale',
            children: [
              _DetailLine(label: 'Scène', value: selected.sceneAction.label),
            ],
          ),
          _DetailSection(
            title: 'Comportement',
            children: [
              _DetailLine(
                  label: 'Réutilisation', value: selected.behavior.label),
            ],
          ),
          _DetailSection(
            title: 'Changements du monde',
            children: [
              if (selected.worldImpacts.isEmpty)
                const _MutedText('Aucun impact monde prévisible')
              else
                for (final impact in selected.worldImpacts)
                  _DetailLine(label: impact.reason, value: impact.label),
            ],
          ),
          _DetailSection(
            title: 'Diagnostics',
            children: [
              if (selected.diagnostics.isEmpty)
                const _DiagnosticNotice(
                  title: 'Aucun diagnostic',
                  message: 'Le read model ne signale aucun problème bloquant.',
                  tone: PokeMapTone.success,
                )
              else
                for (final diagnostic in selected.diagnostics)
                  _DiagnosticNotice(
                    title: diagnostic.title,
                    message: diagnostic.message,
                    tone: _diagnosticTone(diagnostic.severity),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        Icon(icon, size: 13, color: colors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PokeMapCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 116,
              child: Text(
                label.isEmpty ? 'Impact' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticNotice extends StatelessWidget {
  const _DiagnosticNotice({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Container(
        decoration: BoxDecoration(
          color: toneColors.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: toneColors.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.info_circle, size: 15, color: toneColors.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      text,
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

PokeMapBadgeVariant _statusVariant(EventBuilderEventStatus status) {
  return switch (status) {
    EventBuilderEventStatus.active => PokeMapBadgeVariant.success,
    EventBuilderEventStatus.draft => PokeMapBadgeVariant.warning,
    EventBuilderEventStatus.inactive => PokeMapBadgeVariant.neutral,
    EventBuilderEventStatus.invalid => PokeMapBadgeVariant.error,
  };
}

PokeMapTone _diagnosticTone(EventBuilderDiagnosticReadModelSeverity severity) {
  return switch (severity) {
    EventBuilderDiagnosticReadModelSeverity.info => PokeMapTone.info,
    EventBuilderDiagnosticReadModelSeverity.warning => PokeMapTone.warning,
    EventBuilderDiagnosticReadModelSeverity.error => PokeMapTone.danger,
  };
}
