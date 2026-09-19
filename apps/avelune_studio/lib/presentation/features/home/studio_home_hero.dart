import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../theme/studio_home_tokens.dart';

class StudioHomeHero extends StatelessWidget {
  const StudioHomeHero({
    super.key,
    required this.busy,
    required this.onOpen,
    this.onResume,
  });
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 300),
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/home/hero_landscape.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.surfaceContainerLowest.withValues(alpha: .98),
                colors.surfaceContainerLowest.withValues(alpha: .75),
                colors.surfaceContainerLowest.withValues(alpha: .08),
              ],
              stops: const [0, .42, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 590),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BIENVENUE DANS AVELUNE STUDIO',
                      style: TextStyle(
                        color: StudioHomeTokens.titleAccent,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Donnez vie à votre propre',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontSize: 38, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'aventure',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: StudioHomeTokens.titleAccent,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cartes, personnages et histoires.\nRetrouvez vos outils de création, au même endroit.',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        if (onResume != null)
                          StudioButton(
                            label: 'Reprendre mon projet',
                            icon: Icons.arrow_forward,
                            onPressed: busy ? null : onResume,
                          ),
                        StudioButton(
                          key: const Key('open-project-picker'),
                          label: onResume == null
                              ? 'Ouvrir un projet'
                              : 'Ouvrir un autre projet',
                          secondary: onResume != null,
                          icon: Icons.folder_open,
                          onPressed: busy ? null : onOpen,
                        ),
                        if (onResume == null)
                          const Tooltip(
                            message:
                                'La création de projet sera disponible dans un prochain écran.',
                            child: StudioButton(
                              label: 'Nouveau projet',
                              secondary: true,
                              icon: Icons.add,
                              onPressed: null,
                            ),
                          ),
                      ],
                    ),
                    if (onResume == null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Création de projet : disponible dans un prochain écran.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
