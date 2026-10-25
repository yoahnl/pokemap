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
  });
  final MapWorkspaceController workspace;
  final EditableMapDocument document;
  final ProjectManifest project;
  final SpatialSceneController? preview;
  final VoidCallback onChanged;
  final VoidCallback? onSave;
  @override
  State<MapAmbiancePanel> createState() => _MapAmbiancePanelState();
}

class _MapAmbiancePanelState extends State<MapAmbiancePanel> {
  final _status = ValueNotifier(0);
  @override
  void initState() {
    super.initState();
    widget.workspace.addListener(_refresh);
    widget.document.atmosphere?.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) _status.value++;
  }

  @override
  void dispose() {
    widget.workspace.removeListener(_refresh);
    widget.document.atmosphere?.removeListener(_refresh);
    _status.dispose();
    super.dispose();
  }

  Widget _saveBar() {
    final document = widget.document;
    final atmosphere = document.atmosphere;
    final saving = document.saving || atmosphere?.saving == true;
    final dirty = document.dirty || atmosphere?.dirty == true;
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
                onPressed: saving || !dirty ? null : widget.onSave,
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
        if (atmosphere?.error ?? document.error case final message?)
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MapDayNightPanel(
            document: widget.document,
            project: widget.project,
            controller: widget.preview,
            showEffectSaveActions: false,
            onChanged: () {
              widget.onChanged();
              setState(() {});
            },
          ),
        ),
      ),
    ],
  );
}
