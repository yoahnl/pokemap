// Surface Studio — navigateur de catalogue lecture seule (Lot 54).
//
// Consomme uniquement [SurfaceStudioReadModel] (Lot 51) : pas de
// re-calcul de diagnostics, pas de JSON, pas de fichier, pas de mutation
// de manifest, pas d’I/O, pas d’état mutable.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Libellés visibles (aucun nom de type Dart interne).
class SurfaceStudioCatalogBrowserLabels {
  const SurfaceStudioCatalogBrowserLabels._();

  static const String title = 'Catalogue Surface';
  static const String emptyGlobal = 'Le catalogue Surface est vide';
  static const String emptyGlobalHint =
      'Les prochains lots permettront d’ajouter des atlas, des animations et des presets.';
  static const String sectionAtlas = 'Atlas';
  static const String sectionAnimations = 'Animations';
  static const String sectionPresets = 'Presets';
  static const String emptyAtlas = 'Aucun atlas Surface';
  static const String emptyAnimations = 'Aucune animation Surface';
  static const String emptyPresets = 'Aucun preset Surface';

  static const String labelId = 'Identifiant';
  static const String labelTileset = 'Tileset';
  static const String labelTile = 'Tile';
  static const String labelGrid = 'Grille';
  static const String labelLayout = 'Layout';
  static const String labelUsedBy = 'Utilisé par';

  static const String labelFrames = 'Frames';
  static const String labelTotalDuration = 'Durée totale';
  static const String labelRefAtlases = 'Atlas référencés';
  static const String labelSync = 'Groupe de synchronisation';
  static const String labelCategory = 'Catégorie';

  static const String labelVariants = 'Variantes';
  static const String labelRoles = 'Rôles';
  static const String labelPresetAnimationRefs = 'Animations liées';
  static const String labelCoverage = 'Couverture standard';
  static const String coverageFull = 'Rôles standards complets';
  static const String coveragePartial = 'Rôles standards incomplets';

  static const String notUsed = 'Non utilisé';

  static String usedByAnimations(int n) {
    if (n <= 0) {
      return notUsed;
    }
    if (n == 1) {
      return 'Utilisé par 1 animation';
    }
    return 'Utilisé par $n animations';
  }

  static String frameLabel(int n) {
    if (n <= 1) {
      return '1 frame';
    }
    return '$n frames';
  }

  static String variantLabel(int n) {
    if (n <= 1) {
      return '1 variante';
    }
    return '$n variantes';
  }
}

/// Navigateur de catalogue **lecture seule** : seules les listes et champs
/// dérivés du [SurfaceStudioReadModel] sont affichés (ordre source).
class SurfaceStudioCatalogBrowser extends StatelessWidget {
  const SurfaceStudioCatalogBrowser({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioCatalogBrowserLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.isEmpty) ...[
          Text(
            SurfaceStudioCatalogBrowserLabels.emptyGlobal,
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioCatalogBrowserLabels.emptyGlobalHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _SectionHeader(
          title: SurfaceStudioCatalogBrowserLabels.sectionAtlas,
          subtle: subtle,
        ),
        const SizedBox(height: 8),
        if (readModel.atlases.isEmpty)
          _EmptyLine(
            text: SurfaceStudioCatalogBrowserLabels.emptyAtlas,
            subtle: subtle,
          )
        else
          ...readModel.atlases.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AtlasCard(row: row, label: label),
            ),
          ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: SurfaceStudioCatalogBrowserLabels.sectionAnimations,
          subtle: subtle,
        ),
        const SizedBox(height: 8),
        if (readModel.animations.isEmpty)
          _EmptyLine(
            text: SurfaceStudioCatalogBrowserLabels.emptyAnimations,
            subtle: subtle,
          )
        else
          ...readModel.animations.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnimationCard(row: row, label: label),
            ),
          ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: SurfaceStudioCatalogBrowserLabels.sectionPresets,
          subtle: subtle,
        ),
        const SizedBox(height: 8),
        if (readModel.presets.isEmpty)
          _EmptyLine(
            text: SurfaceStudioCatalogBrowserLabels.emptyPresets,
            subtle: subtle,
          )
        else
          ...readModel.presets.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PresetCard(row: row, label: label),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtle});

  final String title;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: subtle,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({
    required this.text,
    required this.subtle,
  });

  final String text;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _BrowserCard extends StatelessWidget {
  const _BrowserCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({
    required this.k,
    required this.v,
    required this.valueColor,
  });

  final String k;
  final String v;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$k : $v',
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

class _AtlasCard extends StatelessWidget {
  const _AtlasCard({
    required this.row,
    required this.label,
  });

  final SurfaceStudioAtlasReadModel row;
  final Color label;

  @override
  Widget build(BuildContext context) {
    final n = row.usedByAnimationIds.length;
    return _BrowserCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelId,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelTileset,
            v: row.tilesetId,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelTile,
            v: '${row.tileWidth}×${row.tileHeight}',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelGrid,
            v: '${row.columns}×${row.rows}',
            valueColor: label,
          ),
          _KeyVal(
            k: 'Tuiles',
            v: '${row.tileCount} tiles',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelLayout,
            v: row.layout.name,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelUsedBy,
            v: SurfaceStudioCatalogBrowserLabels.usedByAnimations(n),
            valueColor: label,
          ),
        ],
      ),
    );
  }
}

class _AnimationCard extends StatelessWidget {
  const _AnimationCard({
    required this.row,
    required this.label,
  });

  final SurfaceStudioAnimationReadModel row;
  final Color label;

  @override
  Widget build(BuildContext context) {
    final refLine = row.referencedAtlasIds.join(' ');
    return _BrowserCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelId,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelFrames,
            v: SurfaceStudioCatalogBrowserLabels.frameLabel(row.frameCount),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelTotalDuration,
            v: '${row.totalDurationMs} ms',
            valueColor: label,
          ),
          if (row.syncGroupId != null)
            _KeyVal(
              k: SurfaceStudioCatalogBrowserLabels.labelSync,
              v: row.syncGroupId!,
              valueColor: label,
            ),
          if (row.categoryId != null)
            _KeyVal(
              k: SurfaceStudioCatalogBrowserLabels.labelCategory,
              v: row.categoryId!,
              valueColor: label,
            ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelRefAtlases,
            v: refLine.isEmpty ? '—' : refLine,
            valueColor: label,
          ),
        ],
      ),
    );
  }
}

String _roleLabel(SurfaceVariantRole r) => r.name;

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.row,
    required this.label,
  });

  final SurfaceStudioPresetReadModel row;
  final Color label;

  @override
  Widget build(BuildContext context) {
    final roleLine = row.roles.map(_roleLabel).join(' ');
    final animLine = row.referencedAnimationIds.join(' ');
    return _BrowserCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelId,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelVariants,
            v: SurfaceStudioCatalogBrowserLabels.variantLabel(row.variantCount),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelRoles,
            v: roleLine,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelPresetAnimationRefs,
            v: animLine.isEmpty ? '—' : animLine,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelCoverage,
            v: row.coversStandardRoles
                ? SurfaceStudioCatalogBrowserLabels.coverageFull
                : SurfaceStudioCatalogBrowserLabels.coveragePartial,
            valueColor: label,
          ),
        ],
      ),
    );
  }
}
