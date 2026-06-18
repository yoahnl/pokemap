import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'event_builder_creation_panel.dart';
import 'event_builder_central_flow.dart';
import 'event_builder_flow_blocks.dart';
import 'event_builder_element_library.dart';
import 'event_builder_inspector_panel.dart';

typedef EventBuilderTitleRenameCallback = bool Function({
  required String eventId,
  required String title,
});

typedef EventBuilderTriggerTypeUpdateCallback = bool Function({
  required String eventId,
  required MapEventType type,
});

typedef EventBuilderSceneActionUpdateCallback = bool Function({
  required String eventId,
  required String sceneId,
});

typedef EventBuilderReusePolicyUpdateCallback = bool Function({
  required String eventId,
  required EventBuilderReusePolicy reusePolicy,
});

typedef EventBuilderFactConditionAddCallback = bool Function({
  required String eventId,
  required String factId,
  required bool expectedValue,
});

typedef EventBuilderEventConsumedConditionAddCallback = bool Function({
  required String eventId,
  required String targetEventId,
  required bool expectedConsumed,
});

typedef EventBuilderConditionRemoveCallback = bool Function({
  required String eventId,
  required int conditionIndex,
});

typedef EventBuilderMapOpenCallback = Future<void> Function(String mapId);

class EventBuilderMapOption {
  const EventBuilderMapOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class EventBuilderSceneOption {
  const EventBuilderSceneOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class EventBuilderFactOption {
  const EventBuilderFactOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class EventBuilderConditionEventOption {
  const EventBuilderConditionEventOption({
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
    this.factOptions = const <EventBuilderFactOption>[],
    this.eventConditionOptions = const <EventBuilderConditionEventOption>[],
    this.mapOptions = const <EventBuilderMapOption>[],
    this.onOpenMap,
    this.onRenameEventTitle,
    this.onUpdateTriggerType,
    this.onUpdateSceneAction,
    this.onUpdateReusePolicy,
    this.onAddFactCondition,
    this.onAddEventConsumedCondition,
    this.onRemoveCondition,
  });

  final EventBuilderReadModel readModel;
  final EventBuilderDraftCreationGate draftCreationGate;
  final List<EventBuilderSceneOption> sceneOptions;
  final List<EventBuilderFactOption> factOptions;
  final List<EventBuilderConditionEventOption> eventConditionOptions;
  final List<EventBuilderMapOption> mapOptions;
  final EventBuilderMapOpenCallback? onOpenMap;
  final EventBuilderTitleRenameCallback? onRenameEventTitle;
  final EventBuilderTriggerTypeUpdateCallback? onUpdateTriggerType;
  final EventBuilderSceneActionUpdateCallback? onUpdateSceneAction;
  final EventBuilderReusePolicyUpdateCallback? onUpdateReusePolicy;
  final EventBuilderFactConditionAddCallback? onAddFactCondition;
  final EventBuilderEventConsumedConditionAddCallback?
      onAddEventConsumedCondition;
  final EventBuilderConditionRemoveCallback? onRemoveCondition;

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
  bool _isCreationPanelExpanded = false;
  final _eventDetailsKey = GlobalKey<_EventDetailsPanelState>();

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
    final newEventAction = _newEventAction(createDraftAction);
    final creationBadgeLabel = _creationBadgeLabel;
    final creationControls = _creationControlWidgets(createDraftAction);
    final creationBadgeVariant = createDraftAction != null
        ? PokeMapBadgeVariant.success
        : PokeMapBadgeVariant.warning;
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
                    onPressed: newEventAction,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.medium,
                    leading: const Icon(CupertinoIcons.plus),
                    child: const Text('Nouvel événement'),
                  ),
                  PokeMapBadge(
                    label: creationBadgeLabel,
                    variant: creationBadgeVariant,
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
                value: widget.readModel.mapTitle ?? 'Aucune map',
                icon: CupertinoIcons.map,
                tone: PokeMapTone.map,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.readModel.events.isEmpty
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 360,
                        child: EventBuilderCreationPanel(
                          key: const ValueKey('event-builder-creation-panel'),
                          isExpanded: true,
                          controls: creationControls,
                          onToggle: null,
                          compactMessage: _draftCreationFeedback,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EventBuilderEmptyState(
                          onCreateDraft: createDraftAction,
                          hasActiveMap: widget.readModel.mapId != null,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: _isCreationPanelExpanded ? 1 : 3,
                              child: _EventListPanel(
                                events: widget.readModel.events,
                                selectedEventId: selected?.eventId,
                                onSelect: (eventId) {
                                  setState(() => _selectedEventId = eventId);
                                },
                              ),
                            ),
                            if (creationControls.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              if (_isCreationPanelExpanded)
                                Expanded(
                                  flex: 2,
                                  child: EventBuilderCreationPanel(
                                    key: const ValueKey(
                                      'event-builder-creation-panel',
                                    ),
                                    isExpanded: true,
                                    controls: creationControls,
                                    compactMessage: _draftCreationFeedback,
                                    onToggle: () {
                                      setState(() {
                                        _isCreationPanelExpanded = false;
                                      });
                                    },
                                  ),
                                )
                              else
                                EventBuilderCreationPanel(
                                  key: const ValueKey(
                                    'event-builder-creation-panel',
                                  ),
                                  isExpanded: false,
                                  controls: creationControls,
                                  compactMessage: _draftCreationFeedback,
                                  onToggle: () {
                                    setState(() {
                                      _isCreationPanelExpanded = true;
                                    });
                                  },
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 260,
                        child: EventBuilderElementLibrary(
                          onActivate: _activateLibraryAction,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EventDetailsPanel(
                          key: _eventDetailsKey,
                          event: selected,
                          sceneOptions: widget.sceneOptions,
                          factOptions: widget.factOptions,
                          eventConditionOptions: widget.eventConditionOptions,
                          onRenameTitle: widget.onRenameEventTitle,
                          onUpdateTriggerType: widget.onUpdateTriggerType,
                          onUpdateSceneAction: widget.onUpdateSceneAction,
                          onUpdateReusePolicy: widget.onUpdateReusePolicy,
                          onAddFactCondition: widget.onAddFactCondition,
                          onAddEventConsumedCondition:
                              widget.onAddEventConsumedCondition,
                          onRemoveCondition: widget.onRemoveCondition,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _activateLibraryAction(EventBuilderLibraryAction action) {
    _eventDetailsKey.currentState?.activateLibraryAction(action);
  }

  VoidCallback? _newEventAction(VoidCallback? createDraftAction) {
    if (createDraftAction != null) {
      return createDraftAction;
    }
    if (_requiresMapActivation ||
        _isCreationPanelExpanded ||
        !widget.draftCreationGate.hasPositionPicker) {
      return null;
    }
    return () {
      setState(() {
        _isCreationPanelExpanded = true;
      });
    };
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

  List<Widget> _creationControlWidgets(VoidCallback? createDraftAction) {
    final controls = <Widget>[];
    void append(Widget control) {
      if (controls.isNotEmpty) {
        controls.add(const SizedBox(height: 12));
      }
      controls.add(control);
    }

    if (widget.draftCreationGate.hasPositionPicker) {
      append(
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
      );
    }
    if (_requiresMapActivation) {
      append(
        _MapActivationPanel(
          mapOptions: widget.mapOptions,
          onOpenMap: widget.onOpenMap,
        ),
      );
    }
    if (_draftCreationFeedback != null) {
      append(
        _DraftCreationFeedbackNotice(
          message: _draftCreationFeedback!,
          tone: _draftCreationFeedbackTone,
        ),
      );
    }
    if (createDraftAction == null &&
        (!widget.draftCreationGate.hasPositionPicker ||
            !widget.draftCreationGate.layerValid)) {
      append(_DraftCreationGateNotice(message: _creationDisabledReason));
    }
    return controls;
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
          _isCreationPanelExpanded = false;
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

  bool get _requiresMapActivation {
    return widget.readModel.mapId == null &&
        !widget.draftCreationGate.hasPositionPicker;
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
  const _EventBuilderEmptyState({
    required this.onCreateDraft,
    required this.hasActiveMap,
  });

  final VoidCallback? onCreateDraft;
  final bool hasActiveMap;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      child: SingleChildScrollView(
        child: PokeMapEmptyState(
          icon: const Icon(CupertinoIcons.bolt_horizontal_circle),
          title: hasActiveMap ? 'Aucun événement sur cette map' : 'Map requise',
          description: hasActiveMap
              ? 'Le Builder d’événements affichera ici les déclencheurs '
                  'authorés depuis la carte active.'
              : 'Choisissez une map du projet avant de placer un brouillon.',
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

class _MapActivationPanel extends StatelessWidget {
  const _MapActivationPanel({
    required this.mapOptions,
    required this.onOpenMap,
  });

  final List<EventBuilderMapOption> mapOptions;
  final EventBuilderMapOpenCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('event-builder-map-activation-panel'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.map,
                color: colors.brandPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aucune map active',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const PokeMapBadge(
                label: 'Map requise',
                variant: PokeMapBadgeVariant.warning,
                icon: Icon(CupertinoIcons.exclamationmark_triangle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez une map du projet pour créer des événements.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (mapOptions.isEmpty) ...[
            Text(
              'Aucune map dans ce projet.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Créez une map avant d’ajouter des événements.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ] else
            for (final map in mapOptions) ...[
              PokeMapButton(
                key: ValueKey('event-builder-open-map-${map.id}'),
                onPressed: onOpenMap == null ? null : () => onOpenMap!(map.id),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.folder_open),
                child: Text('Ouvrir “${map.label}”'),
              ),
              if (map != mapOptions.last) const SizedBox(height: 8),
            ],
        ],
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
                  'Position de création',
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
          Text(
            'Choisissez une position stable, puis utilisez le builder guidé.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
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
              height: 166,
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
            'Liste d’événements',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Édition guidée : déclencheur, conditions, scène et comportement.',
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
    super.key,
    required this.event,
    required this.sceneOptions,
    required this.factOptions,
    required this.eventConditionOptions,
    required this.onRenameTitle,
    required this.onUpdateTriggerType,
    required this.onUpdateSceneAction,
    required this.onUpdateReusePolicy,
    required this.onAddFactCondition,
    required this.onAddEventConsumedCondition,
    required this.onRemoveCondition,
  });

  final EventBuilderEventSummary? event;
  final List<EventBuilderSceneOption> sceneOptions;
  final List<EventBuilderFactOption> factOptions;
  final List<EventBuilderConditionEventOption> eventConditionOptions;
  final EventBuilderTitleRenameCallback? onRenameTitle;
  final EventBuilderTriggerTypeUpdateCallback? onUpdateTriggerType;
  final EventBuilderSceneActionUpdateCallback? onUpdateSceneAction;
  final EventBuilderReusePolicyUpdateCallback? onUpdateReusePolicy;
  final EventBuilderFactConditionAddCallback? onAddFactCondition;
  final EventBuilderEventConsumedConditionAddCallback?
      onAddEventConsumedCondition;
  final EventBuilderConditionRemoveCallback? onRemoveCondition;

  @override
  State<_EventDetailsPanel> createState() => _EventDetailsPanelState();
}

class _EventDetailsPanelState extends State<_EventDetailsPanel> {
  late final TextEditingController _titleController;
  bool _isEditingTitle = false;
  String? _titleError;
  String? _titleFeedback;
  String? _triggerError;
  String? _triggerFeedback;
  bool _isChoosingScene = false;
  String? _sceneError;
  String? _sceneFeedback;
  String? _behaviorError;
  String? _behaviorFeedback;
  bool _isChoosingFactCondition = false;
  bool _isChoosingEventCondition = false;
  String? _conditionError;
  String? _conditionFeedback;

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
      _triggerError = null;
      _triggerFeedback = null;
      _isChoosingScene = false;
      _sceneError = null;
      _sceneFeedback = null;
      _behaviorError = null;
      _behaviorFeedback = null;
      _isChoosingFactCondition = false;
      _isChoosingEventCondition = false;
      _conditionError = null;
      _conditionFeedback = null;
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
    final centralFlow = EventBuilderCentralFlow(
      title: 'Builder d’événement',
      subtitle: 'Composez le Quand / Si / Alors sans ouvrir de script libre.',
      eventHeader: PokeMapCard(
        borderRadius: 8,
        padding: const EdgeInsets.all(12),
        child: Row(
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
      ),
      blocks: [
        EventBuilderFlowBlock(
          key: const ValueKey('event-builder-flow-block-trigger'),
          phaseLabel: 'Quand',
          title: 'Déclencheur',
          icon: CupertinoIcons.bolt_horizontal_circle,
          tone: PokeMapTone.quest,
          summary: sections['trigger']?.summary,
          diagnosticCount: sections['trigger']?.diagnosticCount,
          hasBlockingDiagnostic:
              sections['trigger']?.hasBlockingDiagnostic ?? false,
          children: [
            _buildTriggerBlock(context, selected),
          ],
        ),
        EventBuilderFlowBlock(
          key: const ValueKey('event-builder-flow-block-conditions'),
          phaseLabel: 'Si',
          title: 'Conditions',
          icon: CupertinoIcons.slider_horizontal_3,
          tone: PokeMapTone.info,
          summary: selected.conditionEditingLocked
              ? 'Condition avancée conservée en lecture seule'
              : sections['conditions']?.summary,
          diagnosticCount: sections['conditions']?.diagnosticCount,
          hasBlockingDiagnostic:
              sections['conditions']?.hasBlockingDiagnostic ?? false,
          children: [
            _buildConditionsBlock(context, selected),
          ],
        ),
        EventBuilderFlowBlock(
          key: const ValueKey('event-builder-flow-block-actions'),
          phaseLabel: 'Alors',
          title: 'Action principale',
          icon: CupertinoIcons.play_rectangle,
          tone: PokeMapTone.success,
          summary: sections['actions']?.summary,
          diagnosticCount: sections['actions']?.diagnosticCount,
          hasBlockingDiagnostic:
              sections['actions']?.hasBlockingDiagnostic ?? false,
          children: [
            _buildSceneActionBlock(context, selected),
          ],
        ),
        EventBuilderFlowBlock(
          key: const ValueKey('event-builder-flow-block-behavior'),
          phaseLabel: 'Puis',
          title: 'Comportement',
          icon: CupertinoIcons.repeat,
          tone: PokeMapTone.warning,
          summary: sections['behavior']?.summary,
          diagnosticCount: sections['behavior']?.diagnosticCount,
          hasBlockingDiagnostic:
              sections['behavior']?.hasBlockingDiagnostic ?? false,
          children: [
            _buildBehaviorBlock(context, selected),
          ],
        ),
        EventBuilderFlowBlock(
          key: const ValueKey('event-builder-flow-block-world'),
          phaseLabel: 'Puis',
          title: 'Changements du monde',
          icon: CupertinoIcons.globe,
          tone: PokeMapTone.fact,
          summary: sections['world']?.summary,
          diagnosticCount: sections['world']?.diagnosticCount,
          hasBlockingDiagnostic:
              sections['world']?.hasBlockingDiagnostic ?? false,
          children: [
            const _MutedText('Piloté par les conséquences de scène.'),
            if (selected.worldImpacts.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final impact in selected.worldImpacts)
                _DetailLine(label: impact.reason, value: impact.label),
            ],
          ],
        ),
        EventBuilderFlowBlock(
          key: const ValueKey('event-builder-flow-block-diagnostics'),
          phaseLabel: 'Statut',
          title: 'Diagnostics',
          icon: CupertinoIcons.checkmark_shield,
          tone: selected.diagnostics.isEmpty
              ? PokeMapTone.success
              : PokeMapTone.warning,
          summary: selected.diagnostics.isEmpty
              ? 'Aucun problème bloquant signalé par le read model.'
              : '${selected.diagnostics.length} diagnostic${selected.diagnostics.length > 1 ? 's' : ''} à traiter.',
          children: [
            if (selected.diagnostics.isEmpty)
              const _DiagnosticNotice(
                title: 'Aucun diagnostic',
                message: 'Le read model ne signale aucun problème bloquant.',
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
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: centralFlow),
        const SizedBox(width: 12),
        SizedBox(
          width: 260,
          child: EventBuilderInspectorPanel(event: selected),
        ),
      ],
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
      ],
    );
  }

  Widget _buildTriggerBlock(
    BuildContext context,
    EventBuilderEventSummary selected,
  ) {
    final colors = context.pokeMapColors;
    final currentType = _triggerTypeForLabel(selected.trigger.label);
    final canUpdateTrigger =
        widget.onUpdateTriggerType != null && currentType != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailLine(label: 'Type', value: selected.trigger.label),
        _DetailLine(label: 'Source', value: selected.trigger.sourceLabel),
        if (widget.onUpdateTriggerType != null && currentType == null) ...[
          const SizedBox(height: 8),
          const _DiagnosticNotice(
            title: 'Déclencheur en lecture seule',
            message: 'Ce type de déclencheur n’est pas éditable dans ce lot.',
            tone: PokeMapTone.warning,
            severityLabel: 'Action indisponible',
            details: ['Types MVP : PNJ, objet, zone'],
          ),
        ],
        if (canUpdateTrigger) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TriggerTypeButton(
                key: const ValueKey('event-builder-trigger-actor-button'),
                label: 'Interaction avec un PNJ',
                icon: CupertinoIcons.person_crop_circle,
                type: MapEventType.actor,
                currentType: currentType,
                onSelect: (type) => _selectTriggerType(selected, type),
              ),
              _TriggerTypeButton(
                key: const ValueKey('event-builder-trigger-object-button'),
                label: 'Interaction avec un objet',
                icon: CupertinoIcons.cube_box,
                type: MapEventType.object,
                currentType: currentType,
                onSelect: (type) => _selectTriggerType(selected, type),
              ),
              _TriggerTypeButton(
                key: const ValueKey('event-builder-trigger-zone-button'),
                label: 'Entrée dans une zone',
                icon: CupertinoIcons.square_grid_2x2,
                type: MapEventType.triggerZone,
                currentType: currentType,
                onSelect: (type) => _selectTriggerType(selected, type),
              ),
              if (_triggerFeedback != null)
                PokeMapBadge(
                  label: _triggerFeedback!,
                  variant: PokeMapBadgeVariant.success,
                  icon: const Icon(CupertinoIcons.checkmark_circle),
                ),
            ],
          ),
          if (_triggerError != null) ...[
            const SizedBox(height: 6),
            Text(
              _triggerError!,
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

  Widget _buildConditionsBlock(
    BuildContext context,
    EventBuilderEventSummary selected,
  ) {
    final colors = context.pokeMapColors;
    final canRemoveCondition =
        widget.onRemoveCondition != null && !selected.conditionEditingLocked;
    final canAddFactCondition =
        widget.onAddFactCondition != null && canRemoveCondition;
    final canAddEventCondition =
        widget.onAddEventConsumedCondition != null && canRemoveCondition;
    final eventConditionOptions = _eventConditionOptionsFor(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected.conditionEditingLocked)
          const _DiagnosticNotice(
            title: 'Conditions verrouillées',
            message: 'Cette condition contient une partie avancée préservée.\n'
                'Elle est lisible, mais pas encore éditable partiellement.\n'
                'La condition complète est conservée telle quelle.',
            tone: PokeMapTone.warning,
            severityLabel: 'Avertissement',
            details: ['Section : Conditions'],
          ),
        if (selected.conditions.isEmpty)
          const _EmptyConditionSlot()
        else
          for (var i = 0; i < selected.conditions.length; i++)
            _ConditionDetailLine(
              key: ValueKey('event-builder-condition-row-$i'),
              condition: selected.conditions[i],
              onRemove: canRemoveCondition &&
                      _isEditableConditionKind(selected.conditions[i].kind)
                  ? () => _removeCondition(selected, i)
                  : null,
              removeKey: ValueKey('event-builder-remove-condition-$i'),
            ),
        if (canAddFactCondition) ...[
          const SizedBox(height: 8),
          if (widget.factOptions.isEmpty)
            const _DiagnosticNotice(
              title: 'Aucun Fact disponible.',
              message:
                  'Créez un Fact dans le workspace Facts avant d’ajouter une '
                  'condition.',
              tone: PokeMapTone.warning,
              severityLabel: 'Action indisponible',
              details: ['Aucune création de Fact dans ce lot'],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PokeMapButton(
                  key: const ValueKey(
                    'event-builder-add-fact-condition-button',
                  ),
                  onPressed: () => _startFactConditionChoice(),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.slider_horizontal_3),
                  child: const Text('Ajouter une condition Fact'),
                ),
                if (_isChoosingFactCondition)
                  PokeMapButton(
                    key: const ValueKey(
                      'event-builder-cancel-fact-condition-button',
                    ),
                    onPressed: _cancelFactConditionChoice,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.xmark),
                    child: const Text('Annuler'),
                  ),
                if (_conditionFeedback != null)
                  PokeMapBadge(
                    label: _conditionFeedback!,
                    variant: PokeMapBadgeVariant.success,
                    icon: const Icon(CupertinoIcons.checkmark_circle),
                  ),
              ],
            ),
          if (_isChoosingFactCondition && widget.factOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            PokeMapCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Facts disponibles',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final option in widget.factOptions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FactConditionOptionRow(
                        option: option,
                        onTrue: () => _addFactCondition(
                          selected,
                          option,
                          expectedValue: true,
                        ),
                        onFalse: () => _addFactCondition(
                          selected,
                          option,
                          expectedValue: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
        if (canAddEventCondition) ...[
          const SizedBox(height: 8),
          if (eventConditionOptions.isEmpty)
            const _DiagnosticNotice(
              title: 'Aucun autre événement disponible.',
              message: 'Créez d’abord un autre événement sur cette map pour '
                  'ajouter cette condition.',
              tone: PokeMapTone.warning,
              severityLabel: 'Action indisponible',
              details: ['L’événement courant est exclu des cibles V0'],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PokeMapButton(
                  key: const ValueKey(
                    'event-builder-add-event-condition-button',
                  ),
                  onPressed: () => _startEventConditionChoice(),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.link_circle),
                  child: const Text('Ajouter une condition d’événement'),
                ),
                if (_isChoosingEventCondition)
                  PokeMapButton(
                    key: const ValueKey(
                      'event-builder-cancel-event-condition-button',
                    ),
                    onPressed: _cancelEventConditionChoice,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.xmark),
                    child: const Text('Annuler'),
                  ),
              ],
            ),
          if (_isChoosingEventCondition &&
              eventConditionOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            PokeMapCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Événements disponibles',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final option in eventConditionOptions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _EventConditionOptionRow(
                        option: option,
                        onConsumed: () => _addEventConsumedCondition(
                          selected,
                          option,
                          expectedConsumed: true,
                        ),
                        onNotConsumed: () => _addEventConsumedCondition(
                          selected,
                          option,
                          expectedConsumed: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
        if (_conditionError != null) ...[
          const SizedBox(height: 6),
          Text(
            _conditionError!,
            style: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  List<EventBuilderConditionEventOption> _eventConditionOptionsFor(
    EventBuilderEventSummary selected,
  ) {
    return [
      for (final option in widget.eventConditionOptions)
        // L'auto-cible reste exclue en V0 : elle serait techniquement possible,
        // mais trop ambigüe pour un workflow no-code lisible.
        if (option.id != selected.eventId) option,
    ];
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
        _SceneActionSlot(sceneAction: selected.sceneAction),
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

  Widget _buildBehaviorBlock(
    BuildContext context,
    EventBuilderEventSummary selected,
  ) {
    final colors = context.pokeMapColors;
    final canUpdateBehavior = widget.onUpdateReusePolicy != null;
    final currentPolicy = selected.behavior.reusePolicy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailLine(
          label: 'Réutilisation',
          value: selected.behavior.label,
        ),
        if (canUpdateBehavior) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PokeMapButton(
                key: const ValueKey('event-builder-reuse-oneShot-button'),
                onPressed: currentPolicy == EventBuilderReusePolicy.oneShot
                    ? null
                    : () => _selectReusePolicy(
                          selected,
                          EventBuilderReusePolicy.oneShot,
                        ),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                isSelected: currentPolicy == EventBuilderReusePolicy.oneShot,
                leading: const Icon(CupertinoIcons.checkmark_circle),
                child: const Text('Une seule fois'),
              ),
              PokeMapButton(
                key: const ValueKey('event-builder-reuse-reusable-button'),
                onPressed: currentPolicy == EventBuilderReusePolicy.reusable
                    ? null
                    : () => _selectReusePolicy(
                          selected,
                          EventBuilderReusePolicy.reusable,
                        ),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                isSelected: currentPolicy == EventBuilderReusePolicy.reusable,
                leading: const Icon(CupertinoIcons.repeat),
                child: const Text('Réutilisable'),
              ),
              if (_behaviorFeedback != null)
                PokeMapBadge(
                  label: _behaviorFeedback!,
                  variant: PokeMapBadgeVariant.success,
                  icon: const Icon(CupertinoIcons.checkmark_circle),
                ),
            ],
          ),
          if (_behaviorError != null) ...[
            const SizedBox(height: 6),
            Text(
              _behaviorError!,
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

  void _selectTriggerType(
    EventBuilderEventSummary selected,
    MapEventType type,
  ) {
    final updated = widget.onUpdateTriggerType?.call(
          eventId: selected.eventId,
          type: type,
        ) ??
        false;
    if (!updated) {
      setState(() {
        _triggerError = 'Impossible de modifier ce déclencheur.';
        _triggerFeedback = null;
      });
      return;
    }
    setState(() {
      _triggerError = null;
      _triggerFeedback = 'Déclencheur mis à jour.';
    });
  }

  void _startFactConditionChoice() {
    setState(() {
      _isChoosingFactCondition = true;
      _isChoosingEventCondition = false;
      _conditionError = null;
      _conditionFeedback = null;
    });
  }

  void _cancelFactConditionChoice() {
    setState(() {
      _isChoosingFactCondition = false;
      _conditionError = null;
    });
  }

  void _startEventConditionChoice() {
    setState(() {
      _isChoosingEventCondition = true;
      _isChoosingFactCondition = false;
      _conditionError = null;
      _conditionFeedback = null;
    });
  }

  void _cancelEventConditionChoice() {
    setState(() {
      _isChoosingEventCondition = false;
      _conditionError = null;
    });
  }

  void activateLibraryAction(EventBuilderLibraryAction action) {
    final selected = widget.event;
    if (selected == null) {
      return;
    }
    switch (action) {
      case EventBuilderLibraryAction.triggerActor:
        _selectTriggerTypeFromLibrary(selected, MapEventType.actor);
        break;
      case EventBuilderLibraryAction.triggerObject:
        _selectTriggerTypeFromLibrary(selected, MapEventType.object);
        break;
      case EventBuilderLibraryAction.triggerZone:
        _selectTriggerTypeFromLibrary(selected, MapEventType.triggerZone);
        break;
      case EventBuilderLibraryAction.conditionFact:
        _startFactConditionChoiceFromLibrary(selected);
        break;
      case EventBuilderLibraryAction.conditionEventConsumed:
        _startEventConditionChoiceFromLibrary(selected);
        break;
      case EventBuilderLibraryAction.actionScene:
        _startSceneChoiceFromLibrary();
        break;
    }
  }

  void _selectTriggerTypeFromLibrary(
    EventBuilderEventSummary selected,
    MapEventType type,
  ) {
    if (widget.onUpdateTriggerType == null) {
      setState(() {
        _triggerError = 'Ce déclencheur n’est pas modifiable dans ce lot.';
        _triggerFeedback = null;
      });
      return;
    }
    final currentType = _triggerTypeForLabel(selected.trigger.label);
    if (currentType == type) {
      setState(() {
        _triggerError = null;
        _triggerFeedback = 'Déclencheur déjà sélectionné.';
      });
      return;
    }
    _selectTriggerType(selected, type);
  }

  void _startFactConditionChoiceFromLibrary(
    EventBuilderEventSummary selected,
  ) {
    if (selected.conditionEditingLocked || widget.onAddFactCondition == null) {
      setState(() {
        _isChoosingFactCondition = false;
        _isChoosingEventCondition = false;
        _conditionError =
            'Les conditions ne sont pas éditables pour cet événement.';
        _conditionFeedback = null;
      });
      return;
    }
    _startFactConditionChoice();
  }

  void _startEventConditionChoiceFromLibrary(
    EventBuilderEventSummary selected,
  ) {
    if (selected.conditionEditingLocked ||
        widget.onAddEventConsumedCondition == null) {
      setState(() {
        _isChoosingFactCondition = false;
        _isChoosingEventCondition = false;
        _conditionError =
            'Les conditions ne sont pas éditables pour cet événement.';
        _conditionFeedback = null;
      });
      return;
    }
    _startEventConditionChoice();
  }

  void _startSceneChoiceFromLibrary() {
    if (widget.onUpdateSceneAction == null) {
      setState(() {
        _sceneError = 'L’action principale n’est pas modifiable dans ce lot.';
        _sceneFeedback = null;
      });
      return;
    }
    _startSceneChoice();
  }

  void _addFactCondition(
    EventBuilderEventSummary selected,
    EventBuilderFactOption option, {
    required bool expectedValue,
  }) {
    final added = widget.onAddFactCondition?.call(
          eventId: selected.eventId,
          factId: option.id,
          expectedValue: expectedValue,
        ) ??
        false;
    if (!added) {
      setState(() {
        _conditionError = 'Impossible d’ajouter cette condition.';
        _conditionFeedback = null;
      });
      return;
    }
    setState(() {
      _isChoosingFactCondition = false;
      _conditionError = null;
      _conditionFeedback = 'Condition ajoutée.';
    });
  }

  void _addEventConsumedCondition(
    EventBuilderEventSummary selected,
    EventBuilderConditionEventOption option, {
    required bool expectedConsumed,
  }) {
    final added = widget.onAddEventConsumedCondition?.call(
          eventId: selected.eventId,
          targetEventId: option.id,
          expectedConsumed: expectedConsumed,
        ) ??
        false;
    if (!added) {
      setState(() {
        _conditionError = 'Impossible d’ajouter cette condition.';
        _conditionFeedback = null;
      });
      return;
    }
    setState(() {
      _isChoosingEventCondition = false;
      _conditionError = null;
      _conditionFeedback = 'Condition ajoutée.';
    });
  }

  void _removeCondition(
    EventBuilderEventSummary selected,
    int conditionIndex,
  ) {
    final removed = widget.onRemoveCondition?.call(
          eventId: selected.eventId,
          conditionIndex: conditionIndex,
        ) ??
        false;
    if (!removed) {
      setState(() {
        _conditionError = 'Impossible de retirer cette condition.';
        _conditionFeedback = null;
      });
      return;
    }
    setState(() {
      _conditionError = null;
      _conditionFeedback = 'Condition retirée.';
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

  void _selectReusePolicy(
    EventBuilderEventSummary selected,
    EventBuilderReusePolicy reusePolicy,
  ) {
    final updated = widget.onUpdateReusePolicy?.call(
          eventId: selected.eventId,
          reusePolicy: reusePolicy,
        ) ??
        false;
    if (!updated) {
      setState(() {
        _behaviorError = 'Impossible de modifier ce comportement.';
        _behaviorFeedback = null;
      });
      return;
    }
    setState(() {
      _behaviorError = null;
      _behaviorFeedback = 'Comportement mis à jour.';
    });
  }
}

class _TriggerTypeButton extends StatelessWidget {
  const _TriggerTypeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.type,
    required this.currentType,
    required this.onSelect,
  });

  final String label;
  final IconData icon;
  final MapEventType type;
  final MapEventType currentType;
  final ValueChanged<MapEventType> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentType == type;
    return PokeMapButton(
      onPressed: isSelected ? null : () => onSelect(type),
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      isSelected: isSelected,
      leading: Icon(icon),
      child: Text(label),
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

class _EmptyConditionSlot extends StatelessWidget {
  const _EmptyConditionSlot();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PokeMapCard(
        key: const ValueKey('event-builder-empty-condition-slot'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        borderRadius: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucune condition',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez une condition depuis la bibliothèque ou les boutons ci-dessous.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneActionSlot extends StatelessWidget {
  const _SceneActionSlot({
    required this.sceneAction,
  });

  final EventBuilderSceneActionReadModel sceneAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final value =
        sceneAction.isMissing ? 'Aucune scène choisie' : sceneAction.sceneLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PokeMapCard(
        key: const ValueKey('event-builder-scene-action-slot'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        borderRadius: 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.play_rectangle,
              size: 16,
              color: colors.info,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 116,
              child: Text(
                'Jouer une scène',
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
                  color: sceneAction.isMissing
                      ? colors.textMuted
                      : colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
  const _ConditionDetailLine({
    super.key,
    required this.condition,
    this.onRemove,
    this.removeKey,
  });

  final EventBuilderConditionReadModel condition;
  final VoidCallback? onRemove;
  final Key? removeKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final category = _conditionCategoryLabel(condition.kind);
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
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      condition.isEditable ? colors.textMuted : colors.warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                condition.isSupported
                    ? condition.label
                    : '${condition.label}\nLecture seule dans ce lot',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              PokeMapButton(
                key: removeKey,
                onPressed: onRemove,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.trash),
                child: const Text('Retirer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _conditionCategoryLabel(EventBuilderConditionKind kind) {
  return switch (kind) {
    EventBuilderConditionKind.factIsTrue ||
    EventBuilderConditionKind.factIsFalse =>
      'Fact',
    EventBuilderConditionKind.eventConsumed ||
    EventBuilderConditionKind.eventNotConsumed =>
      'Événement',
    EventBuilderConditionKind.storyStepCompleted ||
    EventBuilderConditionKind.storyStepNotCompleted =>
      'Étape',
  };
}

class _FactConditionOptionRow extends StatelessWidget {
  const _FactConditionOptionRow({
    required this.option,
    required this.onTrue,
    required this.onFalse,
  });

  final EventBuilderFactOption option;
  final VoidCallback onTrue;
  final VoidCallback onFalse;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapButton(
                key: ValueKey('event-builder-fact-true-${option.id}'),
                onPressed: onTrue,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.checkmark_circle),
                child: const Text('Doit être vrai'),
              ),
              PokeMapButton(
                key: ValueKey('event-builder-fact-false-${option.id}'),
                onPressed: onFalse,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.xmark_circle),
                child: const Text('Doit être faux'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventConditionOptionRow extends StatelessWidget {
  const _EventConditionOptionRow({
    required this.option,
    required this.onConsumed,
    required this.onNotConsumed,
  });

  final EventBuilderConditionEventOption option;
  final VoidCallback onConsumed;
  final VoidCallback onNotConsumed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapButton(
                key: ValueKey('event-builder-event-consumed-${option.id}'),
                onPressed: onConsumed,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.checkmark_circle),
                child: const Text('Déjà consommé'),
              ),
              PokeMapButton(
                key: ValueKey('event-builder-event-not-consumed-${option.id}'),
                onPressed: onNotConsumed,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.xmark_circle),
                child: const Text('Pas encore consommé'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isEditableConditionKind(EventBuilderConditionKind kind) {
  return switch (kind) {
    EventBuilderConditionKind.factIsTrue ||
    EventBuilderConditionKind.factIsFalse ||
    EventBuilderConditionKind.eventConsumed ||
    EventBuilderConditionKind.eventNotConsumed =>
      true,
    EventBuilderConditionKind.storyStepCompleted ||
    EventBuilderConditionKind.storyStepNotCompleted =>
      false,
  };
}

MapEventType? _triggerTypeForLabel(String label) {
  return switch (label) {
    'Interaction avec un PNJ' => MapEventType.actor,
    'Interaction avec un objet' => MapEventType.object,
    'Entrée dans une zone' => MapEventType.triggerZone,
    _ => null,
  };
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
