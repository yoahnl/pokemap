import 'package:flutter/material.dart';

import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_pokemon_type_theme.dart';

class PlayerPokemonTypeBadge extends StatelessWidget {
  const PlayerPokemonTypeBadge({
    super.key,
    required this.type,
    this.compact = false,
  });

  final String type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final label = context.playerL10n.battleMoveType(type);
    final presentation = theme.rowPresentation(
      [
        theme.highContrast
            ? theme.base
            : PokeMapPlayerPokemonTypeTheme.color(type)
      ],
      preferredForeground: theme.contrastText,
    );
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        key: ValueKey('pokemon-type-$type'),
        decoration: BoxDecoration(
          color: presentation.backgrounds.first,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.focus.withValues(alpha: .5)),
        ),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PokeMapPlayerPokemonTypeTheme.icon(type),
                  size: 18, color: presentation.foreground),
              if (!compact) ...[
                const SizedBox(width: 5),
                Text(label,
                    style: theme.meta.copyWith(
                        color: presentation.foreground,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
