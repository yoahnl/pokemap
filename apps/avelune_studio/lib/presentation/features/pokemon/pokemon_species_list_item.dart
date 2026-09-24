import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../../features/pokemon/domain/pokemon_workspace_port.dart';
import '../../theme/studio_tokens.dart';
import 'pokemon_species_thumbnail.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesListItem extends StatelessWidget {
  const PokemonSpeciesListItem({
    super.key,
    required this.entry,
    required this.port,
    required this.selected,
    required this.onTap,
  });

  final PokemonSpeciesSummary entry;
  final PokemonWorkspacePort port;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: .7)
            : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          key: ValueKey('species-${entry.id}'),
          borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                PokemonSpeciesThumbnail(
                  key: ValueKey('thumbnail-${entry.id}'),
                  entry: entry,
                  port: port,
                  size: 46,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${entry.nationalDex.toString().padLeft(3, '0')} '
                        '· ${entry.types.map(pokemonTypeLabel).join(' / ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Tooltip(
                  message: entry.enabled
                      ? 'Activée dans le projet'
                      : 'Désactivée dans le projet',
                  child: Icon(
                    entry.enabled ? Icons.circle : Icons.circle_outlined,
                    size: 12,
                    color: entry.enabled
                        ? StudioColors.of(context).success
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
