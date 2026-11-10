import '../../../features/scenes/application/scene_npc_pose_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

class SceneNpcPoseActionForm extends StatefulWidget {
  const SceneNpcPoseActionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
    this.loadMap,
  });
  final ProjectManifest project;
  final SceneActionPayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<MapData> Function(String)? loadMap;

  @override
  State<SceneNpcPoseActionForm> createState() => _SceneNpcPoseActionFormState();
}

class _SceneNpcPoseActionFormState extends State<SceneNpcPoseActionForm> {
  late final SceneNpcPoseDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneNpcPoseDraft(
      project: widget.project,
      current: widget.current,
      loadMap: widget.loadMap,
      changed: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(SceneNpcPoseActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      project: widget.project,
      current: widget.current,
      loadMap: widget.loadMap,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        label: 'Carte du PNJ',
        value: draft.selectedMapId,
        options: draft.mapOptions,
        onChanged: (value) => setState(() {
          draft.selectedMapId = value;
          draft.selectedEntityId = null;
          draft.reloadMap();
        }),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'PNJ à variantes',
        value: draft.selectedEntityId,
        options: draft.actorOptions,
        onChanged: draft.loading
            ? null
            : (value) => setState(() => draft.selectedEntityId = value),
      ),
      if (draft.loading) const StudioNotice('Chargement des PNJ…'),
      if (draft.error != null) StudioNotice(draft.error!, isError: true),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Modification du PNJ',
        value: draft.mode,
        options: const {
          'position': 'Position et direction',
          'facing': 'Direction uniquement',
        },
        onChanged: (value) => setState(() => draft.mode = value),
      ),
      if (draft.mode == 'position') ...[
        const StudioNotice(
          'Le placement est réservé à un PNJ actuellement masqué.',
        ),
        StudioDraftField(
          label: 'Case X',
          value: draft.xText,
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => draft.xText = value),
        ),
        StudioDraftField(
          label: 'Case Y',
          value: draft.yText,
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => draft.yText = value),
        ),
      ] else
        const StudioNotice(
          'La position actuelle du PNJ est conservée, même si le PNJ est masqué.',
        ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Direction du PNJ',
        value: draft.facingName,
        options: {
          if (draft.mode == 'position') '': 'Conserver la direction',
          'south': 'Sud',
          'north': 'Nord',
          'east': 'Est',
          'west': 'Ouest',
        },
        onChanged: (value) => setState(() => draft.facingName = value),
      ),
      const SizedBox(height: 12),
      StudioButton(
        label: widget.current == null
            ? 'Ajouter l’action'
            : 'Appliquer l’action',
        onPressed: draft.pose == null
            ? null
            : () => widget.onApply(SceneActionPayload.consequence(draft.pose!)),
      ),
    ],
  );
}
