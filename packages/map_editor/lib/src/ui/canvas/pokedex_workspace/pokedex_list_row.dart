part of 'pokedex_workspace_page.dart';

// Lignes de liste et badges visuels.
//
// Chaque ligne résume une espèce importée avec un statut clair et des types
// visibles. La sélection reste purement locale au workspace.

class _PokedexListRow extends StatelessWidget {
  const _PokedexListRow({
    required this.entry,
    required this.projectRootPath,
    required this.isSelected,
    required this.onPressed,
  });

  final PokemonDatabaseIndexEntry entry;
  final String projectRootPath;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = isSelected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentJade,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = isSelected
        ? EditorChrome.accentJade.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final portraitAbsolutePath = entry.portraitRelativePath == null
        ? null
        : p.join(projectRootPath, entry.portraitRelativePath!);

    return CupertinoButton(
      key: Key('pokedex-row-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PokedexPortraitThumbnail(
                speciesId: entry.id,
                portraitAbsolutePath: portraitAbsolutePath,
                isSelected: isSelected,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                child: Text(
                  '#${entry.nationalDex.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  entry.primaryName,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  entry.id,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.types
                      .map((type) => _PokedexTypeChip(label: type))
                      .toList(growable: false),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                child: Align(
                  alignment: Alignment.topRight,
                  child: _PokedexStatusChip(
                    label: entry.isEnabledInProject ? 'Activé' : 'Désactivé',
                    isEnabled: entry.isEnabledInProject,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Thumbnail purement décoratif pour la liste Pokédex.
//
// Invariants volontaires :
// - on ne lit jamais de JSON ici ;
// - on ne déduit jamais un portrait “magique” ;
// - on se contente d'afficher le portrait local déjà résolu par la couche
//   applicative si un chemin existe ;
// - sinon on montre un placeholder stable et propre.
class _PokedexPortraitThumbnail extends StatelessWidget {
  const _PokedexPortraitThumbnail({
    required this.speciesId,
    required this.portraitAbsolutePath,
    required this.isSelected,
  });

  final String speciesId;
  final String? portraitAbsolutePath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? EditorChrome.accentJade.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);
    final fill = Color.lerp(
      EditorChrome.islandFillElevated(context),
      EditorChrome.accentJade,
      0.08,
    )!;

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: portraitAbsolutePath == null
            ? _PokedexPortraitPlaceholder(speciesId: speciesId)
            : Image.file(
                File(portraitAbsolutePath!),
                key: Key('pokedex-row-portrait-$speciesId'),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    _PokedexPortraitPlaceholder(speciesId: speciesId),
              ),
      ),
    );
  }
}

// Fallback visuel stable quand aucun portrait local n'est disponible.
//
// L'objectif n'est pas de cacher l'absence d'un asset, mais d'éviter une
// ligne vide ou cassée visuellement. Le placeholder reste donc volontairement
// simple et lisible.
class _PokedexPortraitPlaceholder extends StatelessWidget {
  const _PokedexPortraitPlaceholder({
    required this.speciesId,
  });

  final String speciesId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EditorChrome.accentWarm.withValues(alpha: 0.16),
            EditorChrome.accentJade.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          key: Key('pokedex-row-portrait-placeholder-$speciesId'),
          size: 20,
          color: CupertinoColors.white.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

class _PokedexTypeChip extends StatelessWidget {
  const _PokedexTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentJade,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PokedexStatusChip extends StatelessWidget {
  const _PokedexStatusChip({
    required this.label,
    required this.isEnabled,
  });

  final String label;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final accent =
        isEnabled ? EditorChrome.accentJade : EditorChrome.inspectorJoyCoral;
    final text = EditorChrome.primaryLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
