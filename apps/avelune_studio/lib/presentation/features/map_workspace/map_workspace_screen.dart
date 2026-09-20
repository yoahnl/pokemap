import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'workspace_actions.dart';
import 'workspace_session_loader.dart';
import '../narrative/narrative_navigation.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_shortcuts.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import '../resources/resource_navigation.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_image_import.dart';
import 'workspace_secondary_content.dart';
import '../resources/resource_brush_selection.dart';
import 'map_workspace_layout.dart';
import '../../../features/narrative/domain/narrative_port.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../shell/studio_home_navigation.dart';
export 'workspace_actions.dart' show StudioRuntimeBuilder;

part 'workspace_home_binding.dart';

class MapWorkspaceScreen extends StatefulWidget {
  const MapWorkspaceScreen({
    super.key,
    required this.controller,
    required this.loadVisuals,
    required this.runtimeBuilder,
    required this.onClose,
    required this.registerExitGuard,
    this.resourcePort,
    this.imagePicker,
    this.narrativePort,
    this.home,
  });
  final MapWorkspaceController controller;
  final StudioHomeNavigation? home;
  final ResourcePort? resourcePort;
  final NarrativePort? narrativePort;
  final PickResourceImage? imagePicker;
  final LoadWorkspaceVisuals loadVisuals;
  final StudioRuntimeBuilder runtimeBuilder;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()? guard) registerExitGuard;
  @override
  State<MapWorkspaceScreen> createState() => _MapWorkspaceScreenState();
}

class _MapWorkspaceScreenState extends State<MapWorkspaceScreen> {
  final _views = <String, MapWorkspaceViewState>{};
  final _search = TextEditingController();
  final _homeSearch = TextEditingController();
  bool _palette = true;
  WorkspaceSpace _space = WorkspaceSpace.map;
  ResourceNavigation? _resources;
  NarrativeWorkspaceController? _narrative;
  bool? _inspector;
  MapData? _preparedMap;
  MapWorkspaceVisuals? _visuals;
  String? _resourceError;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _interactionNotice;
  int _gestureGeneration = 0;
  late final WorkspaceActions _actions;
  MapWorkspaceController get _controller => widget.controller;
  MapWorkspaceViewState? get _view {
    final id = _controller.active?.base.mapId;
    return id == null
        ? null
        : _views.putIfAbsent(id, MapWorkspaceViewState.new);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _actions = WorkspaceActions(
      controller: _controller,
      context: () => context,
      mounted: () => mounted,
      changed: () {
        _gestureGeneration++;
        _changed();
      },
      resources: () => _resources,
      narrative: () => _narrative,
      runtimeBuilder: widget.runtimeBuilder,
    );
    widget.registerExitGuard(_actions.allowClose);
    widget.home?.allowSwitch = _actions.allowClose;
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final loaded = await loadWorkspaceSession(
        widget,
        mounted: () => mounted,
        changed: _changed,
        onUse: _useResource,
      );
      if (loaded == null) return;
      _visuals = loaded.visuals;
      _resources = loaded.resources;
      _narrative = loaded.narrative;
      _changed();
    } catch (_) {
      if (mounted) {
        setState(
          () => _resourceError =
              'Impossible de charger les ressources de ce projet.',
        );
      }
    }
  }

  void _changed() {
    final map = _controller.active?.current;
    if (map != null && _visuals != null && !identical(map, _preparedMap)) {
      _preparedMap = map;
      _visuals!.setActiveMap(map);
    }
    if (mounted) {
      setState(() {});
      _publishHome();
    }
  }

  void _toolChanged() {
    _gestureGeneration++;
    retainWorkspaceBrush(_visuals, _view);
    _changed();
  }

  void _show(WorkspaceSpace space) {
    _interactionNotice?.close();
    if (mounted) setState(() => _space = space);
  }

  Future<void> _close() async {
    if (await _actions.allowClose() && mounted) await widget.onClose();
  }

  void _keyboard(void Function() action) {
    if (_space != WorkspaceSpace.map) return;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
        _controller.loading ||
        _actions.testing ||
        _actions.closing) {
      return;
    }
    action();
    _toolChanged();
  }

  @override
  void dispose() {
    widget.registerExitGuard(null);
    _controller.removeListener(_changed);
    _controller.historyGuard = null;
    final visuals = _visuals;
    if (visuals != null) {
      visuals.removeListener(_changed);
      unawaited(visuals.dispose());
    }
    _resources?.removeListener(_changed);
    _resources?.dispose();
    _search.dispose();
    _homeSearch.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    super.dispose();
  }

  Future<void> _zone(MapRect area) async {
    if (_narrative == null) return;
    await openNarrativeZone(_narrative!, area);
    if (mounted) _show(WorkspaceSpace.interaction);
  }

  Future<void> _useResource(ResourceItem item) async {
    final used = await useResourceOnMap(
      context: context,
      workspace: _controller,
      item: item,
      visuals: _visuals!,
      view: () => _view,
    );
    if (!mounted || !used) return;
    if (item.terrain != null) _search.clear();
    _openMap();
    _toolChanged();
  }

  @override
  Widget build(BuildContext context) {
    final document = _controller.active;
    final error =
        workspaceNarrativeError(
          _narrative,
          narrativePage: _space == WorkspaceSpace.interaction,
        ) ??
        _controller.error ??
        document?.error ??
        _resourceError;
    return CallbackShortcuts(
      bindings: workspaceShortcuts(
        _controller,
        _view,
        _keyboard,
        onSave: () {
          if (document != null) {
            unawaited(
              _narrative?.save(document: document) ??
                  _controller.save(document),
            );
          }
        },
      ),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: AbsorbPointer(
            key: const ValueKey('workspace-preparing'),
            absorbing:
                _actions.testing ||
                _actions.closing ||
                _resources?.busy == true ||
                _narrative?.busy == true,
            child: SafeArea(
              child: MapWorkspaceLayout(
                homeSearch: widget.home?.search ?? _homeSearch,
                onSearch: (_) => widget.home?.searchHome(),
                onHome: widget.home?.showHome,
                activeSpace: _space.name,
                controller: _controller,
                view: _view,
                visuals: _visuals,
                search: _search,
                error: error,
                palette: _palette,
                inspector: _inspector,
                generation: _gestureGeneration,
                onPalette: () => setState(() => _palette = !_palette),
                onInspector: () =>
                    setState(() => _inspector = !(_inspector ?? true)),
                onChanged: _changed,
                onToolChanged: _toolChanged,
                onActivate: (entry) {
                  _interactionNotice?.close();
                  _gestureGeneration++;
                  unawaited(_controller.activate(entry));
                },
                onSave: document == null || document.saving
                    ? null
                    : () =>
                          _narrative?.save(document: document) ??
                          _controller.save(document),
                onTest: document == null || _actions.testing || document.saving
                    ? null
                    : _actions.test,
                onClose: _close,
                onResources: _openResources,
                onMap: _openMap,
                onStory: _narrative == null
                    ? null
                    : () => _show(WorkspaceSpace.story),
                onEditInteraction: _editInteraction,
                onZoneDrawn: _narrative == null ? null : _zone,
                deletionBlocked: _narrative?.blocksDeletion,
                onOpenElement: (element) => _openResources(element),
                onEditElement: (element) => _openResources(element, true),
                resourceContent: workspaceSecondaryContent(
                  space: _space,
                  narrative: _narrative,
                  resources: _resources,
                  visuals: _visuals,
                  onMap: _openMap,
                  onInteraction: () => _show(WorkspaceSpace.interaction),
                  onTest: _actions.test,
                  imagePicker: widget.imagePicker,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
