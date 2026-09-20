import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import 'event_labels.dart';

class EventContextMap extends StatefulWidget {
  const EventContextMap({
    super.key,
    required this.map,
    required this.project,
    required this.visuals,
    required this.transform,
    this.source,
    this.chooseKind,
    this.selectableSources,
    this.onChoose,
    this.onCancel,
  });
  final MapData map;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final TransformationController transform;
  final NarrativeEventSourceRef? source;
  final NarrativeEventSourceKind? chooseKind;
  final Set<NarrativeEventSourceRef>? selectableSources;
  final ValueChanged<NarrativeEventSourceRef>? onChoose;
  final VoidCallback? onCancel;

  @override
  State<EventContextMap> createState() => _EventContextMapState();
}

class _EventContextMapState extends State<EventContextMap> {
  bool _fit = false;
  bool _pan = false;
  Size? _viewport;
  double get cellWidth =>
      widget.project.settings.tileWidth *
      widget.project.settings.displayScale.toDouble();
  double get cellHeight =>
      widget.project.settings.tileHeight *
      widget.project.settings.displayScale.toDouble();
  bool _selectable(NarrativeEventSourceRef source) =>
      widget.selectableSources?.contains(source) ?? true;
  void _zoom(double factor) {
    final current = widget.transform.value.getColumn(0).length;
    final target = (current * factor).clamp(.15, 8.0);
    widget.transform.value = widget.transform.value.clone()
      ..scaleByDouble(target / current, target / current, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.map;
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final previous = _viewport;
        _viewport = viewport;
        if (previous != null && previous != viewport) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _viewport != viewport) return;
            final matrix = widget.transform.value.clone();
            matrix.setEntry(
              0,
              3,
              matrix.entry(0, 3) + (viewport.width - previous.width) / 2,
            );
            matrix.setEntry(
              1,
              3,
              matrix.entry(1, 3) + (viewport.height - previous.height) / 2,
            );
            widget.transform.value = matrix;
          });
        }
        final size = Size(
          map.size.width * cellWidth,
          map.size.height * cellHeight,
        );
        void fit() {
          final scale = math
              .min(
                constraints.maxWidth / size.width,
                constraints.maxHeight / size.height,
              )
              .clamp(.15, 8.0);
          widget.transform.value = Matrix4.identity()
            ..translateByDouble(
              (constraints.maxWidth - size.width * scale) / 2,
              (constraints.maxHeight - size.height * scale) / 2,
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
        }

        if (!_fit) {
          _fit = true;
          if (widget.transform.value == Matrix4.identity()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) fit();
            });
          }
        }
        final targets = <(String, Rect, NarrativeEventSourceRef)>[
          if (widget.chooseKind == NarrativeEventSourceKind.entityInteract ||
              (widget.chooseKind == null &&
                  eventMapId(widget.source) == map.id &&
                  widget.source?.kind ==
                      NarrativeEventSourceKind.entityInteract))
            for (final entity in map.entities)
              if (widget.chooseKind == NarrativeEventSourceKind.entityInteract
                  ? _selectable(
                      NarrativeEventSourceRef.entityInteract(map.id, entity.id),
                    )
                  : entity.id == eventTargetId(widget.source))
                (
                  entity.name,
                  Rect.fromLTWH(
                    entity.pos.x * cellWidth,
                    entity.pos.y * cellHeight,
                    cellWidth,
                    cellHeight,
                  ),
                  NarrativeEventSourceRef.entityInteract(map.id, entity.id),
                ),
          if (widget.chooseKind == NarrativeEventSourceKind.triggerEnter ||
              (widget.chooseKind == null &&
                  eventMapId(widget.source) == map.id &&
                  widget.source?.kind == NarrativeEventSourceKind.triggerEnter))
            for (final trigger in map.triggers)
              if (widget.chooseKind == NarrativeEventSourceKind.triggerEnter
                  ? _selectable(
                      NarrativeEventSourceRef.triggerEnter(map.id, trigger.id),
                    )
                  : trigger.id == eventTargetId(widget.source))
                (
                  trigger.name,
                  Rect.fromLTWH(
                    trigger.area.pos.x * cellWidth,
                    trigger.area.pos.y * cellHeight,
                    trigger.area.size.width * cellWidth,
                    trigger.area.size.height * cellHeight,
                  ),
                  NarrativeEventSourceRef.triggerEnter(map.id, trigger.id),
                ),
        ];
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                widget.onCancel?.call(),
          },
          child: Focus(
            autofocus: widget.chooseKind != null,
            child: StudioGraphCard(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: InteractiveViewer(
                        key: const ValueKey('event-context-viewport'),
                        transformationController: widget.transform,
                        constrained: false,
                        alignment: Alignment.topLeft,
                        minScale: .15,
                        maxScale: 8,
                        boundaryMargin: const EdgeInsets.all(300),
                        panEnabled: widget.chooseKind == null || _pan,
                        child: GestureDetector(
                          onTapUp:
                              widget.chooseKind ==
                                      NarrativeEventSourceKind.mapEnter &&
                                  !_pan &&
                                  _selectable(
                                    NarrativeEventSourceRef.mapEnter(map.id),
                                  )
                              ? (_) => widget.onChoose?.call(
                                  NarrativeEventSourceRef.mapEnter(map.id),
                                )
                              : null,
                          child: SizedBox(
                            width: size.width,
                            height: size.height,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: widget.visuals.canvas(map),
                                ),
                                for (final target in targets)
                                  Positioned.fromRect(
                                    rect: target.$2.inflate(2),
                                    child: Tooltip(
                                      message: target.$1,
                                      child: GestureDetector(
                                        key: ValueKey(
                                          'event-target:${eventTargetId(target.$3)}',
                                        ),
                                        behavior: HitTestBehavior.opaque,
                                        onTap:
                                            widget.chooseKind != null && !_pan
                                            ? () => widget.onChoose?.call(
                                                target.$3,
                                              )
                                            : null,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: colors.primary,
                                              width: 2,
                                            ),
                                            color: colors.primary.withValues(
                                              alpha: .16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        if (widget.chooseKind != null) ...[
                          StudioTool(
                            label: 'Choisir une cible',
                            icon: Icons.near_me_outlined,
                            selected: !_pan,
                            onPressed: () => setState(() => _pan = false),
                          ),
                          const SizedBox(width: 4),
                          StudioTool(
                            label: 'Déplacer l’aperçu',
                            icon: Icons.pan_tool_outlined,
                            selected: _pan,
                            onPressed: () => setState(() => _pan = true),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        StudioTool(
                          label: 'Réduire le contexte',
                          icon: Icons.remove,
                          onPressed: () => _zoom(.8),
                        ),
                        const SizedBox(width: 4),
                        StudioTool(
                          label: 'Agrandir le contexte',
                          icon: Icons.add,
                          onPressed: () => _zoom(1.25),
                        ),
                        const SizedBox(width: 4),
                        StudioTool(
                          label: 'Cadrer la carte',
                          icon: Icons.fit_screen,
                          onPressed: fit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
