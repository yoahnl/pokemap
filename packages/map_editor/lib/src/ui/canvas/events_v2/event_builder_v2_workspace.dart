import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/state/narrative_event_builder_v2_state.dart';
import '../../../features/narrative/state/narrative_event_validation_state.dart';
import '../../design_system/design_system.dart';
import 'event_builder_v2_editor.dart';
import 'event_builder_v2_element_library.dart';
import 'event_builder_v2_inspector.dart';
import 'event_builder_v2_project_list.dart';

const double kEventBuilderV2MinimumViewportWidth = 1280;

class EventBuilderV2NarrowViewportGate extends StatelessWidget {
  const EventBuilderV2NarrowViewportGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const PokeMapPageSurface(
      padding: EdgeInsets.zero,
      child: PokeMapEmptyState(
        title: 'Zone de travail trop étroite',
        description:
            'Libérez au moins 1280 px dans la zone Event, par exemple en agrandissant la fenêtre. Votre sélection est conservée.',
        icon: Icon(CupertinoIcons.rectangle_expand_vertical),
      ),
    );
  }
}

class EventBuilderV2Workspace extends StatefulWidget {
  const EventBuilderV2Workspace({
    super.key,
    required this.state,
    required this.mode,
    required this.selectedStableKey,
    required this.viewportWidth,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSelectEvent,
    required this.onCreateEvent,
    required this.onOpenLibrary,
    this.onChangeSource,
    this.onSeeOnMap,
    this.onAddCondition,
    this.onChangeScene,
    this.onOpenScene,
    this.onChangeBehavior,
    this.onManageEvaluationOrder,
    this.validationItems = const [],
    this.onValidationAction,
    this.eventListScrollController,
    this.eventFocusNodeForStableKey,
  });

  final NarrativeEventBuilderV2State state;
  final EventSystemMode mode;
  final String? selectedStableKey;
  final double viewportWidth;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<NarrativeEventBuilderV2Filter> onFilterChanged;
  final ValueChanged<NarrativeEventProjectSummary> onSelectEvent;
  final VoidCallback? onCreateEvent;
  final VoidCallback? onOpenLibrary;
  final VoidCallback? onChangeSource;
  final VoidCallback? onSeeOnMap;
  final VoidCallback? onAddCondition;
  final VoidCallback? onChangeScene;
  final VoidCallback? onOpenScene;
  final VoidCallback? onChangeBehavior;
  final VoidCallback? onManageEvaluationOrder;
  final List<NarrativeEventValidationItem> validationItems;
  final ValueChanged<NarrativeEventValidationItem>? onValidationAction;
  final ScrollController? eventListScrollController;
  final FocusNode Function(String stableKey)? eventFocusNodeForStableKey;

  @override
  State<EventBuilderV2Workspace> createState() =>
      _EventBuilderV2WorkspaceState();
}

class _EventBuilderV2WorkspaceState extends State<EventBuilderV2Workspace> {
  late final TextEditingController _searchController;
  final FocusNode _libraryLauncherFocusNode = FocusNode(
    debugLabel: 'Event Builder V2 library launcher',
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.query);
  }

  @override
  void didUpdateWidget(covariant EventBuilderV2Workspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.state.query) {
      _searchController.value = TextEditingValue(
        text: widget.state.query,
        selection: TextSelection.collapsed(offset: widget.state.query.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _libraryLauncherFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewportWidth < kEventBuilderV2MinimumViewportWidth) {
      return const EventBuilderV2NarrowViewportGate();
    }

    final selected = widget.selectedStableKey == null
        ? null
        : widget.state.readModel.eventByStableKey(
            widget.selectedStableKey!,
          );
    final controls = Row(
      children: [
        Expanded(
          child: PokeMapSearchField(
            key: const ValueKey('event-builder-v2-search'),
            controller: _searchController,
            onChanged: widget.onQueryChanged,
            hintText: 'Rechercher un événement…',
            semanticLabel: 'Rechercher dans tous les événements du projet',
          ),
        ),
        const SizedBox(width: 6),
        PokeMapIconButton(
          key: const ValueKey('event-builder-v2-filter-button'),
          onPressed: () => _openFilterSheet(context),
          icon: const Icon(CupertinoIcons.square_grid_2x2),
          tooltip: 'Filtrer les événements',
          size: 34,
        ),
      ],
    );

    return Semantics(
      container: true,
      label: 'Event Builder V2, vue projet',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The desktop viewport alone is not enough when this workspace is
          // nested inside project chrome. Keep the fifth panel inline only
          // when the business area can honor its 1280 px minimum budget.
          final inlineLibrary =
              widget.viewportWidth >= 1480 && constraints.maxWidth >= 1280;
          final metrics = _EventBuilderV2LayoutMetrics.resolve(
            availableWidth: constraints.maxWidth,
            inlineLibrary: inlineLibrary,
            referenceViewport: widget.viewportWidth >= 1672,
          );

          final list = SizedBox(
            key: const ValueKey('event-builder-v2-list'),
            width: metrics.listWidth,
            child: EventBuilderV2ProjectList(
              groups: widget.state.visibleGroups,
              projectEventCount: widget.state.readModel.events.length,
              selectedStableKey: widget.selectedStableKey,
              controls: controls,
              projectIsEmpty: widget.state.isProjectEmpty,
              hasNoMatchingEvents: widget.state.hasNoMatchingEvents,
              onSelectEvent: widget.onSelectEvent,
              onCreateEvent:
                  widget.state.isReadOnly ? null : widget.onCreateEvent,
              scrollController: widget.eventListScrollController,
              focusNodeForStableKey: widget.eventFocusNodeForStableKey,
            ),
          );

          final editor = SizedBox(
            key: const ValueKey('event-builder-v2-editor'),
            width: metrics.editorWidth,
            child: inlineLibrary
                ? EventBuilderV2Editor(
                    event: selected,
                    onChangeSource: widget.onChangeSource,
                    onSeeOnMap: widget.onSeeOnMap,
                    onAddCondition: widget.onAddCondition,
                    onChangeScene: widget.onChangeScene,
                    onOpenScene: widget.onOpenScene,
                    onChangeBehavior: widget.onChangeBehavior,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PokeMapToolbarSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PokeMapButton(
                            key: const ValueKey(
                              'event-builder-v2-open-library',
                            ),
                            // The side sheet captures the current focus before
                            // opening and restores this exact launcher on close.
                            focusNode: _libraryLauncherFocusNode,
                            onPressed: widget.onOpenLibrary,
                            variant: PokeMapButtonVariant.ghost,
                            size: PokeMapButtonSize.small,
                            leading: const Icon(CupertinoIcons.square_grid_2x2),
                            child: const Text('Ouvrir la bibliothèque'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: EventBuilderV2Editor(
                          event: selected,
                          onChangeSource: widget.onChangeSource,
                          onSeeOnMap: widget.onSeeOnMap,
                          onAddCondition: widget.onAddCondition,
                          onChangeScene: widget.onChangeScene,
                          onOpenScene: widget.onOpenScene,
                          onChangeBehavior: widget.onChangeBehavior,
                        ),
                      ),
                    ],
                  ),
          );

          final inspector = SizedBox(
            key: const ValueKey('event-builder-v2-inspector'),
            width: metrics.inspectorWidth,
            child: EventBuilderV2Inspector(
              event: selected,
              validationItems: widget.validationItems,
              onValidationAction: widget.onValidationAction,
              onChangeSource: widget.onChangeSource,
              onSeeOnMap: widget.onSeeOnMap,
              onOpenScene: widget.onOpenScene,
              onChangeBehavior: widget.onChangeBehavior,
              onManageEvaluationOrder: widget.onManageEvaluationOrder,
            ),
          );

          final children = <Widget>[
            list,
            const SizedBox(width: 8),
            if (inlineLibrary) ...[
              SizedBox(
                key: const ValueKey('event-builder-v2-library'),
                width: metrics.libraryWidth,
                child: EventBuilderV2ElementLibrary(
                  hasLinkedScene: selected?.scene.sceneId != null,
                  onOpenScene: widget.onOpenScene,
                ),
              ),
              const SizedBox(width: 8),
            ],
            editor,
            const SizedBox(width: 8),
            inspector,
          ];

          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );

          if (widget.mode != EventSystemMode.legacyOnly) {
            return content;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.warning,
                title: 'Runtime en mode historique',
                message:
                    'Les événements V2 sont conservés mais ne seront pas joués tant que le projet reste dans ce mode.',
              ),
              const SizedBox(height: 8),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) {
    return showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Filtrer les événements',
      semanticLabel: 'Choisir les événements à afficher',
      width: 320,
      builder: (sheetContext) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final filter in NarrativeEventBuilderV2Filter.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: PokeMapSidebarItem(
                label: filter.label,
                selected: widget.state.filter == filter,
                icon: Icon(_filterIcon(filter)),
                onTap: () {
                  widget.onFilterChanged(filter);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}

IconData _filterIcon(NarrativeEventBuilderV2Filter filter) => switch (filter) {
      NarrativeEventBuilderV2Filter.all => CupertinoIcons.square_grid_2x2,
      NarrativeEventBuilderV2Filter.active => CupertinoIcons.checkmark_circle,
      NarrativeEventBuilderV2Filter.drafts => CupertinoIcons.pencil,
      NarrativeEventBuilderV2Filter.attention =>
        CupertinoIcons.exclamationmark_triangle,
      NarrativeEventBuilderV2Filter.oldFormat => CupertinoIcons.archivebox,
    };

class _EventBuilderV2LayoutMetrics {
  const _EventBuilderV2LayoutMetrics({
    required this.listWidth,
    required this.libraryWidth,
    required this.editorWidth,
    required this.inspectorWidth,
  });

  final double listWidth;
  final double libraryWidth;
  final double editorWidth;
  final double inspectorWidth;

  static _EventBuilderV2LayoutMetrics resolve({
    required double availableWidth,
    required bool inlineLibrary,
    required bool referenceViewport,
  }) {
    if (!inlineLibrary) {
      const list = 220.0;
      const inspector = 320.0;
      final editor = (availableWidth - list - inspector - 16).clamp(
        480.0,
        double.infinity,
      );
      return _EventBuilderV2LayoutMetrics(
        listWidth: list,
        libraryWidth: 0,
        editorWidth: editor,
        inspectorWidth: inspector,
      );
    }

    if (referenceViewport && availableWidth >= 1456) {
      const list = 266.0;
      const library = 213.0;
      const inspector = 388.0;
      final editor = availableWidth - list - library - inspector - 24;
      return _EventBuilderV2LayoutMetrics(
        listWidth: list,
        libraryWidth: library,
        editorWidth: editor,
        inspectorWidth: inspector,
      );
    }

    const list = 236.0;
    const library = 190.0;
    const inspector = 330.0;
    final editor = (availableWidth - list - library - inspector - 24).clamp(
      500.0,
      double.infinity,
    );
    return _EventBuilderV2LayoutMetrics(
      listWidth: list,
      libraryWidth: library,
      editorWidth: editor,
      inspectorWidth: inspector,
    );
  }
}
