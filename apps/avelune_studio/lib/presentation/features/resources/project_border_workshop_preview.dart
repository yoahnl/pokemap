import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/border_workshop_visuals.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/border_workshop_assembly.dart';

class ProjectBorderWorkshopPreview extends StatelessWidget {
  const ProjectBorderWorkshopPreview({
    super.key,
    required this.assembly,
    required this.visuals,
  });

  final BorderWorkshopAssembly assembly;
  final MapWorkspaceVisuals? visuals;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final preview = _preview();
      final pieces = _pieces(context);
      if (pieces == null) return preview;
      if (bounds.maxWidth >= 680) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: preview),
            const SizedBox(width: StudioSpacing.l),
            Expanded(flex: 2, child: pieces),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          preview,
          const SizedBox(height: StudioSpacing.l),
          pieces,
        ],
      );
    },
  );

  Widget _preview() {
    final provider = visuals;
    final map = assembly.map;
    final Widget content;
    if (assembly.issue case final issue?) {
      final (title, description) = _issueText(issue);
      content = StudioEmptyState(
        title: title,
        description: description,
        icon: Icons.info_outline,
      );
    } else if (provider is BorderWorkshopVisuals && map != null) {
      content = (provider as BorderWorkshopVisuals).borderAssemblyPreview(
        map,
        assembly.project,
      );
    } else {
      content = const StudioEmptyState(
        title: 'Rendu indisponible',
        description: 'Les pièces sélectionnées pour le tracé restent visibles.',
        icon: Icons.image_not_supported_outlined,
      );
    }
    return StudioPanel(
      title: 'Tracé d’essai',
      icon: Icons.gesture,
      children: [
        StudioAssetPreview(height: 288, checkerboard: false, child: content),
      ],
    );
  }

  Widget? _pieces(BuildContext context) {
    final pieces = assembly.pieces;
    final used = assembly.map != null;
    if (pieces.isEmpty && !used) return null;
    final theme = Theme.of(context);
    return StudioPanel(
      title: used ? 'Pièces utilisées' : 'Pièces configurées',
      icon: Icons.layers_outlined,
      children: [
        if (pieces.isEmpty)
          const Text('Ce tracé utilise le sol de la bordure.'),
        for (final (index, piece) in pieces.indexed) ...[
          if (index > 0) const Divider(height: StudioSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(piece.name, style: theme.textTheme.titleSmall),
                    Text(
                      borderWorkshopRoleLabel(piece.role),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (piece.placements case final count?) ...[
                const SizedBox(width: StudioSpacing.s),
                StudioBadge('× $count'),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

(String, String) _issueText(BorderWorkshopIssue issue) => switch (issue) {
  BorderWorkshopIssue.empty => (
    'Aucune pièce active',
    'Ajoutez au moins une pièce à cette bordure.',
  ),
  BorderWorkshopIssue.missingRoles => (
    'Pièces manquantes',
    'La ligne a besoin de ses segments, de ses extrémités et de ses angles si le tracé peut tourner.',
  ),
  BorderWorkshopIssue.missingSources => (
    'Modèles introuvables',
    'Vérifiez les modèles associés aux pièces de cette bordure.',
  ),
  BorderWorkshopIssue.unsupportedConfiguration => (
    'Tracé d’essai indisponible',
    'Vérifiez les orientations, les raccords et les réglages des pièces.',
  ),
  BorderWorkshopIssue.mapScope => (
    'Pièces réservées à des cartes différentes',
    'Utilisez des pièces disponibles sur une même carte pour assembler la bordure.',
  ),
  BorderWorkshopIssue.spriteDraft => (
    'Aperçu du brouillon 2D indisponible',
    'L’assemblage 2D utilise les images générées à la publication.',
  ),
  BorderWorkshopIssue.noSample => (
    'Assemblage indisponible',
    'Vérifiez les pièces et leurs réglages pour générer un tracé.',
  ),
};

String borderWorkshopRoleLabel(BorderPrimitiveRole role) => switch (role) {
  BorderPrimitiveRole.structureLarge => 'Structure principale',
  BorderPrimitiveRole.structureMedium => 'Structure intermédiaire',
  BorderPrimitiveRole.filler => 'Complément',
  BorderPrimitiveRole.accent => 'Détail',
  BorderPrimitiveRole.post => 'Poteau',
  BorderPrimitiveRole.span => 'Travée',
  BorderPrimitiveRole.surfacePatch => 'Surface',
  BorderPrimitiveRole.outerAccent => 'Détail extérieur',
  BorderPrimitiveRole.lineCap => 'Extrémité',
  BorderPrimitiveRole.lineStraight => 'Segment droit',
  BorderPrimitiveRole.lineCorner => 'Angle',
};
