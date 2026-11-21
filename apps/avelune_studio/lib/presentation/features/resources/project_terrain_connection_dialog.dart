import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/domain/project_terrain_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_terrain_connection_editor.dart';

export 'project_terrain_connection_editor.dart'
    show TerrainConnectionChoice, editableTerrainConnections;

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
  late var _pending = widget.editor.pendingReceipt;
  late String? _problem = _pending == null
      ? null
      : 'Les raccords sont enregistrés. Relisez la publication pour les afficher.';
  bool _working = false;

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
            if (pending == null)
              ProjectTerrainConnectionEditor(
                preset: _draft,
                project: widget.project,
                visuals: widget.visuals,
                connections: widget.connections,
                enabled: !_working,
                onChanged: (preset) => setState(() => _draft = preset),
              ),
            if (_problem case final problem?) ...[
              if (pending == null) const SizedBox(height: StudioSpacing.l),
              StudioNotice(problem, isError: pending == null),
            ],
          ],
        ),
      ),
    );
  }
}
