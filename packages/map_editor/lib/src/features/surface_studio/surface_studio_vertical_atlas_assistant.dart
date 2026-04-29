import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';

class SurfaceStudioVerticalAtlasAssistant extends StatelessWidget {
  const SurfaceStudioVerticalAtlasAssistant({
    super.key,
    required this.label,
    required this.subtle,
    this.draftTileWidth,
    this.draftTileHeight,
    this.draftColumns,
    this.draftRows,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_vertical_atlas_assistant');

  final Color label;
  final Color subtle;
  final int? draftTileWidth;
  final int? draftTileHeight;
  final int? draftColumns;
  final int? draftRows;

  @override
  material.Widget build(material.BuildContext context) {
    final ok = surfaceStudioAtlasGridOverlayDraftValid(
      draftTileWidth,
      draftTileHeight,
      draftColumns,
      draftRows,
    );
    final tw = draftTileWidth;
    final th = draftTileHeight;
    final cols = draftColumns;
    final rows = draftRows;

    final children = <material.Widget>[
      material.Text(
        'Assistant atlas vertical',
        style: material.TextStyle(
          color: label,
          fontSize: 12,
          fontWeight: material.FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      const material.SizedBox(height: 6),
      material.Text(
        'Colonnes = variantes visuelles',
        style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
      ),
      material.Text(
        'Lignes = frames d’animation',
        style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
      ),
      const material.SizedBox(height: 6),
      material.Text(
        'Votre atlas ressemble à un atlas vertical animé.',
        style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
      ),
      material.Text(
        'Chaque colonne peut représenter une variante de surface.',
        style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
      ),
      material.Text(
        'Chaque ligne peut représenter une frame d’animation.',
        style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
      ),
    ];

    if (!ok) {
      children.add(const material.SizedBox(height: 6));
      children.add(
        material.Text(
          'Indiquez largeur et hauteur de tuile, colonnes et lignes valides pour afficher les détections.',
          style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
        ),
      );
    } else if (cols == 1 && rows == 1) {
      children.add(const material.SizedBox(height: 6));
      children.add(
        material.Text(
          'Atlas simple : aucune structure animée détectée.',
          style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
        ),
      );
    } else if (cols != null &&
        rows != null &&
        tw != null &&
        th != null &&
        cols >= 2 &&
        rows >= 2) {
      final total = cols * rows;
      children.add(const material.SizedBox(height: 6));
      children.add(
        material.Text(
          'Variantes détectées : $cols colonnes',
          style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
        ),
      );
      children.add(
        material.Text(
          'Frames détectées : $rows lignes',
          style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
        ),
      );
      children.add(
        material.Text(
          'Total : $total tuiles',
          style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
        ),
      );
      children.add(
        material.Text(
          'Taille de tuile : $tw×$th px',
          style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
        ),
      );
      if (rows > cols) {
        children.add(const material.SizedBox(height: 4));
        children.add(
          material.Text(
            'Structure probablement verticale : plusieurs frames par variante.',
            style:
                material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
          ),
        );
      } else if (cols > rows) {
        children.add(const material.SizedBox(height: 4));
        children.add(
          material.Text(
            'Structure probablement horizontale ou non standard.',
            style:
                material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
          ),
        );
      }
    }

    return material.Container(
      key: sectionKey,
      padding:
          const material.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: material.BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: material.BorderRadius.circular(10),
        border: material.Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
