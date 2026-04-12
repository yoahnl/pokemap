part of 'pokedex_workspace_page.dart';

// Petits widgets réutilisés par le flow d'import.
//
// Ils rendent l'aperçu plus lisible sans introduire une seconde logique de
// preview. Toute la donnée affichée vient déjà du previeweur applicatif.

class _PokedexImportSourceCard extends StatelessWidget {
  const _PokedexImportSourceCard({
    required this.cardKey,
    required this.title,
    required this.icon,
    this.onPressed,
    this.isSelected = false,
    this.trailingLabel,
  });

  final Key cardKey;
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSelected;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final accent = isSelected
        ? EditorChrome.accentJade
        : EditorChrome.accentWarm.withValues(alpha: 0.45);
    final text = isEnabled
        ? EditorChrome.primaryLabel(context)
        : EditorChrome.subtleLabel(context);

    return GestureDetector(
      key: cardKey,
      onTap: isEnabled ? onPressed : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent, width: isSelected ? 1.2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: text),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingLabel != null)
                Text(
                  trailingLabel!,
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexImportArtifactLine extends StatelessWidget {
  const _PokedexImportArtifactLine({
    super.key,
    required this.label,
    required this.isFound,
  });

  final String label;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    final accent = isFound ? EditorChrome.accentJade : EditorChrome.accentWarm;
    final text = EditorChrome.primaryLabel(context);
    final statusLabel = switch (label) {
      'Évolutions' => isFound ? 'Évolutions trouvées' : 'Évolutions manquantes',
      'Médias' => isFound ? 'Médias trouvés' : 'Médias manquants',
      'Cri' => isFound ? 'Cri trouvé' : 'Cri manquant',
      _ when label.endsWith('s') =>
        isFound ? '$label trouvés' : '$label manquants',
      _ => isFound ? '$label trouvé' : '$label manquant',
    };

    return Row(
      children: [
        Icon(
          isFound
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.exclamationmark_triangle_fill,
          size: 18,
          color: accent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            statusLabel,
            style: TextStyle(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
