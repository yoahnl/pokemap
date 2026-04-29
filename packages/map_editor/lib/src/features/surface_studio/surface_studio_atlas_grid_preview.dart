import 'package:flutter/cupertino.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const ValueKey<String> kSurfaceStudioAtlasGridPreviewSectionKey =
    ValueKey<String>('surface_studio_atlas_grid_preview_section');

class SurfaceStudioAtlasGridPreview extends StatelessWidget {
  const SurfaceStudioAtlasGridPreview({
    super.key,
    required this.sourceLabel,
    this.sourceDisplayForUi,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layoutLabel,
  });

  final String? sourceLabel;

  /// Libellé « humain » pour la ligne Source (ex. nom manifeste) ; si null, [sourceLabel] est utilisé.
  final String? sourceDisplayForUi;
  final int? tileWidth;
  final int? tileHeight;
  final int? columns;
  final int? rows;
  final String layoutLabel;

  static const int _previewMaxColumns = 12;
  static const int _previewMaxRows = 8;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final source = sourceLabel?.trim();
    final hasSource = source != null && source.isNotEmpty;
    final displaySource =
        (sourceDisplayForUi != null && sourceDisplayForUi!.trim().isNotEmpty)
            ? sourceDisplayForUi!.trim()
            : source;
    final hasValidGrid = _isPositive(tileWidth) &&
        _isPositive(tileHeight) &&
        _isPositive(columns) &&
        _isPositive(rows);

    final previewColumns =
        hasValidGrid ? _cap(columns!, _previewMaxColumns) : 0;
    final previewRows = hasValidGrid ? _cap(rows!, _previewMaxRows) : 0;
    final reduced = hasValidGrid &&
        (columns! > _previewMaxColumns || rows! > _previewMaxRows);

    return Container(
      key: kSurfaceStudioAtlasGridPreviewSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aperçu de la grille atlas',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (!hasSource)
            Text(
              'Choisissez une image source pour prévisualiser la grille.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
            )
          else if (!hasValidGrid)
            Text(
              'Corrigez les dimensions de grille pour afficher la preview.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
            )
          else ...[
            Text(
              'Source : $displaySource',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Tile : ${tileWidth!}×${tileHeight!} px',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Grille : ${columns!} colonnes × ${rows!} lignes',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Total : ${columns! * rows!} cases',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Disposition : $layoutLabel',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
            if (reduced) ...[
              const SizedBox(height: 4),
              Text(
                'Aperçu réduit',
                style: TextStyle(
                  color: subtle,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (var i = 0; i < previewColumns * previewRows; i++)
                  Container(
                    key: ValueKey<String>('surface_studio_grid_cell_$i'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: EditorChrome.editorIslandRim(context),
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

bool _isPositive(int? v) => v != null && v > 0;

int _cap(int v, int max) => v > max ? max : v;
