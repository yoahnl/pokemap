import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_warp_drafts.dart';

import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class MapWarpDoorEditor extends StatefulWidget {
  const MapWarpDoorEditor({
    super.key,
    required this.map,
    required this.project,
    required this.warp,
    required this.onApply,
  });

  final MapData map;
  final ProjectManifest project;
  final MapWarp warp;
  final ValueChanged<MapWarpDoor?> onApply;

  @override
  State<MapWarpDoorEditor> createState() => _MapWarpDoorEditorState();
}

class _MapWarpDoorEditorState extends State<MapWarpDoorEditor> {
  late MapWarpDoorDraft form;

  @override
  void initState() {
    super.initState();
    form = MapWarpDoorDraft(widget.map, widget.project, widget.warp);
  }

  @override
  void didUpdateWidget(MapWarpDoorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    form.map = widget.map;
    form.project = widget.project;
    form.warp = widget.warp;
    if (oldWidget.warp.id != widget.warp.id ||
        oldWidget.map.id != widget.map.id ||
        oldWidget.warp.door != widget.warp.door) {
      form.reset(widget.warp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = form.candidates;
    final exits = form.exits();
    final draft = form.value;
    final instance = candidates
        .where((item) => item.id == draft?.instanceId)
        .firstOrNull;
    final clips = form.clips(instance == null ? null : form.model(instance));
    final changed = form.changed;
    final problem = form.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioToggleRow(
          label: 'Porte animée',
          description: 'Ouvre et ferme une porte placée sur cette carte lors du passage.',
          value: form.enabled,
          onChanged: (value) => setState(() {
            form.enable(value);
          }),
        ),
        if (form.enabled) ...[
          if (candidates.isEmpty) ...[
            const StudioNotice(
              'Placez un modèle avec une animation, sans lecture automatique, sur cette carte.',
            ),
            const SizedBox(height: 8),
          ],
          StudioSelect(
            label: 'Modèle de porte',
            value: draft?.instanceId,
            options: {
              for (final item in candidates)
                item.id:
                    '${form.model(item)!.name} · ${item.position.x.toStringAsFixed(1)}, ${item.position.z.toStringAsFixed(1)}',
            },
            onChanged: exits.isEmpty
                ? null
                : (id) => setState(() {
                    form.value = form.binding(
                      candidates.singleWhere((item) => item.id == id),
                      draft?.exitPos ?? exits.keys.first,
                    );
                  }),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Animation d’ouverture',
            value: draft?.openAnimationIndex.toString(),
            options: {for (final clip in clips) '${clip.index}': clip.name},
            onChanged: draft == null
                ? null
                : (index) => setState(() {
                    form.value = draft.copyWith(
                      openAnimationIndex: int.parse(index),
                    );
                  }),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Animation de fermeture',
            value: draft?.closeAnimationIndex.toString(),
            options: {for (final clip in clips) '${clip.index}': clip.name},
            onChanged: draft == null
                ? null
                : (index) => setState(() {
                    form.value = draft.copyWith(
                      closeAnimationIndex: int.parse(index),
                    );
                  }),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Case de dégagement',
            value: draft == null ? null : form.exitId(draft.exitPos),
            options: {
              for (final entry in exits.entries)
                form.exitId(entry.key):
                    '${entry.value} · ${entry.key.x}, ${entry.key.y}',
            },
            onChanged: draft == null
                ? null
                : (id) => setState(() {
                    form.value = draft.copyWith(
                      exitPos: exits.keys.singleWhere(
                        (position) => form.exitId(position) == id,
                      ),
                    );
                  }),
          ),
          const SizedBox(height: 8),
          const Text(
            'Au retour, le personnage quitte la porte vers cette case avant sa fermeture.',
          ),
          if (problem != null) ...[
            const SizedBox(height: 8),
            StudioNotice(problem, isError: true),
          ],
        ],
        if (changed) ...[
          const SizedBox(height: 8),
          StudioButton(
            label: 'Appliquer la porte',
            onPressed: problem == null
                ? () => widget.onApply(form.enabled ? form.value : null)
                : null,
          ),
        ],
      ],
    );
  }
}
