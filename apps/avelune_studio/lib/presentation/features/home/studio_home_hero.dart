import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../theme/studio_home_tokens.dart';

class StudioHomeHero extends StatelessWidget {
  const StudioHomeHero({
    super.key,
    required this.busy,
    required this.onOpen,
    this.onResume,
    this.onExport,
    this.projectName,
    this.compact = false,
    this.smallWindow = false,
  });
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback? onResume;
  final VoidCallback? onExport;
  final String? projectName;
  final bool compact;
  final bool smallWindow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: largeText
              ? 210
              : smallWindow
              ? 188
              : compact
              ? 150
              : 178,
          decoration: const BoxDecoration(
            image: DecorationImage(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
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
                    const SizedBox(height: 4),
                    Text(
                      'Donnez vie à votre propre aventure',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: compact ? 27 : 32,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      projectName == null
                          ? 'Ouvrez un projet pour retrouver vos créations.'
                          : 'Projet courant : $projectName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
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
              Tooltip(
                message: projectName == null
                    ? 'Ouvrez un projet pour exporter le jeu'
                    : 'Créer un paquet .avelunegame pour Avelune Player',
                child: StudioButton(
                  key: const Key('home-export-game'),
                  label: 'Exporter le jeu…',
                  secondary: true,
                  icon: Icons.archive_outlined,
                  onPressed: busy ? null : onExport,
                ),
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
        ),
      ],
    );
  }
}
