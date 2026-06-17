import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

typedef EventBuilderTitleRenameCallback = bool Function({
  required String eventId,
  required String title,
});

typedef EventBuilderSceneActionUpdateCallback = bool Function({
  required String eventId,
  required String sceneId,
});

class EventBuilderSceneOption {
  const EventBuilderSceneOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class EventBuilderWorkspace extends StatefulWidget {
  const EventBuilderWorkspace({
    super.key,
    required this.readModel,
    this.draftCreationGate = const EventBuilderDraftCreationGate.disabled(),
    this.sceneOptions = const <EventBuilderSceneOption>[],
    this.onRenameEventTitle,
    this.onUpdateSceneAction,
  });

  final EventBuilderReadModel readModel;
  final EventBuilderDraftCreationGate draftCreationGate;
  final List<EventBuilderSceneOption> sceneOptions;
  final EventBuilderTitleRenameCallback? onRenameEventTitle;
  final EventBuilderSceneActionUpdateCallback? onUpdateSceneAction;

  @override
  State<EventBuilderWorkspace> createState() => _EventBuilderWorkspaceState();
}

class EventBuilderDraftCreationGate {
  const EventBuilderDraftCreationGate.disabled({
    this.disabledReason =
        'Sélectionnez une position sur la carte pour créer un événement.',
  })  : onCreateDraft = null,
        onCreateDraftAt = null,
        mapId = null,
        mapWidth = null,
        mapHeight = null,
        layerId = null,
        layerLabel = null,
        layerValid = false,
        readyLabel = 'Position requise';

  const EventBuilderDraftCreationGate.enabled({
    required this.onCreateDraft,
    this.readyLabel = 'Position prête',
  })  : onCreateDraftAt = null,
        disabledReason = null,
        mapId = null,
        mapWidth = null,
        mapHeight = null,
        layerId = null,
        layerLabel = null,
        layerValid = false;

  const EventBuilderDraftCreationGate.positionPicker({
    required this.mapId,
    required this.mapWidth,
    required this.mapHeight,
    required this.layerId,
    required this.layerLabel,
    required this.layerValid,
    required this.onCreateDraftAt,
    this.disabledReason =
        'Sélectionnez une position sur la carte pour créer un événement.',
  })  : onCreateDraft = null,
        readyLabel = 'Position requise';

  final VoidCallback? onCreateDraft;
  final String? Function(EventPosition position)? onCreateDraftAt;
  final String? disabledReason;
  final String readyLabel;
  final String? mapId;
  final int? mapWidth;
  final int? mapHeight;
  final String? layerId;
  final String? layerLabel;
  final bool layerValid;

  bool get canCreate => onCreateDraft != null;

  bool get hasPositionPicker {
    final width = mapWidth;
    final height = mapHeight;
    return mapId != null &&
        width != null &&
        height != null &&
        width > 0 &&
        height > 0;
  }
}

class _EventBuilderWorkspaceState extends State<EventBuilderWorkspace> {
  String? _selectedEventId;
  GridPos? _selectedDraftPosition;
  String? _draftCreationFeedback;
  PokeMapTone _draftCreationFeedbackTone = PokeMapTone.success;

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
    if (_positionPickerContextChanged(
      oldWidget.draftCreationGate,
      widget.draftCreationGate,
    )) {
      _selectedDraftPosition = null;
      _draftCreationFeedback = null;
      _draftCreationFeedbackTone = PokeMapTone.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selected = _selectedEvent();
    final activeCount = widget.readModel.events
        .where((event) => event.status == EventBuilderEventStatus.active)
        .length;
    final draftCount = widget.readModel.events
        .where((event) => event.status == EventBuilderEventStatus.draft)
        .length;
    final createDraftAction = _createDraftAction;
    final creationBadgeLabel = _creationBadgeLabel;
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PokeMapButton(
                    key: const ValueKey('event-builder-new-event-button'),
                    onPressed: createDraftAction,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.medium,
                    leading: const Icon(CupertinoIcons.plus),
                    child: const Text('Nouvel événement'),
                  ),
                  PokeMapBadge(
                    label: creationBadgeLabel,
                    variant: createDraftAction != null
                        ? PokeMapBadgeVariant.success
                        : PokeMapBadgeVariant.warning,
                    icon: Icon(createDraftAction != null
                        ? CupertinoIcons.checkmark_circle
                        : CupertinoIcons.location),
                  ),
                ],
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
                label: 'Actifs',
                value: '$activeCount',
                icon: CupertinoIcons.checkmark_circle,
                tone: activeCount == 0
                    ? PokeMapTone.neutral
                    : PokeMapTone.success,
              ),
              PokeMapStatusTile(
                label: 'Brouillons',
                value: '$draftCount',
                icon: CupertinoIcons.pencil_ellipsis_rectangle,
                tone:
                    draftCount == 0 ? PokeMapTone.neutral : PokeMapTone.warning,
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
          if (widget.draftCreationGate.hasPositionPicker) ...[
            const SizedBox(height: 12),
            _DraftPositionPickerPanel(
              gate: widget.draftCreationGate,
              selectedPosition: _selectedDraftPosition,
              onSelect: (position) {
                setState(() {
                  _selectedDraftPosition = position;
                  _draftCreationFeedback = null;
                  _draftCreationFeedbackTone = PokeMapTone.success;
                });
              },
              onClear: _selectedDraftPosition == null
                  ? null
                  : () {
                      setState(() {
                        _selectedDraftPosition = null;
                        _draftCreationFeedback = null;
                        _draftCreationFeedbackTone = PokeMapTone.success;
                      });
                    },
            ),
          ],
          if (_draftCreationFeedback != null) ...[
            const SizedBox(height: 12),
            _DraftCreationFeedbackNotice(
              message: _draftCreationFeedback!,
              tone: _draftCreationFeedbackTone,
            ),
          ],
          if (createDraftAction == null) ...[
            const SizedBox(height: 12),
            _DraftCreationGateNotice(message: _creationDisabledReason),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: widget.readModel.events.isEmpty
                ? _EventBuilderEmptyState(onCreateDraft: createDraftAction)
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
                        child: _EventDetailsPanel(
                          event: selected,
                          sceneOptions: widget.sceneOptions,
                          onRenameTitle: widget.onRenameEventTitle,
                          onUpdateSceneAction: widget.onUpdateSceneAction,
                        ),
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

  VoidCallback? get _createDraftAction {
    final gate = widget.draftCreationGate;
    final legacyAction = gate.onCreateDraft;
    if (legacyAction != null) {
      return legacyAction;
    }
    final position = _selectedDraftPosition;
    final layerId = gate.layerId?.trim();
    final create = gate.onCreateDraftAt;
    if (!gate.hasPositionPicker ||
        position == null ||
        layerId == null ||
        layerId.isEmpty ||
        !gate.layerValid ||
        create == null) {
      return null;
    }
    return () {
      final eventId = create(
        EventPosition(layerId: layerId, x: position.x, y: position.y),
      );
      if (eventId != null && eventId.trim().isNotEmpty) {
        setState(() {
          _selectedEventId = eventId;
          _selectedDraftPosition = null;
          _draftCreationFeedback =
              'Brouillon d’événement créé. Sélectionnez une nouvelle position '
              'pour en créer un autre.';
          _draftCreationFeedbackTone = PokeMapTone.success;
        });
        return;
      }
      setState(() {
        _draftCreationFeedback =
            'Impossible de créer le brouillon. Vérifiez la position et la '
            'couche, puis réessayez.';
        _draftCreationFeedbackTone = PokeMapTone.warning;
      });
    };
  }

  String get _creationBadgeLabel {
    if (_createDraftAction != null) {
      return 'Position prête';
    }
    final gate = widget.draftCreationGate;
    if (gate.hasPositionPicker && _selectedDraftPosition != null) {
      return gate.layerValid ? gate.readyLabel : 'Couche requise';
    }
    return gate.readyLabel;
  }

  String get _creationDisabledReason {
    final gate = widget.draftCreationGate;
    if (gate.hasPositionPicker && !gate.layerValid) {
      return 'Sélectionnez une couche de destination pour créer un événement.';
    }
    if (gate.hasPositionPicker && _selectedDraftPosition == null) {
      return 'Sélectionnez une position stable sur la carte pour créer un événement.';
    }
    return gate.disabledReason ??
        'Sélectionnez une position sur la carte pour créer un événement.';
  }

  bool _positionPickerContextChanged(
    EventBuilderDraftCreationGate previous,
    EventBuilderDraftCreationGate next,
  ) {
    return previous.mapId != next.mapId ||
        previous.mapWidth != next.mapWidth ||
        previous.mapHeight != next.mapHeight ||
        previous.layerId != next.layerId;
  }
}

class _EventBuilderEmptyState extends StatelessWidget {
  const _EventBuilderEmptyState({required this.onCreateDraft});

  final VoidCallback? onCreateDraft;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      child: SingleChildScrollView(
        child: PokeMapEmptyState(
          icon: const Icon(CupertinoIcons.bolt_horizontal_circle),
          title: 'Aucun événement sur cette map',
          description: 'Le Builder d’événements affichera ici les déclencheurs '
              'authorés depuis la carte active.',
          action: PokeMapButton(
            onPressed: onCreateDraft,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.plus),
            child: const Text('Nouvel événement'),
          ),
        ),
      ),
    );
  }
}

class _DraftPositionPickerPanel extends StatelessWidget {
  const _DraftPositionPickerPanel({
    required this.gate,
    required this.selectedPosition,
    required this.onSelect,
    required this.onClear,
  });

  final EventBuilderDraftCreationGate gate;
  final GridPos? selectedPosition;
  final ValueChanged<GridPos> onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final width = gate.mapWidth ?? 0;
    final height = gate.mapHeight ?? 0;
    final selected = selectedPosition;
    final positionLabel = selected == null
        ? 'Position sélectionnée : aucune'
        : 'Position sélectionnée : x ${selected.x}, y ${selected.y}';
    final crossAxisCount = width.clamp(1, 8).toInt();
    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.map_pin_ellipse,
                color: colors.brandPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Position du brouillon',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PokeMapBadge(
                label: gate.layerValid
                    ? 'Couche : ${gate.layerLabel ?? gate.layerId}'
                    : 'Couche requise',
                variant: gate.layerValid
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.warning,
                icon: Icon(gate.layerValid
                    ? CupertinoIcons.checkmark_circle
                    : CupertinoIcons.layers),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  positionLabel,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: const ValueKey('event-builder-clear-position'),
                onPressed: onClear,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.xmark),
                child: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 360,
              height: 190,
              child: GridView.builder(
                key: const ValueKey('event-builder-position-grid'),
                itemCount: width * height,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (context, index) {
                  final x = index % width;
                  final y = index ~/ width;
                  final isSelected = selected?.x == x && selected?.y == y;
                  return PokeMapButton(
                    key: ValueKey('event-builder-position-$x-$y'),
                    onPressed: () => onSelect(GridPos(x: x, y: y)),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: isSelected,
                    child: Text('$x,$y'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCreationFeedbackNotice extends StatelessWidget {
  const _DraftCreationFeedbackNotice({
    required this.message,
    required this.tone,
  });

  final String message;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == PokeMapTone.success
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.exclamationmark_triangle,
            color: toneColors.icon,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCreationGateNotice extends StatelessWidget {
  const _DraftCreationGateNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.location,
            color: colors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
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
            'Création de brouillon uniquement. L’édition reste verrouillée '
            'dans ce lot.',
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
    final blockingCount = event.diagnostics
        .where((diagnostic) =>
            diagnostic.severity ==
            EventBuilderDiagnosticReadModelSeverity.error)
        .length;
    final actionLabel = event.sceneAction.isMissing
        ? 'Aucune action principale'
        : event.sceneAction.label;
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
            label: actionLabel,
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
                label: diagnosticCount == 0
                    ? 'Aucun diagnostic'
                    : '$diagnosticCount diagnostic${diagnosticCount > 1 ? 's' : ''}',
                variant: diagnosticCount == 0
                    ? PokeMapBadgeVariant.success
                    : blockingCount > 0
                        ? PokeMapBadgeVariant.error
                        : PokeMapBadgeVariant.warning,
                icon: diagnosticCount == 0
                    ? const Icon(CupertinoIcons.checkmark_circle)
                    : const Icon(CupertinoIcons.exclamationmark_triangle),
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

class _EventDetailsPanel extends StatefulWidget {
  const _EventDetailsPanel({
    required this.event,
    required this.sceneOptions,
    required this.onRenameTitle,
    required this.onUpdateSceneAction,
  });

  final EventBuilderEventSummary? event;
  final List<EventBuilderSceneOption> sceneOptions;
  final EventBuilderTitleRenameCallback? onRenameTitle;
  final EventBuilderSceneActionUpdateCallback? onUpdateSceneAction;

  @override
  State<_EventDetailsPanel> createState() => _EventDetailsPanelState();
}

class _EventDetailsPanelState extends State<_EventDetailsPanel> {
  late final TextEditingController _titleController;
  bool _isEditingTitle = false;
  String? _titleError;
  String? _titleFeedback;
  bool _isChoosingScene = false;
  String? _sceneError;
  String? _sceneFeedback;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.event?.displayName ?? '',
    );
  }

  @override
  void didUpdateWidget(_EventDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousId = oldWidget.event?.eventId;
    final next = widget.event;
    if (previousId != next?.eventId) {
      _isEditingTitle = false;
      _titleError = null;
      _titleFeedback = null;
      _isChoosingScene = false;
      _sceneError = null;
      _sceneFeedback = null;
      _titleController.text = next?.displayName ?? '';
      return;
    }
    if (!_isEditingTitle && next != null) {
      _titleController.text = next.displayName;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.event;
    if (selected == null) {
      return const PokeMapPanel(
        expandChild: true,
        child: PokeMapEmptyState(
          icon: Icon(CupertinoIcons.sidebar_right),
          title: 'Sélectionnez un événement',
        ),
      );
    }

    final sections = {
      for (final section in selected.sections) section.key: section,
    };
    return PokeMapPanel(
      key: const ValueKey('event-builder-event-details'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  child: _buildTitleBlock(context, selected),
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
              section: sections['trigger'],
              children: [
                _DetailLine(label: 'Type', value: selected.trigger.label),
                _DetailLine(
                    label: 'Source', value: selected.trigger.sourceLabel),
              ],
            ),
            _DetailSection(
              title: 'Conditions',
              section: sections['conditions'],
              summaryOverride: selected.conditionEditingLocked
                  ? 'Condition avancée conservée en lecture seule'
                  : null,
              children: [
                if (selected.conditionEditingLocked)
                  const _DiagnosticNotice(
                    title: 'Conditions verrouillées',
                    message:
                        'Cette condition contient une partie avancée préservée.\n'
                        'Elle est lisible, mais pas encore éditable '
                        'partiellement.\n'
                        'La condition complète est conservée telle quelle.',
                    tone: PokeMapTone.warning,
                    severityLabel: 'Avertissement',
                    details: ['Section : Conditions'],
                  ),
                if (selected.conditions.isEmpty)
                  const _MutedText('Aucune condition')
                else
                  for (final condition in selected.conditions)
                    _ConditionDetailLine(condition: condition),
              ],
            ),
            _DetailSection(
              title: 'Action principale',
              section: sections['actions'],
              children: [
                _buildSceneActionBlock(context, selected),
              ],
            ),
            _DetailSection(
              title: 'Comportement',
              section: sections['behavior'],
              children: [
                _DetailLine(
                  label: 'Réutilisation',
                  value: selected.behavior.label,
                ),
              ],
            ),
            _DetailSection(
              title: 'Changements du monde',
              section: sections['world'],
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
                    message:
                        'Le read model ne signale aucun problème bloquant.',
                    tone: PokeMapTone.success,
                    severityLabel: 'OK',
                    details: ['Toutes les sections sont lisibles'],
                  )
                else
                  for (final diagnostic in selected.diagnostics)
                    _DiagnosticNotice(
                      title: diagnostic.title,
                      message: diagnostic.message,
                      tone: _diagnosticTone(diagnostic.severity),
                      severityLabel: _diagnosticSeverityLabel(
                        diagnostic.severity,
                      ),
                      details: [
                        'Section : ${_diagnosticSectionLabel(diagnostic.sectionTarget)}',
                        if (diagnostic.path.isNotEmpty)
                          'Chemin : ${diagnostic.path}',
                        if (diagnostic.referencedId != null)
                          'Référence : ${diagnostic.referencedId}',
                      ],
                    ),
              ],
            ),
            _DetailSection(
              title: 'Informations techniques',
              children: [
                _DetailLine(label: 'ID technique', value: selected.technicalId),
                _DetailLine(label: 'Groupe', value: selected.groupKey),
                _DetailLine(
                  label: 'Position',
                  value: 'x ${selected.position.x}, y ${selected.position.y}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBlock(
    BuildContext context,
    EventBuilderEventSummary selected,
  ) {
    final colors = context.pokeMapColors;
    if (_isEditingTitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Titre de l’événement',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: const ValueKey('event-builder-title-field'),
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveTitle(selected),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            placeholder: 'Titre de l’événement',
            placeholderStyle: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.controlSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _titleError == null
                    ? colors.borderSubtle
                    : colors.errorBorder,
              ),
            ),
          ),
          if (_titleError != null) ...[
            const SizedBox(height: 6),
            Text(
              _titleError!,
              style: TextStyle(
                color: colors.error,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapButton(
                key: const ValueKey('event-builder-cancel-title-button'),
                onPressed: () => _cancelTitleEdit(selected),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.xmark),
                child: const Text('Annuler'),
              ),
              PokeMapButton(
                key: const ValueKey('event-builder-save-title-button'),
                onPressed: () => _saveTitle(selected),
                variant: PokeMapButtonVariant.success,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.checkmark),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TechnicalIdHint(technicalId: selected.technicalId),
        ],
      );
    }

    return Column(
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (widget.onRenameTitle != null)
              PokeMapButton(
                key: const ValueKey('event-builder-rename-title-button'),
                onPressed: () => _startTitleEdit(selected),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.pencil),
                child: const Text('Renommer'),
              ),
            if (_titleFeedback != null)
              PokeMapBadge(
                label: _titleFeedback!,
                variant: PokeMapBadgeVariant.success,
                icon: const Icon(CupertinoIcons.checkmark_circle),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _TechnicalIdHint(technicalId: selected.technicalId),
      ],
    );
  }

  Widget _buildSceneActionBlock(
    BuildContext context,
    EventBuilderEventSummary selected,
  ) {
    final colors = context.pokeMapColors;
    final canUpdateScene = widget.onUpdateSceneAction != null;
    final sceneButtonLabel = selected.sceneAction.isMissing
        ? 'Choisir une scène'
        : 'Changer la scène';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailLine(
          label: selected.sceneAction.isMissing ? 'État' : 'Scène',
          value: selected.sceneAction.label,
        ),
        if (canUpdateScene) ...[
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PokeMapButton(
                key: const ValueKey('event-builder-choose-scene-button'),
                onPressed: () => _startSceneChoice(),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.play_rectangle),
                child: Text(sceneButtonLabel),
              ),
              if (_isChoosingScene)
                PokeMapButton(
                  key: const ValueKey('event-builder-cancel-scene-button'),
                  onPressed: _cancelSceneChoice,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.xmark),
                  child: const Text('Annuler'),
                ),
              if (_sceneFeedback != null)
                PokeMapBadge(
                  label: _sceneFeedback!,
                  variant: PokeMapBadgeVariant.success,
                  icon: const Icon(CupertinoIcons.checkmark_circle),
                ),
            ],
          ),
        ],
        if (_isChoosingScene) ...[
          const SizedBox(height: 8),
          if (widget.sceneOptions.isEmpty)
            const _DiagnosticNotice(
              title: 'Aucune scène disponible.',
              message:
                  'Créez une scène dans le workspace Scènes avant de choisir '
                  'l’action principale de cet événement.',
              tone: PokeMapTone.warning,
              severityLabel: 'Action indisponible',
              details: ['Aucune création de scène dans ce lot'],
            )
          else
            // Picker borné : les options viennent du ProjectManifest et
            // l'utilisateur ne saisit jamais de sceneId à la main dans ce lot.
            PokeMapCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Scènes disponibles',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in widget.sceneOptions)
                        PokeMapButton(
                          key: ValueKey(
                            'event-builder-scene-option-${option.id}',
                          ),
                          onPressed: () => _selectScene(selected, option),
                          variant: PokeMapButtonVariant.secondary,
                          size: PokeMapButtonSize.small,
                          isSelected: selected.sceneAction.sceneId == option.id,
                          leading: const Icon(CupertinoIcons.film),
                          child: Text(option.label),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (_sceneError != null) ...[
            const SizedBox(height: 6),
            Text(
              _sceneError!,
              style: TextStyle(
                color: colors.error,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _startTitleEdit(EventBuilderEventSummary selected) {
    setState(() {
      _isEditingTitle = true;
      _titleError = null;
      _titleFeedback = null;
      _titleController.text = selected.displayName;
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );
    });
  }

  void _cancelTitleEdit(EventBuilderEventSummary selected) {
    setState(() {
      _isEditingTitle = false;
      _titleError = null;
      _titleFeedback = null;
      _titleController.text = selected.displayName;
    });
  }

  void _saveTitle(EventBuilderEventSummary selected) {
    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty) {
      setState(() {
        _titleError = 'Le titre est obligatoire.';
        _titleFeedback = null;
      });
      return;
    }
    if (trimmedTitle == selected.displayName.trim()) {
      setState(() {
        _isEditingTitle = false;
        _titleError = null;
        _titleFeedback = null;
        _titleController.text = selected.displayName;
      });
      return;
    }
    final renamed = widget.onRenameTitle?.call(
          eventId: selected.eventId,
          title: trimmedTitle,
        ) ??
        false;
    if (!renamed) {
      setState(() {
        _titleError = 'Impossible de renommer cet événement.';
        _titleFeedback = null;
      });
      return;
    }
    setState(() {
      _isEditingTitle = false;
      _titleError = null;
      _titleFeedback = 'Titre mis à jour.';
      _titleController.text = trimmedTitle;
    });
  }

  void _startSceneChoice() {
    setState(() {
      _isChoosingScene = true;
      _sceneError = null;
      _sceneFeedback = null;
    });
  }

  void _cancelSceneChoice() {
    setState(() {
      _isChoosingScene = false;
      _sceneError = null;
    });
  }

  void _selectScene(
    EventBuilderEventSummary selected,
    EventBuilderSceneOption option,
  ) {
    final updated = widget.onUpdateSceneAction?.call(
          eventId: selected.eventId,
          sceneId: option.id,
        ) ??
        false;
    if (!updated) {
      setState(() {
        _sceneError = 'Impossible de choisir cette scène.';
        _sceneFeedback = null;
      });
      return;
    }
    setState(() {
      _isChoosingScene = false;
      _sceneError = null;
      _sceneFeedback = 'Scène mise à jour.';
    });
  }
}

class _TechnicalIdHint extends StatelessWidget {
  const _TechnicalIdHint({required this.technicalId});

  final String technicalId;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID technique',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          technicalId,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    this.section,
    this.summaryOverride,
  });

  final String title;
  final List<Widget> children;
  final EventBuilderSectionReadModel? section;
  final String? summaryOverride;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (section != null) ...[
                const SizedBox(width: 8),
                PokeMapBadge(
                  label: section!.diagnosticCount == 0
                      ? '0 diagnostic'
                      : '${section!.diagnosticCount} diagnostic${section!.diagnosticCount > 1 ? 's' : ''}',
                  variant: section!.diagnosticCount == 0
                      ? PokeMapBadgeVariant.success
                      : section!.hasBlockingDiagnostic
                          ? PokeMapBadgeVariant.error
                          : PokeMapBadgeVariant.warning,
                ),
                if (section!.hasBlockingDiagnostic) ...[
                  const SizedBox(width: 6),
                  const PokeMapBadge(
                    label: 'Bloquant',
                    variant: PokeMapBadgeVariant.error,
                  ),
                ],
              ],
            ],
          ),
          if (summaryOverride != null || section != null) ...[
            const SizedBox(height: 5),
            Text(
              summaryOverride ?? section!.summary,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 8),
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

class _ConditionDetailLine extends StatelessWidget {
  const _ConditionDetailLine({required this.condition});

  final EventBuilderConditionReadModel condition;

  @override
  Widget build(BuildContext context) {
    return _DetailLine(
      label: condition.isEditable ? 'Condition' : 'Condition lue',
      value: condition.isSupported
          ? condition.label
          : '${condition.label}\nLecture seule dans ce lot',
    );
  }
}

class _DiagnosticNotice extends StatelessWidget {
  const _DiagnosticNotice({
    required this.title,
    required this.message,
    required this.tone,
    this.severityLabel,
    this.details = const <String>[],
  });

  final String title;
  final String message;
  final PokeMapTone tone;
  final String? severityLabel;
  final List<String> details;

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
                  if (severityLabel != null) ...[
                    const SizedBox(height: 4),
                    PokeMapBadge(
                      label: severityLabel!,
                      variant: _diagnosticBadgeVariant(tone),
                    ),
                  ],
                  const SizedBox(height: 3),
                  for (final line in message.split('\n'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    for (final detail in details)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          detail,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                  ],
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

PokeMapBadgeVariant _diagnosticBadgeVariant(PokeMapTone tone) {
  return switch (tone) {
    PokeMapTone.success => PokeMapBadgeVariant.success,
    PokeMapTone.warning => PokeMapBadgeVariant.warning,
    PokeMapTone.danger => PokeMapBadgeVariant.error,
    PokeMapTone.info => PokeMapBadgeVariant.info,
    _ => PokeMapBadgeVariant.neutral,
  };
}

String _diagnosticSeverityLabel(
  EventBuilderDiagnosticReadModelSeverity severity,
) {
  return switch (severity) {
    EventBuilderDiagnosticReadModelSeverity.info => 'Information',
    EventBuilderDiagnosticReadModelSeverity.warning => 'Avertissement',
    EventBuilderDiagnosticReadModelSeverity.error => 'Erreur',
  };
}

String _diagnosticSectionLabel(String section) {
  return switch (section) {
    'trigger' => 'Déclencheur',
    'conditions' => 'Conditions',
    'actions' => 'Action principale',
    'behavior' => 'Comportement',
    'world' => 'Changements du monde',
    'event' => 'Événement',
    _ => section,
  };
}
