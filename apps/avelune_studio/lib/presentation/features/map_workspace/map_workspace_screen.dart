import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'workspace_resource_diagnostics.dart';
import 'map_workspace_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/dialogs/confirm_studio_close.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_toolbar.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_shortcuts.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

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
  });
  final MapWorkspaceController controller;
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
    _changed();
  }

  Future<bool> _allowClose() async {
    if (_controller.saving || _closing || _testing) return false;
    if (!_controller.dirty) return true;
    _closing = true;
    try {
      final choice = await confirmStudioClose(context);
      if (!mounted || choice == null || choice == 'cancel') return false;
      if (choice == 'save') return await _controller.saveAll();
      return choice == 'discard';
    } finally {
      _closing = false;
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
    _search.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = _controller.active;
    final project = _controller.project;
    final visuals = _visuals;
    final view = _view;
    final error = _controller.error ?? document?.error ?? _resourceError;
    return CallbackShortcuts(
      bindings: workspaceShortcuts(_controller, _view, _keyboard),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: AbsorbPointer(
            key: const ValueKey('workspace-preparing'),
            absorbing: _testing,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final expandedText =
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  final inspector =
                      _inspector ??
                      (constraints.maxWidth >= 1150 && !expandedText);
                  return Column(
                    children: [
                      MapWorkspaceToolbar(
                        controller: _controller,
                        view: view,
                        onChanged: _toolChanged,
                        paletteVisible: _palette,
                        inspectorVisible: inspector,
                        onPalette: () => setState(() => _palette = !_palette),
                        onInspector: () =>
                            setState(() => _inspector = !inspector),
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
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: StudioNotice(error, isError: true),
                        ),
                      Expanded(
                        child:
                            _controller.loading ||
                                (project == null && error == null) ||
                                (project != null &&
                                    visuals == null &&
                                    _resourceError == null)
                            ? const Center(child: CircularProgressIndicator())
                            : document == null ||
                                  visuals == null ||
                                  view == null ||
                                  project == null
                            ? const Center(
                                child: Text(
                                  'Choisissez une carte disponible dans ce projet.',
                                ),
                              )
                            : Row(
                                children: [
                                  if (_palette)
                                    MapWorkspacePalette(
                                      project: project,
                                      document: document,
                                      visuals: visuals,
                                      view: view,
                                      search: _search,
                                      onChanged: _toolChanged,
                                    ),
                                  Expanded(
                                    child: MapWorkspaceCanvas(
                                      key: ValueKey(document.base.mapId),
                                      document: document,
                                      project: project,
                                      visuals: visuals,
                                      view: view,
                                      onChanged: _changed,
                                      gestureGeneration: _gestureGeneration,
                                    ),
                                  ),
                                  if (inspector)
                                    MapWorkspaceInspector(
                                      project: project,
                                      document: document,
                                      visuals: visuals,
                                      onChanged: _toolChanged,
                                    ),
                                ],
                              ),
                      ),
                      if (visuals != null)
                        WorkspaceResourceDiagnostics(visuals: visuals),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
