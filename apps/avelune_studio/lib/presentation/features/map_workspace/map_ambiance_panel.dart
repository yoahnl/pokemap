import '../../../features/project_visuals/application/project_visuals_controller.dart';
import 'map_weather_controls.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'map_day_night_panel.dart';

class MapAmbiancePanel extends StatefulWidget {
  const MapAmbiancePanel({
    super.key,
    required this.workspace,
    required this.document,
    required this.project,
    required this.onChanged,
    this.preview,
    this.onSave,
    this.onMapChanged,
  });
  final MapWorkspaceController workspace;
  final EditableMapDocument document;
  final ProjectManifest project;
  final SpatialSceneController? preview;
  final VoidCallback onChanged;
  final VoidCallback? onSave, onMapChanged;
  @override
  State<MapAmbiancePanel> createState() => _MapAmbiancePanelState();
}

class _MapAmbiancePanelState extends State<MapAmbiancePanel> {
  ProjectVisualsController? _weather;
  bool _leavingMap = false;
  bool get _currentMap => identical(widget.workspace.active, widget.document);
  final _status = ValueNotifier(0);
  @override
  void initState() {
    super.initState();
    _weather = widget.document.current.spatialScene == null ? null : widget.workspace.weatherDraftFor(widget.document);
    _weather?.addListener(_refresh);
    widget.workspace.addListener(_refresh);
    widget.document.atmosphere?.addListener(_refresh);
  }

  @override
  void didUpdateWidget(MapAmbiancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.document, widget.document) && identical(oldWidget.workspace, widget.workspace)) return;
    _leavingMap = false;
    oldWidget.workspace.removeListener(_refresh);
    oldWidget.document.atmosphere?.removeListener(_refresh);
    _weather?.removeListener(_refresh);
    _weather = widget.document.current.spatialScene == null ? null : widget.workspace.weatherDraftFor(widget.document);
    _weather?.addListener(_refresh);
    widget.workspace.addListener(_refresh);
    widget.document.atmosphere?.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    if (!_currentMap && !_leavingMap) {
      _leavingMap = true;
      setState(() {});
      if (widget.onMapChanged != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_currentMap) widget.onMapChanged?.call();
        });
      }
    }
    _status.value++;
  }

  @override
  void dispose() {
    _weather?.removeListener(_refresh);
    widget.workspace.removeListener(_refresh);
    widget.document.atmosphere?.removeListener(_refresh);
    _status.dispose();
    super.dispose();
  }

  Widget _saveBar() {
    final document = widget.document;
    final atmosphere = document.atmosphere;
    final saving = document.saving || atmosphere?.saving == true || _weather?.saving == true;
    final dirty = document.dirty || atmosphere?.dirty == true || _weather?.dirty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StudioButton(
                key: const ValueKey('ambiance-save'),
                label: 'Enregistrer',
                icon: Icons.save_outlined,
                loading: saving,
                onPressed: saving || !dirty || !_currentMap ? null : widget.onSave,
              ),
              StudioBadge(
                saving
                    ? 'Enregistrement…'
                    : dirty
                    ? 'À enregistrer'
                    : 'Enregistré',
                tone: dirty ? StudioTone.warning : StudioTone.success,
              ),
            ],
          ),
        ),
        if (_weather?.error ?? atmosphere?.error ?? document.error case final message?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: StudioNotice(message, isError: true),
          ),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListenableBuilder(
        listenable: _status,
        builder: (context, _) => _saveBar(),
      ),
      Expanded(
        child: IgnorePointer(ignoring: !_currentMap, child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_weather case final owner?) ListenableBuilder(listenable: owner, builder: (context, _) => MapWeatherControls(
              patch: owner.preview.value,
              inherited: SpatialVisualPatch.fromScene(camera: widget.document.current.spatialScene!.camera, atmosphere: widget.document.atmosphere?.current ?? SpatialAtmosphereSettings()).overriddenBy(widget.workspace.inheritedVisualProfile),
              onChanged: owner.loading || owner.saving || owner.saved == null || !_currentMap ? null : owner.edit,
              onEditStart: owner.beginGesture, onEditEnd: owner.endGesture,
            )),
            if (_weather case final owner?) ListenableBuilder(listenable: owner, builder: (context, _) => Wrap(spacing: 8, children: [
              StudioButton(label: 'Annuler la météo', icon: Icons.undo, secondary: true, onPressed: owner.canUndo && !owner.saving ? owner.undo : null),
              StudioButton(label: 'Rétablir la météo', icon: Icons.redo, secondary: true, onPressed: owner.canRedo && !owner.saving ? owner.redo : null),
              if (owner.error != null) StudioButton(label: 'Recharger la météo enregistrée', secondary: true, onPressed: owner.saving ? null : () => owner.open(map: owner.scope)),
            ])),
            MapDayNightPanel(
            document: widget.document,
            project: widget.project,
            controller: widget.preview,
            showEffectSaveActions: false,
            onChanged: () {
              widget.onChanged();
              setState(() {});
            },
          ),
          ]),
        )),
      ),
    ],
  );
}
