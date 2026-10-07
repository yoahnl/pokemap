import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'map_workspace_visuals.dart';

enum SpatialTool { select, raise, lower, level, place }

class SpatialMapEditor extends StatefulWidget {
  const SpatialMapEditor({
    super.key,
    required this.document,
    required this.controller,
    required this.project,
    required this.visuals,
    required this.onChanged,
    required this.onResources,
  });
  final EditableMapDocument document;
  final MapWorkspaceController controller;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onChanged, onResources;
  @override
  State<SpatialMapEditor> createState() => _SpatialMapEditorState();
}

class _SpatialMapEditorState extends State<SpatialMapEditor> {
  final camera = SpatialSceneController();
  SpatialTool tool = SpatialTool.select;
  int level = 1, brush = 1, sequence = 0;
  String? modelId, selectedId, error;
  (int, int)? cell;
  MapSpatialScene get scene => widget.document.current.spatialScene!;
  bool get locked =>
      widget.document.saving ||
      widget.controller.catalogLocks(widget.document.base.mapId);
  @override
  void dispose() {
    camera.dispose();
    super.dispose();
  }

  static const operations = SpatialMapOperations();
  void edit(MapData next) {
    if (locked) return;
    widget.document.commit(next);
    setState(() => error = null);
    widget.onChanged();
  }

  void paint(int x, int z) {
    try {
      applyTool(x, z);
    } on FormatException {
      setState(
        () => error = 'Cette modification dépasse les limites de la carte.',
      );
    }
  }

  void applyTool(int x, int z) {
    setState(() => cell = (x, z));
    if (locked) return;
    if (tool == SpatialTool.select) {
      final found = scene.instances
          .where((i) => i.position.x.floor() == x && i.position.z.floor() == z)
          .toList();
      setState(() => selectedId = found.isEmpty ? null : found.last.id);
      return;
    }
    if (tool == SpatialTool.place) {
      final model = widget.project.models3d
          .where((m) => m.id == modelId)
          .firstOrNull;
      if (model == null) {
        setState(() => error = 'Choisissez un modèle dans la palette.');
        return;
      }
      final instance = SpatialModelInstance(
        id: 'object_${DateTime.now().microsecondsSinceEpoch}_${sequence++}',
        modelId: model.id,
        position: Model3dVector3(x: x + .5, y: scene.heightAt(x, z), z: z + .5),
      );
      edit(operations.upsertInstance(widget.document.current, instance));
      setState(() => selectedId = instance.id);
      return;
    }
    final cells = <SpatialCellLevel>[];
    final radius = brush ~/ 2;
    for (
      var pz = math.max(0, z - radius);
      pz <= math.min(scene.depth - 1, z + radius);
      pz++
    ) {
      for (
        var px = math.max(0, x - radius);
        px <= math.min(scene.width - 1, x + radius);
        px++
      ) {
        final index = pz * scene.width + px;
        final next = switch (tool) {
          SpatialTool.raise => math.min(32, scene.heightLevels[index] + 1),
          SpatialTool.lower => math.max(0, scene.heightLevels[index] - 1),
          _ => level,
        };
        cells.add(SpatialCellLevel(x: px, z: pz, level: next));
      }
    }
    edit(operations.setLevels(widget.document.current, cells));
  }

  void updateInstance(SpatialModelInstance instance) {
    edit(operations.upsertInstance(widget.document.current, instance));
  }

  Widget number(String label, double value, void Function(double) apply) =>
      StudioCommitField(
        label: label,
        value: value.toStringAsFixed(2),
        tryCommit: (raw) {
          final parsed = double.tryParse(raw.replaceAll(',', '.'));
          if (parsed == null || !parsed.isFinite) return false;
          try {
            apply(parsed);
            return true;
          } on Object {
            setState(
              () => error = 'Cette valeur dépasse les limites autorisées.',
            );
            return false;
          }
        },
      );

  @override
  Widget build(BuildContext context) {
    final visuals = widget.visuals;
    if (visuals is! SpatialWorkspaceVisuals) {
      return const StudioNotice(
        'Le rendu 3D est indisponible dans cette session.',
      );
    }
    final selected = scene.instances
        .where((i) => i.id == selectedId)
        .firstOrNull;
    final colors = Theme.of(context).colorScheme;
    final sidebar = SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioPanel(
            title: 'Construire la carte',
            children: [
              StudioSelect(
                label: 'Outil',
                value: tool.name,
                options: const {
                  'select': 'Sélectionner',
                  'raise': 'Monter d’un palier',
                  'lower': 'Descendre d’un palier',
                  'level': 'Aplanir à un niveau',
                  'place': 'Poser un modèle',
                },
                onChanged: locked
                    ? null
                    : (v) =>
                          setState(() => tool = SpatialTool.values.byName(v)),
              ),
              if (tool == SpatialTool.raise ||
                  tool == SpatialTool.lower ||
                  tool == SpatialTool.level) ...[
                const SizedBox(height: 12),
                StudioSelect(
                  label: 'Taille du pinceau',
                  value: '$brush',
                  options: const {
                    '1': '1 × 1 case',
                    '3': '3 × 3 cases',
                    '5': '5 × 5 cases',
                  },
                  onChanged: (v) => setState(() => brush = int.parse(v)),
                ),
                if (tool == SpatialTool.level) ...[
                  const SizedBox(height: 12),
                  StudioSelect(
                    label: 'Niveau du terrain',
                    value: '$level',
                    options: {for (var i = 0; i <= 32; i++) '$i': 'Niveau $i'},
                    onChanged: (v) => setState(() => level = int.parse(v)),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Cliquez sur les cases. Chaque palier a une hauteur fixe. Les objets conservent leur hauteur ; « Poser au sol » les ajuste au nouveau relief.',
                ),
              ],
              if (tool == SpatialTool.place) ...[
                const SizedBox(height: 12),
                if (widget.project.models3d.isEmpty)
                  const Text(
                    'Importez votre premier modèle dans les ressources.',
                  ),
                if (widget.project.models3d.isNotEmpty)
                  StudioSelect(
                    label: 'Modèle',
                    value: modelId,
                    options: {
                      for (final model in widget.project.models3d)
                        model.id: model.name,
                    },
                    onChanged: (v) => setState(() => modelId = v),
                  ),
                const SizedBox(height: 8),
                StudioButton(
                  label: 'Ouvrir les ressources',
                  secondary: true,
                  onPressed: widget.onResources,
                ),
              ],
              if (cell case final position?) ...[
                const SizedBox(height: 12),
                Text(
                  'Case ${position.$1}, ${position.$2} · niveau ${scene.heightLevels[position.$2 * scene.width + position.$1]}',
                ),
              ],
            ],
          ),
          if (scene.instances.isNotEmpty) ...[
            const SizedBox(height: 12),
            StudioSelect(
              label: 'Objets de la carte',
              value: selectedId,
              options: {
                for (final item in scene.instances)
                  item.id:
                      '${widget.project.models3d.where((m) => m.id == item.modelId).firstOrNull?.name ?? item.modelId} · ${item.position.x.toStringAsFixed(1)}, ${item.position.z.toStringAsFixed(1)}',
              },
              onChanged: (v) => setState(() {
                selectedId = v;
                tool = SpatialTool.select;
              }),
            ),
          ],
          if (selected != null) ...[
            const SizedBox(height: 12),
            IgnorePointer(
              ignoring: locked,
              child: StudioPanel(
                title: 'Objet sélectionné',
                children: [
                  number(
                    'X · position horizontale',
                    selected.position.x,
                    (v) => updateInstance(
                      selected.copyWith(
                        position: Model3dVector3(
                          x: v,
                          y: selected.position.y,
                          z: selected.position.z,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  number(
                    'Z · profondeur',
                    selected.position.z,
                    (v) => updateInstance(
                      selected.copyWith(
                        position: Model3dVector3(
                          x: selected.position.x,
                          y: selected.position.y,
                          z: v,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  number(
                    'Y · hauteur',
                    selected.position.y,
                    (v) => updateInstance(
                      selected.copyWith(
                        position: Model3dVector3(
                          x: selected.position.x,
                          y: v,
                          z: selected.position.z,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  number(
                    'Rotation en degrés',
                    selected.rotationDegrees,
                    (v) =>
                        updateInstance(selected.copyWith(rotationDegrees: v)),
                  ),
                  const SizedBox(height: 10),
                  number(
                    'Échelle',
                    selected.scale,
                    (v) => updateInstance(selected.copyWith(scale: v)),
                  ),
                  const SizedBox(height: 10),
                  StudioSelect(
                    label: 'Animation',
                    value: selected.animationIndex?.toString() ?? 'none',
                    options: {
                      'none': 'Pose de repos',
                      for (final clip
                          in widget.project.models3d
                                  .where((m) => m.id == selected.modelId)
                                  .firstOrNull
                                  ?.inspection
                                  .animations ??
                              <Model3dAnimation>[])
                        '${clip.index}': clip.name,
                    },
                    onChanged: (v) => updateInstance(
                      SpatialModelInstance(
                        id: selected.id,
                        modelId: selected.modelId,
                        position: selected.position,
                        rotationDegrees: selected.rotationDegrees,
                        scale: selected.scale,
                        blocksMovement: selected.blocksMovement,
                        animationIndex: int.tryParse(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StudioButton(
                    label: 'Poser au sol',
                    secondary: true,
                    onPressed: () => updateInstance(
                      selected.copyWith(
                        position: Model3dVector3(
                          x: selected.position.x,
                          y: scene.heightAt(
                            selected.position.x.floor(),
                            selected.position.z.floor(),
                          ),
                          z: selected.position.z,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StudioButton(
                    label: 'Retirer cet objet',
                    secondary: true,
                    onPressed: () {
                      edit(
                        operations.deleteInstance(
                          widget.document.current,
                          selected.id,
                        ),
                      );
                      setState(() => selectedId = null);
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          IgnorePointer(
            ignoring: locked,
            child: StudioPanel(
              title: 'Caméra du jeu · angle fixe',
              children: [
                number(
                  'Inclinaison en degrés',
                  scene.camera.pitchDegrees,
                  (v) => configureCamera(pitch: v),
                ),
                const SizedBox(height: 10),
                number(
                  'Orientation en degrés',
                  scene.camera.yawDegrees,
                  (v) => configureCamera(yaw: v),
                ),
                const SizedBox(height: 10),
                number(
                  'Champ de vision en degrés',
                  scene.camera.fieldOfViewDegrees,
                  (v) => configureCamera(fov: v),
                ),
                const SizedBox(height: 10),
                number(
                  'Distance',
                  scene.camera.distance,
                  (v) => configureCamera(distance: v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final view in SpatialEditorView.values)
                StudioButton(
                  label: switch (view) {
                    SpatialEditorView.orbit => 'Vue libre',
                    SpatialEditorView.top => 'Vue de dessus',
                    SpatialEditorView.game => 'Caméra du jeu',
                  },
                  secondary: camera.view != view,
                  onPressed: () => setState(() => camera.setView(view)),
                ),
              StudioButton(
                label: 'Recentrer',
                secondary: true,
                onPressed: camera.reset,
              ),
              StudioButton(
                label: 'Annuler',
                secondary: true,
                onPressed: locked || !widget.document.canUndo
                    ? null
                    : () {
                        widget.controller.restore(redo: false);
                        widget.onChanged();
                      },
              ),
              StudioButton(
                label: 'Rétablir',
                secondary: true,
                onPressed: locked || !widget.document.canRedo
                    ? null
                    : () {
                        widget.controller.restore(redo: true);
                        widget.onChanged();
                      },
              ),
            ],
          ),
        ),
        if (error != null) StudioNotice(error!, isError: true),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Cliquez pour utiliser l’outil · glissez pour tourner en vue libre · molette pour zoomer',
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final canvas = SpatialSceneView(
                selectedCell: cell,
                scene: scene,
                models: widget.project.models3d,
                loadModel: (visuals as SpatialWorkspaceVisuals).readModel,
                controller: camera,
                onCell: paint,
                background: colors.surfaceContainerLowest,
                ground: colors.primaryContainer,
                edge: colors.outlineVariant,
                errorBuilder: (_, failure) => Center(
                  child: StudioNotice(
                    'La scène ne peut pas être affichée : $failure',
                    isError: true,
                  ),
                ),
              );
              return bounds.maxWidth < 650
                  ? Column(
                      children: [
                        Expanded(child: canvas),
                        SizedBox(height: 210, child: sidebar),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: canvas),
                        SizedBox(width: 286, child: sidebar),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  void configureCamera({
    double? pitch,
    double? yaw,
    double? fov,
    double? distance,
  }) {
    final previous = scene.camera;
    edit(
      operations.configureCamera(
        widget.document.current,
        SpatialCameraProfile(
          pitchDegrees: pitch ?? previous.pitchDegrees,
          yawDegrees: yaw ?? previous.yawDegrees,
          fieldOfViewDegrees: fov ?? previous.fieldOfViewDegrees,
          distance: distance ?? previous.distance,
        ),
      ),
    );
  }
}
