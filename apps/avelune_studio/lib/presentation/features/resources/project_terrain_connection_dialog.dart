import 'dart:math' as math;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/resource_catalog.dart';
import '../../../features/resources/application/resource_preview_source.dart';
import '../../../features/resources/application/resource_terrain_example.dart';
import '../../../features/resources/domain/project_terrain_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_library_resource_art.dart';

typedef TerrainConnectionChoice = ({
  int ruleIndex,
  String label,
  TerrainFrameGrid grid,
});

List<TerrainConnectionChoice> editableTerrainConnections(
  ProjectManifest project,
  ProjectSmartTilePreset preset,
) {
  if (preset.status != SmartTilePresetStatus.published) return const [];
  final example = terrainConnectionExampleCells(project, preset);
  if (example == null) return const [];
  final labels = <String, String>{};
  const positions = [
    'Angle haut gauche',
    'Bord haut',
    'Angle haut droit',
    'Bord gauche',
    'Centre',
    'Bord droit',
    'Angle bas gauche',
    'Bord bas',
    'Angle bas droit',
  ];
  for (final index in const [4, 0, 1, 2, 3, 5, 6, 7, 8]) {
    labels.putIfAbsent(example[index].ruleId, () => positions[index]);
  }
  final choices = <TerrainConnectionChoice>[];
  for (final (index, rule) in preset.rules.indexed) {
    final label = labels[rule.id];
    final candidate = rule.candidates.singleOrNull;
    final part = candidate?.parts.singleOrNull;
    if (label == null || part == null) continue;
    final grid = terrainFrameGrid(project, part);
    if (grid == null) continue;
    choices.add((
      ruleIndex: index,
      label: candidate!.label.trim().isEmpty ? label : candidate.label,
      grid: grid,
    ));
  }
  final order = labels.keys.toList(growable: false);
  choices.sort(
    (a, b) => order
        .indexOf(preset.rules[a.ruleIndex].id)
        .compareTo(order.indexOf(preset.rules[b.ruleIndex].id)),
  );
  return choices;
}

class ProjectTerrainConnectionDialog extends StatefulWidget {
  const ProjectTerrainConnectionDialog({
    super.key,
    required this.preset,
    required this.project,
    required this.visuals,
    required this.connections,
    required this.editor,
    required this.revision,
  });

  final ProjectSmartTilePreset preset;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final List<TerrainConnectionChoice> connections;
  final ProjectTerrainWorkshopEditor editor;
  final String revision;

  @override
  State<ProjectTerrainConnectionDialog> createState() =>
      _ProjectTerrainConnectionDialogState();
}

class _ProjectTerrainConnectionDialogState
    extends State<ProjectTerrainConnectionDialog> {
  late var _draft = widget.preset;
  int _connection = 0;
  late var _pending = widget.editor.pendingReceipt;
  late String? _problem = _pending == null
      ? null
      : 'Les raccords sont enregistrés. Relisez la publication pour les afficher.';
  bool _working = false;

  void _pick(int ruleIndex, SmartTileFrameRef frame) {
    final rules = _draft.rules.toList();
    final rule = rules[ruleIndex];
    final candidate = rule.candidates.single;
    rules[ruleIndex] = rule.copyWith(
      candidates: [
        candidate.copyWith(
          parts: [
            candidate.parts.single.copyWith(
              source: SmartTileVisualSource.frame(frame: frame),
            ),
          ],
        ),
      ],
    );
    setState(() => _draft = _draft.copyWith(rules: rules));
  }

  Future<void> _publish() async {
    if (_working) return;
    setState(() {
      _working = true;
      _problem = null;
    });
    final editor = widget.editor;
    try {
      var receipt = _pending;
      if (receipt != null) {
        await editor.reconcile(receipt);
      } else {
        receipt = await editor.publish(_draft, widget.revision);
      }
      editor.onPendingReceiptChanged(null);
      if (mounted) Navigator.of(context).pop(receipt);
    } on Object catch (error) {
      final partial = error is ResourceFailure ? error.partialReceipt : null;
      if (partial != null) editor.onPendingReceiptChanged(partial);
      if (!mounted) return;
      setState(() {
        _pending = partial ?? _pending;
        _problem = error is ResourceFailure
            ? error.message
            : 'Les raccords n’ont pas pu être publiés.';
      });
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return PopScope(
      canPop: !_working,
      child: StudioReviewDialog(
        title: 'Modifier les raccords',
        confirmLabel: _working
            ? 'En cours…'
            : pending != null
            ? 'Relire la publication'
            : 'Publier',
        onConfirmed: !_working && (pending != null || _draft != widget.preset)
            ? _publish
            : null,
        cancelLabel: pending == null ? 'Annuler' : 'Fermer',
        onCancelled: _working ? null : () => Navigator.of(context).pop(),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pending == null) _editor(context),
            if (_problem case final problem?) ...[
              if (pending == null) const SizedBox(height: StudioSpacing.l),
              StudioNotice(problem, isError: pending == null),
            ],
          ],
        ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final connections = widget.connections;
    final choice = connections[_connection];
    final styles = Theme.of(context).textTheme;
    final tiles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tuiles de la planche', style: styles.titleSmall),
        const SizedBox(height: StudioSpacing.s),
        _tiles(choice),
      ],
    );
    final preview = Column(
      children: [
        Text('Aperçu après modification', style: styles.titleSmall),
        const SizedBox(height: StudioSpacing.s),
        ProjectLibraryResourceArt(
          key: const ValueKey('terrain-draft-preview'),
          item: ResourceItem(
            id: _draft.id,
            name: _draft.name,
            kind: ResourceKind.terrains,
            terrain: _draft,
          ),
          project: widget.project,
          visuals: widget.visuals,
          size: 144,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Raccord',
          value: '$_connection',
          options: {
            for (final (index, connection) in connections.indexed)
              '$index': connection.label,
          },
          onChanged: _working
              ? null
              : (value) => setState(() => _connection = int.parse(value)),
        ),
        const SizedBox(height: StudioSpacing.l),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 480
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: tiles),
                    const SizedBox(width: StudioSpacing.l),
                    preview,
                  ],
                )
              : Column(
                  children: [
                    preview,
                    const SizedBox(height: StudioSpacing.l),
                    tiles,
                  ],
                ),
        ),
      ],
    );
  }

  Widget _tiles(TerrainConnectionChoice choice) {
    final (:ruleIndex, :grid, label: _) = choice;
    final (:atlas, :source, frame: _) = grid;
    final frame =
        (_draft.rules[ruleIndex].candidates.single.parts.single.source
                as SmartTileFrameSource)
            .frame;
    final columns = math.min(atlas.columns, source.columns);
    final rows = math.min(atlas.rows, source.rows);
    final visuals = widget.visuals;
    return SizedBox(
      height: 212,
      child: GridView.builder(
        key: ValueKey(ruleIndex),
        primary: false,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 232,
          mainAxisExtent: 64,
          crossAxisSpacing: StudioSpacing.s,
        ),
        itemCount: rows * columns,
        itemBuilder: (context, index) {
          final row = index ~/ columns;
          final column = index % columns;
          final tile = TileLayerPaletteEntry(
            tilesetId: atlas.tilesetId,
            localTileId: regularAtlasLocalTileId(
              row: row,
              column: column,
              source: source,
            ),
          );
          return StudioChoice(
            label: 'Ligne ${row + 1} · colonne ${column + 1}',
            selected: row == frame.row && column == frame.column,
            selectionAccent: true,
            leading: visuals is ScopedResourcePreviewVisuals
                ? (visuals as ScopedResourcePreviewVisuals)
                      .scopedResourcePreview(
                        TileFramePreviewSource(tile),
                        widget.project,
                        size: 28,
                      )
                : visuals.tileThumbnail(tile, size: 28),
            onTap: _working
                ? null
                : () => _pick(
                    ruleIndex,
                    frame.copyWith(row: row, column: column),
                  ),
          );
        },
      ),
    );
  }
}
