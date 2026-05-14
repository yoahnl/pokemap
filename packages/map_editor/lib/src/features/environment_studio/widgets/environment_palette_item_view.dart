import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import 'environment_element_thumbnail.dart';

/// Carte d’un item de palette Environment (read-only).
class EnvironmentPaletteItemView extends StatelessWidget {
  const EnvironmentPaletteItemView({
    super.key,
    required this.item,
    required this.subtleColor,
    this.isIncompatibleTileset = false,
    this.manifest,
    this.element,
    this.resolveTilesetPathById,
  });

  final EnvironmentPaletteItem item;
  final Color subtleColor;
  final bool isIncompatibleTileset;
  final ProjectManifest? manifest;
  final ProjectElementEntry? element;
  final EnvironmentTilesetPathResolver? resolveTilesetPathById;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    final tags = item.tags.toList()..sort();

    return DecoratedBox(
      key: isIncompatibleTileset
          ? Key('environment-studio-palette-incompatible-${item.elementId}')
          : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        color: fill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 270,
              child: Row(
                children: [
                  manifest == null
                      ? _legacyIcon()
                      : EnvironmentElementThumbnail(
                          manifest: manifest!,
                          element: element,
                          elementId: item.elementId,
                          resolveTilesetPathById: resolveTilesetPathById,
                          size: 30,
                          previewKey: Key(
                            'environment-selected-palette-preview-${item.elementId}',
                          ),
                          fallbackKey: Key(
                            'environment-selected-palette-preview-fallback-${item.elementId}',
                          ),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.elementId,
                          key: Key(
                            'environment-studio-palette-item-${item.elementId}',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: label,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.elementId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 92,
              child: _miniChip(
                context,
                label: 'Poids ${item.weight}',
                key: Key('environment-studio-palette-weight-${item.elementId}'),
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                _collisionLabel(item.collisionMode),
                key: Key(
                  'environment-studio-palette-collision-${item.elementId}',
                ),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 230,
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  if (tags.isEmpty)
                    Text(
                      '—',
                      style: TextStyle(
                        color: subtleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    for (final t in tags)
                      _miniChip(
                        context,
                        label: t,
                        key: Key(
                          'environment-studio-palette-tag-${item.elementId}-$t',
                        ),
                      ),
                ],
              ),
            ),
            SizedBox(
              width: 78,
              child: isIncompatibleTileset
                  ? _warningChip(
                      context,
                      label: 'Tileset incompatible',
                    )
                  : Text(
                      '—',
                      style: TextStyle(
                        color: subtleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legacyIcon() {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.32),
        ),
      ),
      child: const Icon(
        CupertinoIcons.tree,
        color: EditorChrome.accentJade,
        size: 15,
      ),
    );
  }

  static String _collisionLabel(EnvironmentCollisionMode m) {
    return switch (m) {
      EnvironmentCollisionMode.useElementDefault => 'Défaut élément',
      EnvironmentCollisionMode.forceEnabled => 'Collision forcée',
      EnvironmentCollisionMode.forceDisabled => 'Collision désactivée',
    };
  }

  Widget _miniChip(
    BuildContext context, {
    required String label,
    Key? key,
  }) {
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: subtle,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _warningChip(
    BuildContext context, {
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorChrome.accentWarm.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: EditorChrome.accentWarm,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
