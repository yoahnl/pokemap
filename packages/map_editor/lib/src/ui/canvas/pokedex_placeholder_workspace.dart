import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../shared/cupertino_editor_widgets.dart';

/// Placeholder central du lot 12 pour l'entree Pokédex.
///
/// Ce widget est volontairement pauvre en logique :
/// - aucune lecture de donnees Pokemon ;
/// - aucun provider dedie ;
/// - aucun chargement asynchrone ;
/// - aucune liste factice.
///
/// Le role produit de ce lot est seulement de rendre visible un point d'entree
/// Pokédex clair dans l'editeur, sans pretendre que le catalogue Pokemon est
/// deja branche. Les lots suivants pourront remplacer ce placeholder par un
/// vrai contenu, mais ce fichier ne doit rien anticiper fonctionnellement.
class PokedexPlaceholderWorkspace extends StatelessWidget {
  const PokedexPlaceholderWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = EditorChrome.inspectorJoyAmber;
    final surface = EditorChrome.islandFillElevated(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: DecoratedBox(
          key: const Key('pokedex-placeholder-workspace'),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: accent.withValues(alpha: 0.55),
              width: 1.1,
            ),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
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
                  'Pokédex',
                  style: TextStyle(
                    color: label,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cette section deviendra plus tard le point d’entrée du contenu Pokémon du projet.',
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pour le lot 12, l’objectif reste volontairement minimal : la tuile existe, la navigation fonctionne et le vrai contenu détaillé arrivera dans les prochains lots.',
                  style: TextStyle(
                    color: subtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
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
