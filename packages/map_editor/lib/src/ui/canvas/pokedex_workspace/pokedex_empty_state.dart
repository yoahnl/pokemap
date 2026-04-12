part of 'pokedex_workspace_page.dart';

// États vides et cadres de présentation du workspace.
//
// Ces vues servent à garder une UX lisible dans tous les cas simples : projet
// absent, chargement, erreur, aucune espèce importée ou aucun résultat après
// filtres. Elles restent volontairement honnêtes et non techniques.

class PokedexWorkspaceLoadingState extends StatelessWidget {
  const PokedexWorkspaceLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DefaultTextStyle(
      style: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      child: const PokedexWorkspaceStateFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: ProgressCircle(),
            ),
            SizedBox(height: 14),
            Text(
              'Chargement de la liste Pokédex…',
              key: Key('pokedex-loading-label'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'erreur minimale du lot 13.
///
/// L'objectif n'est pas d'ajouter une UX de récupération riche ; on rend
/// simplement l'erreur lisible, sans masquer qu'un chargement a échoué.
class PokedexWorkspaceErrorState extends StatelessWidget {
  const PokedexWorkspaceErrorState({
    super.key,
    required this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final message = switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error?.toString() ?? 'Erreur inconnue',
    };

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-error-state'),
      title: 'Pokédex',
      accent: EditorChrome.inspectorJoyCoral,
      titleStyle: TextStyle(
        color: label,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      message: 'Impossible de charger la liste locale des espèces.\n$message',
      messageStyle: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
    );
  }
}

/// Etat dédié des lots 14/15 quand les critères locaux ne matchent aucune entrée.
///
/// Il doit rester distinct de l'état "aucune espèce importée" :
/// - ici, la base locale contient des espèces ;
/// - ce sont uniquement les critères courants (recherche et/ou filtres) qui
///   n'ont trouvé aucun match.
/// On garde donc un message sobre, non anxiogène, et différent d'une erreur.
class PokedexWorkspaceNoResultsState extends StatelessWidget {
  const PokedexWorkspaceNoResultsState({
    super.key,
    required this.query,
    this.selectedType,
    this.selectedGeneration,
    this.selectedStatus,
  });

  final String query;
  final String? selectedType;
  final String? selectedGeneration;
  final String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final normalizedStatus = switch (selectedStatus) {
      _PokedexFilterDropdown.enabledOnlyValue => 'Activées',
      _PokedexFilterDropdown.disabledOnlyValue => 'Désactivées',
      _ => selectedStatus,
    };
    final activeCriteriaLines = <String>[
      if (normalizedQuery.isNotEmpty)
        'Recherche actuelle : "$normalizedQuery".',
      if (selectedType != null) 'Type : $selectedType.',
      if (selectedGeneration != null) 'Génération : $selectedGeneration.',
      if (normalizedStatus != null) 'Statut : $normalizedStatus.',
    ];
    final suffix = activeCriteriaLines.isEmpty
        ? ''
        : '\n${activeCriteriaLines.join('\n')}';

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-no-results-state'),
      title: 'Pokédex',
      message: 'Aucun résultat avec les critères actuels.$suffix',
    );
  }
}

/// Vue succès du lot 13.
///
/// Elle reste volontairement en lecture seule, mais la phase 5 ajoute une
/// vraie sélection locale de ligne pour ouvrir la fiche détail.

class PokedexWorkspaceImportEmptyState extends StatelessWidget {
  const PokedexWorkspaceImportEmptyState({
    super.key,
    required this.onImportRequested,
  });

  final VoidCallback onImportRequested;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              key: const Key('pokedex-empty-state'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: EditorChrome.accentPrune.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.folder,
                    size: 34,
                    color: EditorChrome.accentLilac,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Importer des Pokémon',
                  style: TextStyle(
                    color: label,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Votre Pokédex est encore vide. Importez un premier Pokémon pour commencer à construire la liste du projet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                CupertinoButton(
                  key: const Key('pokedex-empty-state-import-button'),
                  color: EditorChrome.accentJade.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: onImportRequested,
                  child: const Text('Importer des Pokémon'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokedexWorkspaceStateCard extends StatelessWidget {
  const PokedexWorkspaceStateCard({
    super.key,
    required this.title,
    required this.message,
    this.accent = EditorChrome.inspectorJoyAmber,
    this.titleStyle,
    this.messageStyle,
  });

  final String title;
  final String message;
  final Color accent;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return PokedexWorkspaceStateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accent, 0.72)!,
                  Color.lerp(accent, const Color(0xFF1A1408), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.82),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.book_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: titleStyle ??
                TextStyle(
                  color: label,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: messageStyle ??
                TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class PokedexWorkspaceStateFrame extends StatelessWidget {
  const PokedexWorkspaceStateFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.38),
              width: 1.1,
            ),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: child,
          ),
        ),
      ),
    );
  }
}
