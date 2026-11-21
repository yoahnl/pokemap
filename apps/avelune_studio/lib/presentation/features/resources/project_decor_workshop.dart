import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/decors/application/decor_source_support.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/resource_preview_source.dart';
import '../../../features/resources/domain/project_decor_workshop_port.dart';

class ProjectDecorWorkshop extends StatefulWidget {
  const ProjectDecorWorkshop({
    super.key,
    required this.id,
    required this.load,
    required this.visuals,
    required this.onBack,
    this.edit,
  });

  final String id;
  final Future<ProjectDecorWorkshopRead> Function() load;
  final MapWorkspaceVisuals? visuals;
  final VoidCallback onBack;
  final Future<bool> Function(ProjectDecorWorkshopRead)? edit;

  @override
  State<ProjectDecorWorkshop> createState() => _ProjectDecorWorkshopState();
}

class _ProjectDecorWorkshopState extends State<ProjectDecorWorkshop> {
  late var _reading = Future.sync(widget.load);

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(StudioSpacing.xl),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: StudioButton(
          label: 'Retour à la bibliothèque',
          icon: Icons.arrow_back,
          variant: StudioButtonVariant.quiet,
          onPressed: widget.onBack,
        ),
      ),
      const SizedBox(height: StudioSpacing.l),
      FutureBuilder<ProjectDecorWorkshopRead>(
        future: _reading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Chargement du décor',
              ),
            );
          }
          if (snapshot.hasError) {
            return StudioEmptyState(
              title: 'Impossible de lire le décor',
              action: StudioButton(
                label: 'Réessayer',
                onPressed: () =>
                    setState(() => _reading = Future.sync(widget.load)),
              ),
            );
          }
          final read = snapshot.data!;
          final element = read.project.elements
              .where((entry) => entry.id == widget.id)
              .firstOrNull;
          if (element == null) {
            return const StudioEmptyState(title: 'Décor introuvable');
          }
          return _decor(read, element);
        },
      ),
    ],
  );

  Widget _decor(ProjectDecorWorkshopRead read, ProjectElementEntry element) {
    final tileset = read.project.tilesets
        .where((entry) => entry.id == element.tilesetId)
        .firstOrNull;
    final visuals = widget.visuals;
    final edit = widget.edit;
    final problem = decorWorkshopProblem(read.project, tileset, element);
    return StudioPanel(
      title: element.name,
      children: [
        if (visuals is ScopedResourcePreviewVisuals)
          SizedBox(
            height: 180,
            child: (visuals as ScopedResourcePreviewVisuals)
                .scopedResourcePreview(
                  ElementPreviewSource(element),
                  read.project,
                  size: 180,
                ),
          ),
        if (tileset != null) Text(tileset.name),
        if (element.frames.length > 1)
          Text('${element.frames.length} images d’animation'),
        if (element.collisionProfile case final collision?
            when collision.cells.isNotEmpty || collision.collisionMask != null)
          const Text('Collision personnalisée'),
        if (problem != null)
          StudioNotice(problem)
        else if (edit != null)
          StudioButton(
            label: 'Modifier le décor',
            icon: Icons.edit_outlined,
            onPressed: () async {
              final changed = await edit(read);
              if (changed && mounted) {
                setState(() => _reading = Future.sync(widget.load));
              }
            },
          )
        else
          const StudioBadge('Lecture seule', icon: Icons.lock_outline),
      ],
    );
  }
}

String? decorWorkshopProblem(
  ProjectManifest project,
  ProjectTilesetEntry? tileset,
  ProjectElementEntry? element,
) {
  if (tileset == null) return 'La planche source est indisponible.';
  if (element?.frames.isEmpty == true) {
    return 'Ce décor ne possède aucune image.';
  }
  if (element?.frames.any(
        (frame) => frame.tilesetId.isNotEmpty && frame.tilesetId != tileset.id,
      ) ==
      true) {
    return 'Ce décor utilise plusieurs planches. Ses réglages restent en lecture seule.';
  }
  return decorConversionProblem(tileset, project);
}
