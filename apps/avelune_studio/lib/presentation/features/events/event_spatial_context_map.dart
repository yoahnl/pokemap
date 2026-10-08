import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../map_workspace/studio_spatial_map_preview.dart';
import 'event_labels.dart';

class EventSpatialContextMap extends StatefulWidget {
  const EventSpatialContextMap({
    super.key,
    required this.map,
    required this.project,
    required this.visuals,
    this.source,
    this.chooseKind,
    this.selectableSources,
    this.onChoose,
    this.onCancel,
  });
  final MapData map;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final NarrativeEventSourceRef? source;
  final NarrativeEventSourceKind? chooseKind;
  final Set<NarrativeEventSourceRef>? selectableSources;
  final ValueChanged<NarrativeEventSourceRef>? onChoose;
  final VoidCallback? onCancel;
  @override
  State<EventSpatialContextMap> createState() => _EventSpatialContextMapState();
}

class _EventSpatialContextMapState extends State<EventSpatialContextMap> {
  final _camera = SpatialSceneController()..setView(SpatialEditorView.game);
  bool selectable(NarrativeEventSourceRef source) =>
      widget.selectableSources?.contains(source) ?? true;

  void accept(NarrativeEventSourceRef source) {
    if (widget.chooseKind == source.kind && selectable(source)) {
      widget.onChoose?.call(source);
    }
  }

  Map<String, String> get models => {
    for (final instance in widget.map.spatialScene!.instances)
      if (selectable(
        NarrativeEventSourceRef.modelInteract(widget.map.id, instance.id),
      ))
        instance.id:
            '${widget.project.models3d.where((model) => model.id == instance.modelId).firstOrNull?.name ?? 'Ressource absente'} · (${instance.position.x.toStringAsFixed(1)}, ${instance.position.z.toStringAsFixed(1)})',
  };

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = eventTargetId(widget.source);
    final model = widget.source?.kind == NarrativeEventSourceKind.modelInteract
        ? widget.map.spatialScene!.instances
              .where((instance) => instance.id == id)
              .firstOrNull
        : null;
    final color = Theme.of(context).colorScheme.primary;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            widget.onCancel?.call(),
      },
      child: Focus(
        autofocus: widget.chooseKind != null,
        child: StudioGraphCard(
          child: Column(
            children: [
              if (widget.chooseKind == NarrativeEventSourceKind.modelInteract)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: StudioSelect(
                    label: 'Décor 3D à utiliser',
                    value: model?.id,
                    options: models,
                    onChanged: (value) => accept(
                      NarrativeEventSourceRef.modelInteract(
                        widget.map.id,
                        value,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: StudioSpatialMapPreview(
                        map: widget.map,
                        project: widget.project,
                        visuals: widget.visuals,
                        controller: _camera,
                        selectedContent: model == null
                            ? null
                            : SpatialSceneContentHit(
                                kind: SpatialSceneContentKind.model,
                                id: model.id,
                                cell: (
                                  model.position.x.floor(),
                                  model.position.z.floor(),
                                ),
                              ),
                        selectContent:
                            widget.chooseKind ==
                                NarrativeEventSourceKind.modelInteract ||
                            widget.chooseKind ==
                                NarrativeEventSourceKind.entityInteract,
                        onContent: (hit) {
                          if (hit.kind == SpatialSceneContentKind.model) {
                            accept(
                              NarrativeEventSourceRef.modelInteract(
                                widget.map.id,
                                hit.id,
                              ),
                            );
                          }
                          if (hit.kind == SpatialSceneContentKind.actor &&
                              hit.id.startsWith('npc:')) {
                            accept(
                              NarrativeEventSourceRef.entityInteract(
                                widget.map.id,
                                hit.id.substring(4),
                              ),
                            );
                          }
                        },
                        onCell: (x, z) {
                          if (widget.chooseKind ==
                              NarrativeEventSourceKind.mapEnter) {
                            accept(
                              NarrativeEventSourceRef.mapEnter(widget.map.id),
                            );
                          }
                          if (widget.chooseKind ==
                              NarrativeEventSourceKind.entityInteract) {
                            for (final entity in widget.map.entities) {
                              if (x >= entity.pos.x &&
                                  z >= entity.pos.y &&
                                  x < entity.pos.x + entity.size.width &&
                                  z < entity.pos.y + entity.size.height) {
                                accept(
                                  NarrativeEventSourceRef.entityInteract(
                                    widget.map.id,
                                    entity.id,
                                  ),
                                );
                                break;
                              }
                            }
                          }
                          if (widget.chooseKind ==
                              NarrativeEventSourceKind.triggerEnter) {
                            for (final trigger in widget.map.triggers) {
                              if (x >= trigger.area.pos.x &&
                                  z >= trigger.area.pos.y &&
                                  x <
                                      trigger.area.pos.x +
                                          trigger.area.size.width &&
                                  z <
                                      trigger.area.pos.y +
                                          trigger.area.size.height) {
                                accept(
                                  NarrativeEventSourceRef.triggerEnter(
                                    widget.map.id,
                                    trigger.id,
                                  ),
                                );
                                break;
                              }
                            }
                          }
                        },
                        overlays: [
                          if (widget.chooseKind ==
                              NarrativeEventSourceKind.entityInteract)
                            for (final entity in widget.map.entities)
                              if (selectable(
                                NarrativeEventSourceRef.entityInteract(
                                  widget.map.id,
                                  entity.id,
                                ),
                              ))
                                SpatialCellOverlay(
                                  id: entity.id,
                                  cell: (entity.pos.x, entity.pos.y),
                                  kind: SpatialCellOverlayKind.preview,
                                  color: color,
                                ),
                          if (widget.chooseKind ==
                                  NarrativeEventSourceKind.triggerEnter ||
                              widget.source?.kind ==
                                  NarrativeEventSourceKind.triggerEnter)
                            for (final trigger in widget.map.triggers)
                              if (widget.chooseKind ==
                                      NarrativeEventSourceKind.triggerEnter
                                  ? selectable(
                                      NarrativeEventSourceRef.triggerEnter(
                                        widget.map.id,
                                        trigger.id,
                                      ),
                                    )
                                  : trigger.id == id)
                                for (
                                  var x = trigger.area.pos.x;
                                  x <
                                      trigger.area.pos.x +
                                          trigger.area.size.width;
                                  x++
                                )
                                  for (
                                    var z = trigger.area.pos.y;
                                    z <
                                        trigger.area.pos.y +
                                            trigger.area.size.height;
                                    z++
                                  )
                                    SpatialCellOverlay(
                                      id: '${trigger.id}:$x:$z',
                                      cell: (x, z),
                                      kind: SpatialCellOverlayKind.preview,
                                      color: color,
                                    ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Wrap(
                        spacing: 4,
                        children: [
                          StudioTool(
                            label: 'Réduire la carte',
                            icon: Icons.remove,
                            onPressed: () => _camera.dolly(220),
                          ),
                          StudioTool(
                            label: 'Agrandir la carte',
                            icon: Icons.add,
                            onPressed: () => _camera.dolly(-220),
                          ),
                          StudioTool(
                            label: 'Cadrer la carte',
                            icon: Icons.fit_screen,
                            onPressed: _camera.reset,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
