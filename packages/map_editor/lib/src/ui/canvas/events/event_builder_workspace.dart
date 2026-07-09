import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../map_canvas.dart';
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

typedef EventBuilderEventSelectCallback = void Function(String eventId);
typedef EventBuilderDestinationLayerCreateCallback = void Function();

// NS-EVENT-40 keeps the visual reference tuning local to Event Builder. The
// numbers below intentionally describe the four-column shell without changing
// Narrative Studio's global chrome or any event-authoring contract.
const _eventBuilderShellPadding = 12.0;
const _eventBuilderColumnGap = 10.0;
const _eventBuilderListColumnWidth = 264.0;
const _eventBuilderLibraryColumnWidth = 244.0;
const _eventBuilderGuidedLibraryColumnWidth = 216.0;
const _eventBuilderInspectorColumnWidth = 340.0;
const _eventBuilderGuidedInspectorColumnWidth = 306.0;

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

class EventBuilderDestinationLayerOption {
  const EventBuilderDestinationLayerOption({
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
    this.selectedEventId,
    this.draftCreationGate = const EventBuilderDraftCreationGate.disabled(),
    this.sceneOptions = const <EventBuilderSceneOption>[],
    this.factOptions = const <EventBuilderFactOption>[],
    this.eventConditionOptions = const <EventBuilderConditionEventOption>[],
    this.mapOptions = const <EventBuilderMapOption>[],
    this.onOpenMap,
    this.onSelectEvent,
    this.onRenameEventTitle,
    this.onUpdateTriggerType,
    this.onUpdateSceneAction,
    this.onUpdateReusePolicy,
    this.onAddFactCondition,
    this.onAddEventConsumedCondition,
    this.onRemoveCondition,
    this.onCreateDestinationLayer,
  });

  final EventBuilderReadModel readModel;
  final String? selectedEventId;
  final EventBuilderDraftCreationGate draftCreationGate;
  final List<EventBuilderSceneOption> sceneOptions;
  final List<EventBuilderFactOption> factOptions;
  final List<EventBuilderConditionEventOption> eventConditionOptions;
  final List<EventBuilderMapOption> mapOptions;
  final EventBuilderMapOpenCallback? onOpenMap;
  final EventBuilderEventSelectCallback? onSelectEvent;
  final EventBuilderTitleRenameCallback? onRenameEventTitle;
  final EventBuilderTriggerTypeUpdateCallback? onUpdateTriggerType;
  final EventBuilderSceneActionUpdateCallback? onUpdateSceneAction;
  final EventBuilderReusePolicyUpdateCallback? onUpdateReusePolicy;
  final EventBuilderFactConditionAddCallback? onAddFactCondition;
  final EventBuilderEventConsumedConditionAddCallback?
      onAddEventConsumedCondition;
  final EventBuilderConditionRemoveCallback? onRemoveCondition;
  final EventBuilderDestinationLayerCreateCallback? onCreateDestinationLayer;

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
        destinationLayerOptions = const <EventBuilderDestinationLayerOption>[],
        autoResolvedLayer = false,
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
        destinationLayerOptions = const <EventBuilderDestinationLayerOption>[],
        autoResolvedLayer = false,
        layerValid = false;

  const EventBuilderDraftCreationGate.positionPicker({
    required this.mapId,
    required this.mapWidth,
    required this.mapHeight,
    required this.layerId,
    required this.layerLabel,
    required this.layerValid,
    required this.onCreateDraftAt,
    this.destinationLayerOptions = const <EventBuilderDestinationLayerOption>[],
    this.autoResolvedLayer = false,
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
  final List<EventBuilderDestinationLayerOption> destinationLayerOptions;
  final bool autoResolvedLayer;
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
  String? _selectedDraftLayerId;
  GridPos? _selectedDraftPosition;
  String? _draftCreationFeedback;
  PokeMapTone _draftCreationFeedbackTone = PokeMapTone.success;
  bool _isCreationPanelExpanded = false;
  bool _isMapPlacementActive = false;
  final _eventDetailsKey = GlobalKey<_EventDetailsPanelState>();

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(EventBuilderWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readModel != widget.readModel ||
        oldWidget.selectedEventId != widget.selectedEventId) {
      _syncSelection();
    }
    if (_positionPickerContextChanged(
      oldWidget.draftCreationGate,
      widget.draftCreationGate,
    )) {
      _selectedDraftLayerId = null;
      _selectedDraftPosition = null;
      _draftCreationFeedback = null;
      _draftCreationFeedbackTone = PokeMapTone.success;
      _isMapPlacementActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEvent();
    final activeCount = widget.readModel.events
        .where((event) => event.status == EventBuilderEventStatus.active)
        .length;
    final draftCount = widget.readModel.events
        .where((event) => event.status == EventBuilderEventStatus.draft)
        .length;
    final showGuidedPostCreation = selected != null &&
        _draftCreationFeedback != null &&
        _draftCreationFeedbackTone == PokeMapTone.success;
    final createDraftAction = _createDraftAction;
    final creationControls = _creationControlWidgets(createDraftAction);
    final showCreationShortcut = widget.readModel.events.isNotEmpty &&
        !_isCreationPanelExpanded &&
        creationControls.isNotEmpty;
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-workspace'),
      padding: const EdgeInsets.all(_eventBuilderShellPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EventBuilderShellHeader(
            totalCount: widget.readModel.events.length,
            activeCount: activeCount,
            draftCount: draftCount,
            diagnosticCount: widget.readModel.diagnostics.length,
            mapTitle: widget.readModel.mapTitle ?? 'Aucune map',
            showCreationShortcut: showCreationShortcut,
            onCreateShortcut: _openCreationPanelAction,
          ),
          const SizedBox(height: 12),
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
                      const SizedBox(width: _eventBuilderColumnGap),
                      Expanded(
                        child: _EventBuilderEmptyState(
                          hasActiveMap: widget.readModel.mapId != null,
                        ),
                      ),
                    ],
                  )
                : KeyedSubtree(
                    key: const ValueKey('event-builder-reference-body'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          key: const ValueKey(
                            'event-builder-reference-list-column',
                          ),
                          width: _eventBuilderListColumnWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: _isCreationPanelExpanded ? 1 : 3,
                                child: _EventListPanel(
                                  events: widget.readModel.events,
                                  selectedEventId: selected?.eventId,
                                  onSelect: (eventId) {
                                    widget.onSelectEvent?.call(eventId);
                                    setState(() {
                                      _selectedEventId = eventId;
                                      _draftCreationFeedback = null;
                                      _isMapPlacementActive = false;
                                    });
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
                        const SizedBox(width: _eventBuilderColumnGap),
                        SizedBox(
                          key: const ValueKey(
                            'event-builder-reference-library-column',
                          ),
                          width: showGuidedPostCreation
                              ? _eventBuilderGuidedLibraryColumnWidth
                              : _eventBuilderLibraryColumnWidth,
                          child: showGuidedPostCreation
                              ? _CollapsedElementLibraryPanel(
                                  onActivate: _activateLibraryAction,
                                )
                              : EventBuilderElementLibrary(
                                  onActivate: _activateLibraryAction,
                                ),
                        ),
                        const SizedBox(width: _eventBuilderColumnGap),
                        Expanded(
                          key: const ValueKey(
                            'event-builder-reference-flow-column',
                          ),
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
                            showGuidedSetup: showGuidedPostCreation,
                          ),
                        ),
                        const SizedBox(width: _eventBuilderColumnGap),
                        SizedBox(
                          key: const ValueKey(
                            'event-builder-reference-inspector-column',
                          ),
                          width: showGuidedPostCreation
                              ? _eventBuilderGuidedInspectorColumnWidth
                              : _eventBuilderInspectorColumnWidth,
                          child: _inspectorPanelFor(
                            selected,
                            showGuidedPostCreation,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _activateLibraryAction(EventBuilderLibraryAction action) {
    _eventDetailsKey.currentState?.activateLibraryAction(action);
  }

  Widget _inspectorPanelFor(
    EventBuilderEventSummary? selected,
    bool showGuidedPostCreation,
  ) {
    if (selected == null) {
      return const PokeMapPanel(
        expandChild: true,
        child: PokeMapEmptyState(
          icon: Icon(CupertinoIcons.sidebar_right),
          title: 'Sélectionnez un événement',
        ),
      );
    }
    final inspector = EventBuilderInspectorPanel(event: selected);
    if (!showGuidedPostCreation) {
      return inspector;
    }
    // NS-EVENT-38 asserted that a freshly created event exposes a secondary
    // summary. NS-EVENT-39 keeps that contract while using the richer inspector.
    return KeyedSubtree(
      key: const ValueKey('event-builder-inspector-summary-panel'),
      child: inspector,
    );
  }

  VoidCallback? get _openCreationPanelAction {
    if (_requiresMapActivation || _isCreationPanelExpanded) {
      return null;
    }
    if (!widget.draftCreationGate.hasPositionPicker &&
        !widget.draftCreationGate.canCreate) {
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
    final externalSelection = widget.selectedEventId?.trim();
    if (externalSelection != null &&
        externalSelection.isNotEmpty &&
        events.any((event) => event.eventId == externalSelection)) {
      _selectedEventId = externalSelection;
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

  EventBuilderDestinationLayerOption? _effectiveDestinationLayer() {
    final selectedLayerId = _selectedDraftLayerId?.trim();
    if (selectedLayerId != null && selectedLayerId.isNotEmpty) {
      for (final option in widget.draftCreationGate.destinationLayerOptions) {
        if (option.id == selectedLayerId) {
          return option;
        }
      }
    }
    if (widget.draftCreationGate.layerValid) {
      final id = widget.draftCreationGate.layerId?.trim();
      if (id != null && id.isNotEmpty) {
        return EventBuilderDestinationLayerOption(
          id: id,
          label: widget.draftCreationGate.layerLabel?.trim().isNotEmpty == true
              ? widget.draftCreationGate.layerLabel!.trim()
              : id,
        );
      }
    }
    return null;
  }

  List<Widget> _creationControlWidgets(VoidCallback? createDraftAction) {
    final controls = <Widget>[];
    void append(Widget control) {
      if (controls.isNotEmpty) {
        controls.add(const SizedBox(height: 12));
      }
      controls.add(control);
    }

    final destinationLayer = _effectiveDestinationLayer();

    if (widget.draftCreationGate.hasPositionPicker) {
      append(
        _DraftDestinationLayerPanel(
          gate: widget.draftCreationGate,
          selectedLayer: destinationLayer,
          selectedLayerId: _selectedDraftLayerId,
          onCreateLayer: widget.onCreateDestinationLayer,
          onSelectLayer: (layerId) {
            setState(() {
              _selectedDraftLayerId = layerId;
              _selectedDraftPosition = null;
              _draftCreationFeedback = null;
              _draftCreationFeedbackTone = PokeMapTone.success;
            });
          },
        ),
      );
    }

    if (widget.draftCreationGate.hasPositionPicker) {
      append(
        _DraftPositionPickerPanel(
          gate: widget.draftCreationGate,
          selectedPosition: _selectedDraftPosition,
          canChooseOnMap: destinationLayer != null,
          isMapPlacementActive: _isMapPlacementActive,
          onSelect: (position) {
            setState(() {
              _selectedDraftPosition = position;
              _isMapPlacementActive = false;
              _draftCreationFeedback = null;
              _draftCreationFeedbackTone = PokeMapTone.success;
            });
          },
          onStartMapPlacement: destinationLayer == null
              ? null
              : () {
                  setState(() {
                    _isMapPlacementActive = true;
                    _draftCreationFeedback = null;
                    _draftCreationFeedbackTone = PokeMapTone.success;
                  });
                },
          onCancelMapPlacement: !_isMapPlacementActive
              ? null
              : () {
                  setState(() => _isMapPlacementActive = false);
                },
          onClear: _selectedDraftPosition == null
              ? null
              : () {
                  setState(() {
                    _selectedDraftPosition = null;
                    _isMapPlacementActive = false;
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
    append(
      _DraftCreationActionPanel(
        onCreate: createDraftAction,
        disabledReason: _creationDisabledReason,
      ),
    );
    if (_draftCreationFeedback != null) {
      append(
        _DraftCreationFeedbackNotice(
          message: _draftCreationFeedback!,
          tone: _draftCreationFeedbackTone,
        ),
      );
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
    final destinationLayer = _effectiveDestinationLayer();
    final layerId = destinationLayer?.id.trim();
    final create = gate.onCreateDraftAt;
    if (!gate.hasPositionPicker ||
        position == null ||
        layerId == null ||
        layerId.isEmpty ||
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
          _isMapPlacementActive = false;
          _isCreationPanelExpanded = false;
          _draftCreationFeedback =
              'Événement créé. Il est sélectionné dans la liste. Choisissez '
              'une autre case pour en créer un nouveau.';
          _draftCreationFeedbackTone = PokeMapTone.success;
        });
        return;
      }
      setState(() {
        _draftCreationFeedback =
            'Impossible de créer l’événement. Vérifiez la destination et la '
            'position, puis réessayez.';
        _draftCreationFeedbackTone = PokeMapTone.warning;
      });
    };
  }

  String get _creationDisabledReason {
    final gate = widget.draftCreationGate;
    if (_requiresMapActivation) {
      return 'Ouvrez une map active pour choisir où placer l’événement.';
    }
    if (gate.hasPositionPicker && _effectiveDestinationLayer() == null) {
      if (gate.destinationLayerOptions.isEmpty) {
        return 'Créez la couche Événements pour choisir une position.';
      }
      return 'Choisissez une destination avant de placer l’événement.';
    }
    if (gate.hasPositionPicker && _selectedDraftPosition == null) {
      return 'Choisissez une position sur la carte pour activer la création.';
    }
    return gate.disabledReason ??
        'Choisissez une position avant de créer l’événement.';
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
        previous.layerId != next.layerId ||
        !_sameLayerOptions(
          previous.destinationLayerOptions,
          next.destinationLayerOptions,
        );
  }

  bool _sameLayerOptions(
    List<EventBuilderDestinationLayerOption> previous,
    List<EventBuilderDestinationLayerOption> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (var i = 0; i < previous.length; i++) {
      if (previous[i].id != next[i].id || previous[i].label != next[i].label) {
        return false;
      }
    }
    return true;
  }
}

class _EventBuilderShellHeader extends StatelessWidget {
  const _EventBuilderShellHeader({
    required this.totalCount,
    required this.activeCount,
    required this.draftCount,
    required this.diagnosticCount,
    required this.mapTitle,
    required this.showCreationShortcut,
    required this.onCreateShortcut,
  });

  final int totalCount;
  final int activeCount;
  final int draftCount;
  final int diagnosticCount;
  final String mapTitle;
  final bool showCreationShortcut;
  final VoidCallback? onCreateShortcut;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final titleCluster = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PokeMapIconTile(
          icon: CupertinoIcons.bolt_horizontal_circle,
          tone: PokeMapTone.quest,
          size: 40,
          iconSize: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Événements',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Déclenchez des scènes depuis la carte, ajoutez des '
                'conditions, puis suivez les conséquences.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final metrics = Wrap(
      key: const ValueKey('event-builder-polished-metrics-row'),
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PokeMapStatusTile(
          label: 'Total',
          value: '$totalCount',
          icon: CupertinoIcons.list_bullet,
          tone: PokeMapTone.quest,
        ),
        PokeMapStatusTile(
          label: 'Actifs',
          value: '$activeCount',
          icon: CupertinoIcons.checkmark_circle,
          tone: activeCount == 0 ? PokeMapTone.neutral : PokeMapTone.success,
        ),
        PokeMapStatusTile(
          label: 'Brouillons',
          value: '$draftCount',
          icon: CupertinoIcons.pencil_ellipsis_rectangle,
          tone: draftCount == 0 ? PokeMapTone.neutral : PokeMapTone.warning,
        ),
        PokeMapStatusTile(
          label: 'Diagnostics',
          value: '$diagnosticCount',
          icon: CupertinoIcons.exclamationmark_triangle,
          tone:
              diagnosticCount == 0 ? PokeMapTone.success : PokeMapTone.warning,
        ),
        PokeMapStatusTile(
          label: 'Portée',
          value: mapTitle,
          icon: CupertinoIcons.map,
          tone: PokeMapTone.map,
        ),
      ],
    );
    final createButton = showCreationShortcut
        ? PokeMapButton(
            key: const ValueKey('event-builder-new-event-button'),
            onPressed: onCreateShortcut,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.medium,
            leading: const Icon(CupertinoIcons.plus),
            child: const Text('Préparer un événement'),
          )
        : null;

    return KeyedSubtree(
      key: const ValueKey('event-builder-polished-shell-header'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1180;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleCluster),
                    if (createButton != null) ...[
                      const SizedBox(width: 10),
                      createButton,
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: metrics,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: titleCluster),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.topRight,
                  child: metrics,
                ),
              ),
              if (createButton != null) ...[
                const SizedBox(width: 10),
                createButton,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EventBuilderEmptyState extends StatelessWidget {
  const _EventBuilderEmptyState({
    required this.hasActiveMap,
  });

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
              ? 'Cliquez sur “Choisir sur la carte”, puis cliquez sur la '
                  'carte pour placer votre premier événement.'
              : 'Choisissez une map du projet avant de placer un événement.',
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

class _DraftDestinationLayerPanel extends StatelessWidget {
  const _DraftDestinationLayerPanel({
    required this.gate,
    required this.selectedLayer,
    required this.selectedLayerId,
    required this.onCreateLayer,
    required this.onSelectLayer,
  });

  final EventBuilderDraftCreationGate gate;
  final EventBuilderDestinationLayerOption? selectedLayer;
  final String? selectedLayerId;
  final VoidCallback? onCreateLayer;
  final ValueChanged<String> onSelectLayer;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final options = gate.destinationLayerOptions;
    final selected = selectedLayer;
    final hasOptions = options.isNotEmpty;
    return _GuidedCreationStep(
      key: const ValueKey('event-builder-destination-layer-panel'),
      number: 1,
      title: 'Destination',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selected == null
                ? hasOptions
                    ? 'Couche utilisée : à choisir'
                    : 'Aucune couche d’événements sur cette map.'
                : 'Couche utilisée : ${selected.label}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _destinationMessage(hasOptions, selected),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (options.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  PokeMapButton(
                    key: ValueKey('event-builder-layer-option-${option.id}'),
                    onPressed: () => onSelectLayer(option.id),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: selectedLayerId == option.id,
                    leading: const Icon(CupertinoIcons.layers_alt),
                    child: Text(option.label),
                  ),
              ],
            ),
          ],
          if (!hasOptions && onCreateLayer != null) ...[
            const SizedBox(height: 12),
            PokeMapButton(
              key: const ValueKey(
                'event-builder-create-destination-layer',
              ),
              onPressed: onCreateLayer,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.plus_square_on_square),
              child: const Text('Créer la couche Événements'),
            ),
          ],
        ],
      ),
    );
  }

  String _destinationMessage(
    bool hasOptions,
    EventBuilderDestinationLayerOption? selected,
  ) {
    if (!hasOptions) {
      return 'Créez-la ici pour placer vos événements.';
    }
    if (gate.autoResolvedLayer && selected != null) {
      return 'Destination choisie automatiquement.';
    }
    if (selected != null) {
      return 'Les événements créés seront placés ici.';
    }
    return 'Choisissez où placer cet événement.';
  }
}

class _DraftPositionPickerPanel extends StatelessWidget {
  const _DraftPositionPickerPanel({
    required this.gate,
    required this.selectedPosition,
    required this.canChooseOnMap,
    required this.isMapPlacementActive,
    required this.onSelect,
    required this.onStartMapPlacement,
    required this.onCancelMapPlacement,
    required this.onClear,
  });

  final EventBuilderDraftCreationGate gate;
  final GridPos? selectedPosition;
  final bool canChooseOnMap;
  final bool isMapPlacementActive;
  final ValueChanged<GridPos> onSelect;
  final VoidCallback? onStartMapPlacement;
  final VoidCallback? onCancelMapPlacement;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selected = selectedPosition;
    final positionLabel = selected == null
        ? 'Aucune position choisie'
        : 'Position choisie : x ${selected.x}, y ${selected.y}';
    return _GuidedCreationStep(
      number: 2,
      title: 'Position',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cliquez sur “Choisir sur la carte”, puis cliquez dans la carte '
            'pour placer l’événement.',
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
              if (selected != null) ...[
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
            ],
          ),
          const SizedBox(height: 10),
          PokeMapButton(
            key: const ValueKey('event-builder-choose-on-map-button'),
            onPressed: onStartMapPlacement,
            variant: isMapPlacementActive
                ? PokeMapButtonVariant.success
                : PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.medium,
            leading: const Icon(CupertinoIcons.map),
            child: const Text('Choisir sur la carte'),
          ),
          if (!canChooseOnMap) ...[
            const SizedBox(height: 8),
            Text(
              'Préparez la destination avant de choisir la position.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
          if (isMapPlacementActive) ...[
            const SizedBox(height: 10),
            PokeMapCard(
              borderRadius: 8,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const PokeMapBadge(
                        label: 'Mode placement actif',
                        variant: PokeMapBadgeVariant.success,
                        icon: Icon(CupertinoIcons.cursor_rays),
                      ),
                      PokeMapButton(
                        onPressed: onCancelMapPlacement,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.xmark),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquez sur la carte pour choisir l’emplacement.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: MapCanvas(
                        key: const ValueKey(
                          'event-builder-map-placement-canvas',
                        ),
                        onEventBuilderPositionChosen: onSelect,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (selected != null) ...[
            const SizedBox(height: 8),
            Text(
              'La carte a enregistré cette position.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ] else if (gate.mapWidth != null && gate.mapHeight != null) ...[
            const SizedBox(height: 8),
            Text(
              'Carte active : ${gate.mapWidth} x ${gate.mapHeight} cases.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftCreationActionPanel extends StatelessWidget {
  const _DraftCreationActionPanel({
    required this.onCreate,
    required this.disabledReason,
  });

  final VoidCallback? onCreate;
  final String disabledReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isReady = onCreate != null;
    return _GuidedCreationStep(
      number: 3,
      title: 'Création',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isReady ? 'Destination et position choisies.' : disabledReason,
            style: TextStyle(
              color: isReady ? colors.textSecondary : colors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          PokeMapButton(
            key: const ValueKey('event-builder-create-event-button'),
            onPressed: onCreate,
            variant: PokeMapButtonVariant.primary,
            size: PokeMapButtonSize.medium,
            leading: const Icon(CupertinoIcons.checkmark_circle),
            child: const Text('Créer l’événement'),
          ),
        ],
      ),
    );
  }
}

class _GuidedCreationStep extends StatelessWidget {
  const _GuidedCreationStep({
    super.key,
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$number. $title',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
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

class _EventListPanel extends StatefulWidget {
  const _EventListPanel({
    required this.events,
    required this.selectedEventId,
    required this.onSelect,
  });

  final List<EventBuilderEventSummary> events;
  final String? selectedEventId;
  final ValueChanged<String> onSelect;

  @override
  State<_EventListPanel> createState() => _EventListPanelState();
}

class _EventListPanelState extends State<_EventListPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final query = _searchController.text.trim().toLowerCase();
    final filteredEvents = widget.events.where((event) {
      if (query.isEmpty) {
        return true;
      }
      return event.displayName.toLowerCase().contains(query) ||
          event.technicalId.toLowerCase().contains(query) ||
          event.statusLabel.toLowerCase().contains(query);
    }).toList(growable: false);
    final groupedEvents = <String, List<EventBuilderEventSummary>>{};
    for (final event in filteredEvents) {
      groupedEvents.putIfAbsent(event.groupKey, () => []).add(event);
    }
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
          const SizedBox(height: 10),
          CupertinoTextField(
            key: const ValueKey('event-builder-event-search-field'),
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                CupertinoIcons.search,
                size: 15,
                color: colors.textMuted,
              ),
            ),
            placeholder: 'Rechercher un événement...',
            placeholderStyle: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: colors.controlSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              key: const ValueKey('event-builder-event-list'),
              children: [
                if (filteredEvents.isEmpty)
                  const _EventListEmptyResult()
                else
                  for (final group in groupedEvents.entries) ...[
                    _EventListGroupHeader(
                      label: group.key,
                      count: group.value.length,
                    ),
                    const SizedBox(height: 8),
                    for (final event in group.value) ...[
                      _EventListCard(
                        event: event,
                        selected: event.eventId == widget.selectedEventId,
                        onTap: () => widget.onSelect(event.eventId),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventListGroupHeader extends StatelessWidget {
  const _EventListGroupHeader({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        PokeMapBadge(
          label: '$count',
          variant: PokeMapBadgeVariant.neutral,
        ),
      ],
    );
  }
}

class _EventListEmptyResult extends StatelessWidget {
  const _EventListEmptyResult();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 8,
      child: Text(
        'Aucun événement ne correspond à cette recherche.',
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
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

class _CollapsedElementLibraryPanel extends StatelessWidget {
  const _CollapsedElementLibraryPanel({
    required this.onActivate,
  });

  final ValueChanged<EventBuilderLibraryAction> onActivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('event-builder-element-library-collapsed'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions rapides',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'La bibliothèque complète reste secondaire pendant la première '
              'configuration.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            _QuickLibraryActionButton(
              key: const ValueKey('event-builder-library-item-trigger-zone'),
              label: 'Choisir le déclencheur',
              icon: CupertinoIcons.square_grid_2x2,
              onPressed: () =>
                  onActivate(EventBuilderLibraryAction.triggerZone),
            ),
            const SizedBox(height: 8),
            _QuickLibraryActionButton(
              key: const ValueKey('event-builder-library-item-action-scene'),
              label: 'Choisir une scène',
              icon: CupertinoIcons.play_rectangle,
              onPressed: () =>
                  onActivate(EventBuilderLibraryAction.actionScene),
            ),
            const SizedBox(height: 8),
            _QuickLibraryActionButton(
              key: const ValueKey('event-builder-library-item-condition-fact'),
              label: 'Ajouter une condition',
              icon: CupertinoIcons.checkmark_shield,
              onPressed: () =>
                  onActivate(EventBuilderLibraryAction.conditionFact),
            ),
            const SizedBox(height: 8),
            _QuickLibraryActionButton(
              key: const ValueKey(
                'event-builder-library-item-condition-event-consumed',
              ),
              label: 'Condition événement',
              icon: CupertinoIcons.flag,
              onPressed: () => onActivate(
                EventBuilderLibraryAction.conditionEventConsumed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLibraryActionButton extends StatelessWidget {
  const _QuickLibraryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PokeMapButton(
      onPressed: onPressed,
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      leading: Icon(icon),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
    );
  }
}

class _GuidedSetupPanel extends StatelessWidget {
  const _GuidedSetupPanel({
    required this.event,
  });

  final EventBuilderEventSummary event;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('event-builder-guided-setup-panel'),
      borderRadius: 8,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.checkmark_seal,
                tone: PokeMapTone.success,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurer l’événement',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Événement créé. Complétez les étapes principales.',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const PokeMapBadge(
            label: 'À faire',
            variant: PokeMapBadgeVariant.warning,
            icon: Icon(CupertinoIcons.list_bullet),
          ),
          const SizedBox(height: 10),
          _GuidedSetupStep(
            complete: true,
            label: 'Position choisie',
            detail: 'x ${event.position.x}, y ${event.position.y}',
          ),
          _GuidedSetupStep(
            complete: event.displayName.trim() != 'Nouvel événement',
            label: 'Renommer l’événement',
            detail: event.displayName,
          ),
          _GuidedSetupStep(
            complete: event.trigger.label.trim().isNotEmpty,
            label: 'Choisir le déclencheur',
            detail: event.trigger.label,
          ),
          _GuidedSetupStep(
            complete: !event.sceneAction.isMissing,
            label: 'Choisir une scène',
            detail: event.sceneAction.label,
          ),
          _GuidedSetupStep(
            complete: event.behavior.label.trim().isNotEmpty,
            label: 'Vérifier le comportement',
            detail: event.behavior.label,
          ),
        ],
      ),
    );
  }
}

class _GuidedSetupStep extends StatelessWidget {
  const _GuidedSetupStep({
    required this.complete,
    required this.label,
    required this.detail,
  });

  final bool complete;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            complete
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: complete ? colors.success : colors.textMuted,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
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
    required this.showGuidedSetup,
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
  final bool showGuidedSetup;

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
      title: 'Éditeur d’événement',
      subtitle: widget.showGuidedSetup
          ? 'Complétez le nom, le déclencheur, la scène et le comportement.'
          : 'Suivez le flux Déclencheur, Conditions, Action, Projections.',
      eventHeader: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showGuidedSetup) ...[
            _GuidedSetupPanel(event: selected),
            const SizedBox(height: 10),
          ],
          PokeMapCard(
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
        ],
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
            _FlowSubsection(
              title: 'Comportement',
              icon: CupertinoIcons.repeat,
              tone: PokeMapTone.warning,
              child: _buildBehaviorBlock(context, selected),
            ),
          ],
        ),
        EventBuilderFlowBlock(
          key: const ValueKey('event-builder-flow-block-consequences'),
          phaseLabel: 'Puis',
          title: 'Conséquences projetées',
          icon: CupertinoIcons.scope,
          tone: PokeMapTone.warning,
          summary: selected.worldImpacts.isEmpty
              ? 'Aucune source projetée'
              : _sourceCountLabel(selected.worldImpacts.length),
          diagnosticCount: (sections['behavior']?.diagnosticCount ?? 0) +
              (sections['world']?.diagnosticCount ?? 0),
          hasBlockingDiagnostic:
              (sections['behavior']?.hasBlockingDiagnostic ?? false) ||
                  (sections['world']?.hasBlockingDiagnostic ?? false),
          children: [
            _ProjectedConsequencesBlock(
              sceneOutcomes: selected.sceneOutcomes,
              impacts: selected.worldImpacts,
              worldRules: selected.worldRules,
              stacked: widget.showGuidedSetup,
            ),
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
    return centralFlow;
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
        _LifecycleProjectionNotice(lifecycle: selected.lifecycle),
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

class _FlowSubsection extends StatelessWidget {
  const _FlowSubsection({
    required this.title,
    required this.icon,
    required this.tone,
    required this.child,
  });

  final String title;
  final IconData icon;
  final PokeMapTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PokeMapCard(
        padding: const EdgeInsets.all(10),
        borderRadius: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: toneColors.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
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

class _SceneOutcomesProjectionSlot extends StatelessWidget {
  const _SceneOutcomesProjectionSlot({
    required this.projection,
  });

  final EventBuilderSceneOutcomesProjection projection;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PokeMapCard(
        key: const ValueKey('event-builder-scene-outcomes-projection'),
        padding: const EdgeInsets.all(10),
        borderRadius: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.flag_circle,
                  size: 16,
                  color: colors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Issues de la scène liée',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Les résultats appartiennent à la Scene liée.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: PokeMapBadge(
                label: 'Lecture seule',
                variant: PokeMapBadgeVariant.neutral,
              ),
            ),
            const SizedBox(height: 9),
            _buildProjectionBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionBody(BuildContext context) {
    return switch (projection.status) {
      EventBuilderSceneOutcomesProjectionStatus.hasDeclaredOutcomes =>
        _SceneOutcomeRows(projection: projection),
      EventBuilderSceneOutcomesProjectionStatus.noSceneTarget =>
        const _DiagnosticNotice(
          title: 'Aucune scène liée',
          message: 'Choisissez une scène pour voir ses résultats possibles.',
          tone: PokeMapTone.info,
          severityLabel: 'À compléter',
        ),
      EventBuilderSceneOutcomesProjectionStatus.missingScene =>
        const _DiagnosticNotice(
          title: 'Scène introuvable',
          message: 'La scène liée n’existe pas dans le projet.',
          tone: PokeMapTone.warning,
          severityLabel: 'À corriger',
        ),
      EventBuilderSceneOutcomesProjectionStatus.noDeclaredOutcomes =>
        const _DiagnosticNotice(
          title: 'Aucun résultat déclaré',
          message: 'Cette scène ne déclare pas encore de résultat.',
          tone: PokeMapTone.info,
          severityLabel: 'Lecture seule',
        ),
    };
  }
}

class _SceneOutcomeRows extends StatelessWidget {
  const _SceneOutcomeRows({
    required this.projection,
  });

  final EventBuilderSceneOutcomesProjection projection;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          projection.label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        for (final outcome in projection.outcomes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: PokeMapCard(
              key: ValueKey('event-builder-scene-outcome-${outcome.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              borderRadius: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal,
                    size: 15,
                    color: colors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outcome.label,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if ((outcome.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            outcome.description!.trim(),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ],
                        const SizedBox(height: 7),
                        const Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            PokeMapBadge(
                              label: 'Lecture seule',
                              variant: PokeMapBadgeVariant.neutral,
                            ),
                            PokeMapBadge(
                              label: 'Défini dans la scène',
                              variant: PokeMapBadgeVariant.info,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LifecycleProjectionNotice extends StatelessWidget {
  const _LifecycleProjectionNotice({
    required this.lifecycle,
  });

  final EventBuilderLifecycleProjection lifecycle;

  @override
  Widget build(BuildContext context) {
    final info = _lifecycleUiInfo(lifecycle);
    return _DiagnosticNotice(
      title: info.title,
      message: info.message,
      tone: info.tone,
      severityLabel: info.severityLabel,
      details: info.details,
    );
  }
}

_LifecycleUiInfo _lifecycleUiInfo(EventBuilderLifecycleProjection lifecycle) {
  return switch (lifecycle.status) {
    EventBuilderLifecycleProjectionStatus.reusableNoConsumptionNeeded =>
      const _LifecycleUiInfo(
        title: 'Réutilisable',
        message: 'Aucune consommation d’événement nécessaire.',
        tone: PokeMapTone.success,
        severityLabel: 'OK',
      ),
    EventBuilderLifecycleProjectionStatus.oneShotNoSceneTarget =>
      const _LifecycleUiInfo(
        title: 'Une seule fois',
        message: 'Aucune scène liée, l’activation unique n’est pas vérifiable.',
        tone: PokeMapTone.warning,
        severityLabel: 'À vérifier',
      ),
    EventBuilderLifecycleProjectionStatus.oneShotMissingScene =>
      const _LifecycleUiInfo(
        title: 'Une seule fois',
        message: 'Scène introuvable, l’activation unique n’est pas vérifiable.',
        tone: PokeMapTone.warning,
        severityLabel: 'À corriger',
      ),
    EventBuilderLifecycleProjectionStatus.oneShotIntentOnly =>
      const _LifecycleUiInfo(
        title: 'Une seule fois',
        message: 'Intention à vérifier côté jeu.',
        tone: PokeMapTone.warning,
        severityLabel: 'À vérifier',
      ),
    EventBuilderLifecycleProjectionStatus
          .oneShotExplicitSceneConsequenceForThisEvent =>
      const _LifecycleUiInfo(
        title: 'Consommation explicite trouvée dans la Scene.',
        message: 'Compatible, mais fragile si cette Scene est réutilisée.',
        tone: PokeMapTone.warning,
        severityLabel: 'Compatible',
        details: ['La scène marque cet événement comme joué.'],
      ),
    EventBuilderLifecycleProjectionStatus
          .oneShotExplicitSceneConsequenceForAnotherEvent =>
      _LifecycleUiInfo(
        title: 'Attention : la Scene consomme un autre événement.',
        message:
            lifecycle.warningMessage ?? 'La Scene consomme un autre event.',
        tone: PokeMapTone.danger,
        severityLabel: 'À corriger',
        details: [
          if ((lifecycle.explicitConsumedEventId ?? '').trim().isNotEmpty)
            'Événement consommé : ${lifecycle.explicitConsumedEventId}',
        ],
      ),
  };
}

class _LifecycleUiInfo {
  const _LifecycleUiInfo({
    required this.title,
    required this.message,
    required this.tone,
    required this.severityLabel,
    this.details = const <String>[],
  });

  final String title;
  final String message;
  final PokeMapTone tone;
  final String severityLabel;
  final List<String> details;
}

class _WorldImpactsProjectionBlock extends StatelessWidget {
  const _WorldImpactsProjectionBlock({
    required this.impacts,
    required this.worldRules,
  });

  final List<EventBuilderWorldImpactReadModel> impacts;
  final EventBuilderWorldRulesProjection worldRules;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final hasConsumedEvent = impacts.any(
      (impact) => impact.kind == EventBuilderWorldImpactKind.consumedEvent,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sources projetées',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ce que l’événement ou la scène peut modifier dans l’état du jeu.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 9),
        if (impacts.isEmpty)
          const _DiagnosticNotice(
            title: 'Aucune source d’état projetée',
            message: 'Aucun changement d’état visible pour l’instant.',
            tone: PokeMapTone.info,
            severityLabel: 'Lecture seule',
          )
        else ...[
          Text(
            _sourceCountLabel(impacts.length),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          for (final impact in impacts)
            _WorldImpactProjectionRow(impact: impact),
          if (hasConsumedEvent)
            const _DiagnosticNotice(
              title: 'Consommation d’événement',
              message:
                  'La consommation d’événement est affichée ici comme effet prévisible.\n'
                  'Le statut de fiabilité est détaillé dans Comportement.',
              tone: PokeMapTone.warning,
              severityLabel: 'Projection',
            ),
        ],
        const SizedBox(height: 12),
        _WorldRulesProjectionBlock(projection: worldRules),
      ],
    );
  }
}

class _ProjectedConsequencesBlock extends StatelessWidget {
  const _ProjectedConsequencesBlock({
    required this.sceneOutcomes,
    required this.impacts,
    required this.worldRules,
    required this.stacked,
  });

  final EventBuilderSceneOutcomesProjection sceneOutcomes;
  final List<EventBuilderWorldImpactReadModel> impacts;
  final EventBuilderWorldRulesProjection worldRules;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final sceneSlot = _SceneOutcomesProjectionSlot(projection: sceneOutcomes);
    final worldSlot = KeyedSubtree(
      // Older lots named this section "world". It remains addressable for
      // regression tests, while NS-EVENT-39/40 promote the user-facing
      // read-only projection frame.
      key: const ValueKey('event-builder-flow-block-world'),
      child: _WorldImpactsProjectionBlock(
        impacts: impacts,
        worldRules: worldRules,
      ),
    );
    if (stacked) {
      return KeyedSubtree(
        key: const ValueKey('event-builder-polished-consequences-grid'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sceneSlot,
            const SizedBox(height: 10),
            worldSlot,
          ],
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('event-builder-polished-consequences-grid'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: sceneSlot),
          const SizedBox(width: 10),
          Expanded(child: worldSlot),
        ],
      ),
    );
  }
}

class _WorldRulesProjectionBlock extends StatelessWidget {
  const _WorldRulesProjectionBlock({
    required this.projection,
  });

  final EventBuilderWorldRulesProjection projection;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      key: const ValueKey('event-builder-world-rules-projection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Règles concernées',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Les règles ci-dessous observent ces sources. Elles ne sont pas simulées ici.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 9),
        switch (projection.status) {
          EventBuilderWorldRulesProjectionStatus.noWorldImpacts =>
            const _DiagnosticNotice(
              title: 'Aucune source d’état projetée',
              message:
                  'Aucune règle ne peut être reliée tant qu’aucun changement d’état n’est visible.',
              tone: PokeMapTone.info,
              severityLabel: 'Lecture seule',
            ),
          EventBuilderWorldRulesProjectionStatus.noMatchingRules =>
            const _DiagnosticNotice(
              title: 'Aucune règle du monde liée',
              message: 'Aucune règle ne lit les sources affichées ci-dessus.\n'
                  'Ce n’est pas une erreur.',
              tone: PokeMapTone.info,
              severityLabel: 'Projection passive',
            ),
          EventBuilderWorldRulesProjectionStatus.hasMatchingRules => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _worldRuleCountLabel(projection.rules.length),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                for (final rule in projection.rules)
                  _WorldRuleProjectionRow(rule: rule),
              ],
            ),
        },
      ],
    );
  }
}

class _WorldRuleProjectionRow extends StatelessWidget {
  const _WorldRuleProjectionRow({
    required this.rule,
  });

  final EventBuilderWorldRuleProjectionReadModel rule;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PokeMapCard(
        key: ValueKey('event-builder-world-rule-${rule.ruleId}'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.scope,
              size: 15,
              color: colors.fact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.ruleLabel,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  if (rule.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      rule.description,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PokeMapBadge(
                        label: rule.enabled ? 'Activée' : 'Désactivée',
                        variant: rule.enabled
                            ? PokeMapBadgeVariant.success
                            : PokeMapBadgeVariant.warning,
                      ),
                      const PokeMapBadge(
                        label: 'Lecture seule',
                        variant: PokeMapBadgeVariant.neutral,
                      ),
                      const PokeMapBadge(
                        label: 'Projection passive',
                        variant: PokeMapBadgeVariant.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _WorldRuleProjectionLine(
                    label: 'Condition observée',
                    value: rule.predicateLabel,
                  ),
                  _WorldRuleProjectionLine(
                    label: 'Cible',
                    value: rule.targetLabel,
                  ),
                  _WorldRuleProjectionLine(
                    label: 'Effet déclaré',
                    value: rule.effectLabel,
                  ),
                  _WorldRuleProjectionLine(
                    label: 'Note',
                    value: rule.reason,
                  ),
                  if (!rule.enabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Désactivée : listée pour contexte, sans effet produit.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
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

String _sourceCountLabel(int count) {
  return '$count source${count > 1 ? 's' : ''} projetée${count > 1 ? 's' : ''}';
}

String _worldRuleCountLabel(int count) {
  return '$count règle${count > 1 ? 's' : ''} concernée${count > 1 ? 's' : ''}';
}

class _WorldRuleProjectionLine extends StatelessWidget {
  const _WorldRuleProjectionLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label · $value',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _WorldImpactProjectionRow extends StatelessWidget {
  const _WorldImpactProjectionRow({
    required this.impact,
  });

  final EventBuilderWorldImpactReadModel impact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final category = _worldImpactCategoryLabel(impact.kind);
    final reason = _worldImpactReadableReason(impact);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PokeMapCard(
        key: ValueKey('event-builder-world-impact-${impact.kind.name}'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _worldImpactIcon(impact.kind),
              size: 15,
              color: colors.fact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    impact.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  const Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PokeMapBadge(
                        label: 'Lecture seule',
                        variant: PokeMapBadgeVariant.neutral,
                      ),
                      PokeMapBadge(
                        label: 'Projection',
                        variant: PokeMapBadgeVariant.info,
                      ),
                    ],
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

String _worldImpactCategoryLabel(EventBuilderWorldImpactKind kind) {
  return switch (kind) {
    EventBuilderWorldImpactKind.fact => 'Fait du monde',
    EventBuilderWorldImpactKind.storyStep => 'Étape narrative',
    EventBuilderWorldImpactKind.consumedEvent => 'Événement consommé',
  };
}

IconData _worldImpactIcon(EventBuilderWorldImpactKind kind) {
  return switch (kind) {
    EventBuilderWorldImpactKind.fact => CupertinoIcons.checkmark_shield,
    EventBuilderWorldImpactKind.storyStep => CupertinoIcons.list_bullet,
    EventBuilderWorldImpactKind.consumedEvent => CupertinoIcons.flag,
  };
}

String? _worldImpactReadableReason(EventBuilderWorldImpactReadModel impact) {
  final reason = impact.reason.trim();
  if (reason.isEmpty) {
    return null;
  }
  if (reason ==
      'A one-shot event can drive World Rules through consumed event state after the Scene succeeds.') {
    return 'Peut influencer les règles du monde après la scène.';
  }
  return reason;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: condition.isEditable
                          ? colors.textMuted
                          : colors.warning,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
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
            const SizedBox(height: 5),
            Text(
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
