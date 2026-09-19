import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/dialogs/confirm_studio_close.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_shortcuts.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import '../resources/resource_navigation.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_image_import.dart';
import '../resources/resource_workspace_pane.dart';
import '../resources/resource_brush_selection.dart';
import 'map_workspace_layout.dart';

typedef StudioRuntimeBuilder =
    Widget Function(
      ProjectMapEntry entry,
      String revision,
      VoidCallback onClose,
    );

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
  });
  final MapWorkspaceController controller;
  final ResourcePort? resourcePort;
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
  bool _palette = true;
  bool _resourceSpace = false;
  ResourceNavigation? _resources;
  bool? _inspector;
  MapData? _preparedMap;
  MapWorkspaceVisuals? _visuals;
  String? _resourceError;
  int _gestureGeneration = 0;
  bool _testing = false;
  bool _closing = false;
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
    widget.registerExitGuard(_allowClose);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    final project = _controller.project;
    if (!mounted || project == null) return;
    try {
      final visuals = await widget.loadVisuals(_controller.session, project);
      if (!mounted) {
        await visuals.dispose();
        return;
      }
      _visuals = visuals;
      if (widget.resourcePort != null) {
        _resources = ResourceNavigation(
          workspace: _controller,
          port: widget.resourcePort!,
          visuals: visuals,
          onUse: _useResource,
        )..addListener(_changed);
      }
      visuals.addListener(_changed);
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
    if (mounted) setState(() {});
  }

  void _toolChanged() {
    _gestureGeneration++;
    _visuals?.setBrush(_view?.brush, _view?.tile);
    if (_visuals case final ResourceWorkspaceVisuals resources) {
      resources.setTerrainBrush(_view?.terrain);
    }
    _changed();
  }

  Future<bool> _allowClose() async {
    if (_controller.saving ||
        _closing ||
        _testing ||
        _resources?.busy == true) {
      return false;
    }
    if (!_controller.dirty && _resources?.dirty != true) return true;
    setState(() => _closing = true);
    try {
      final choice = await confirmStudioClose(context);
      if (!mounted || choice == null || choice == 'cancel') return false;
      if (choice == 'save') {
        if (_resources != null && !await _resources!.saveDrafts()) return false;
        return await _controller.saveAll();
      }
      return choice == 'discard';
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  Future<void> _close() async {
    if (await _allowClose() && mounted) await widget.onClose();
  }

  Future<void> _test() async {
    final document = _controller.active;
    if (document == null || _testing || _controller.loading) return;
    final entry = _controller.project!.maps.firstWhere(
      (e) => e.id == document.base.mapId,
    );
    setState(() {
      _testing = true;
      _gestureGeneration++;
    });
    try {
      if (!await _controller.save(document) || !mounted) return;
      if (!identical(_controller.active, document) || _controller.loading) {
        return;
      }
      if (document.dirty) {
        document.error =
            'La carte a encore changé. Enregistrez-la avant de tester.';
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (routeContext) => widget.runtimeBuilder(
            entry,
            document.base.revision,
            () => Navigator.of(routeContext).pop(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _keyboard(void Function() action) {
    if (_resourceSpace) return;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
        _controller.loading ||
        _testing ||
        _closing) {
      return;
    }
    action();
    _toolChanged();
  }

  @override
  void dispose() {
    widget.registerExitGuard(null);
    _controller.removeListener(_changed);
    final visuals = _visuals;
    if (visuals != null) {
      visuals.removeListener(_changed);
      unawaited(visuals.dispose());
    }
    _resources?.removeListener(_changed);
    _resources?.dispose();
    _search.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    super.dispose();
  }

  void _openResources([ProjectElementEntry? element, bool edit = false]) {
    if (_resources == null) return;
    _resources!.openElement(element, edit: edit);
    setState(() => _resourceSpace = true);
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
    setState(() => _resourceSpace = false);
    _toolChanged();
  }

  @override
  Widget build(BuildContext context) {
    final document = _controller.active;
    final error = _controller.error ?? document?.error ?? _resourceError;
    return CallbackShortcuts(
      bindings: workspaceShortcuts(_controller, _view, _keyboard),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: AbsorbPointer(
            key: const ValueKey('workspace-preparing'),
            absorbing: _testing || _closing || _resources?.busy == true,
            child: SafeArea(
              child: MapWorkspaceLayout(
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
                  _gestureGeneration++;
                  unawaited(_controller.activate(entry));
                },
                onSave: document == null || document.saving
                    ? null
                    : () => _controller.save(document),
                onTest: document == null || _testing || document.saving
                    ? null
                    : _test,
                onClose: _close,
                onResources: _openResources,
                onMap: () => setState(() => _resourceSpace = false),
                onOpenElement: (element) => _openResources(element),
                onEditElement: (element) => _openResources(element, true),
                onTileset: (tileset) => _useResource(
                  ResourceItem(
                    id: tileset.id,
                    name: tileset.name,
                    kind: ResourceKind.images,
                    tileset: tileset,
                  ),
                ),
                resourceContent: !_resourceSpace || _resources == null
                    ? null
                    : ResourceWorkspacePane(
                        navigation: _resources!,
                        picker: widget.imagePicker ?? () async => null,
                        onBack: () => setState(() => _resourceSpace = false),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
