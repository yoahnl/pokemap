import 'package:flutter/material.dart';

import '../../theme/studio_tokens.dart';

class PokemonSurface extends StatelessWidget {
  const PokemonSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => Material(
        color: emphasized ? colors.surfaceContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: padding,
          child: SizedBox(
            width: constraints.hasBoundedWidth ? double.infinity : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

class PokemonSectionHeading extends StatelessWidget {
  const PokemonSectionHeading({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class PokemonPill extends StatelessWidget {
  const PokemonPill({
    super.key,
    required this.label,
    this.icon,
    this.success = false,
    this.warning = false,
  });

  final String label;
  final IconData? icon;
  final bool success;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = success
        ? StudioColors.of(context).success
        : warning
        ? StudioColors.of(context).warning
        : colors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PokemonDataRow extends StatelessWidget {
  const PokemonDataRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 126,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

class PokemonEmptyState extends StatelessWidget {
  const PokemonEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.catching_pokemon_outlined,
    this.action,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Icon(icon, size: 34),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    ),
  );
}

String pokemonTypeLabel(String type) => switch (type.toLowerCase()) {
  'grass' => 'Plante',
  'poison' => 'Poison',
  'fire' => 'Feu',
  'water' => 'Eau',
  'electric' => 'Électrik',
  'ice' => 'Glace',
  'ground' => 'Sol',
  'rock' => 'Roche',
  'flying' => 'Vol',
  'psychic' => 'Psy',
  'bug' => 'Insecte',
  'ghost' => 'Spectre',
  'dragon' => 'Dragon',
  'dark' => 'Ténèbres',
  'steel' => 'Acier',
  'fairy' => 'Fée',
  'fighting' => 'Combat',
  'normal' => 'Normal',
  _ => type,
};
