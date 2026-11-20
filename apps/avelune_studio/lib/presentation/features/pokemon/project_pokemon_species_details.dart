part of 'project_pokemon_page.dart';

class _SpeciesDetails extends StatefulWidget {
  const _SpeciesDetails({
    super.key,
    required this.entry,
    required this.thumbnail,
  });

  final PokemonSpeciesSummary entry;
  final Future<Uint8List?> Function() thumbnail;

  @override
  State<_SpeciesDetails> createState() => _SpeciesDetailsState();
}

class _SpeciesDetailsState extends State<_SpeciesDetails> {
  late final _thumbnail = Future.sync(widget.thumbnail);

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final l10n = context.l10n;
    final types = PokeMapPlayerLocalizations.lookup(Locale(l10n.localeName));
    return ListView(
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        StudioPanel(
          title: entry.name,
          children: [
            FutureBuilder(
              future: _thumbnail,
              builder: (context, snapshot) => switch (snapshot.data) {
                final bytes? => Image.memory(
                  bytes,
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.catching_pokemon, size: 48),
                ),
                _ => const Icon(Icons.catching_pokemon, size: 48),
              },
            ),
            Text(
              '#${entry.nationalDex} · ${l10n.pokemonGeneration(entry.generation)}',
            ),
            if (entry.types.isNotEmpty)
              Text(entry.types.map(types.battleMoveType).join(' · ')),
            Text(
              entry.enabled
                  ? l10n.pokemonSpeciesEnabled
                  : l10n.pokemonSpeciesDisabled,
            ),
          ],
        ),
      ],
    );
  }
}
