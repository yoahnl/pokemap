import 'package:flutter/material.dart';
import '../../../features/home/domain/recent_studio_project.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'studio_home_hero.dart';
import 'studio_home_navigation.dart';
import 'studio_home_projects.dart';
import 'studio_home_tools.dart';

class StudioHomeScreen extends StatefulWidget {
  const StudioHomeScreen({
    super.key,
    this.projectName,
    this.projectPath,
    this.busy = false,
    this.canTest = false,
    required this.onOpen,
    this.onResume,
    required this.onDestination,
    this.recentProjects = const [],
    required this.onRecent,
    required this.onRemoveRecent,
    this.maps = const [],
    required this.onMap,
    this.status,
    this.statusAtTop = false,
  });
  final String? projectName, projectPath;
  final bool busy, canTest;
  final VoidCallback onOpen;
  final VoidCallback? onResume;
  final ValueChanged<String> onDestination, onMap;
  final List<RecentStudioProject> recentProjects;
  final ValueChanged<RecentStudioProject> onRecent, onRemoveRecent;
  final List<({String id, String name})> maps;
  final Widget? status;
  final bool statusAtTop;

  @override
  State<StudioHomeScreen> createState() => _StudioHomeScreenState();
}

class _StudioHomeScreenState extends State<StudioHomeScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final recent = widget.recentProjects
        .where(
          (entry) =>
              entry.name.toLowerCase().contains(_query) ||
              entry.directoryPath.toLowerCase().contains(_query),
        )
        .toList();
    final maps = widget.maps
        .where((map) => map.name.toLowerCase().contains(_query))
        .toList();
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxWidth < 1200;
        final sidebar = Column(
          children: [
            StudioHomeRecentProjects(
              entries: recent,
              onOpen: widget.onRecent,
              onRemove: widget.onRemoveRecent,
              busy: widget.busy,
            ),
            const SizedBox(height: 16),
            const StudioPanel(
              title: 'Conseil du jour',
              compact: true,
              children: [
                Text(
                  'Préparez vos terrains dans Ressources, puis peignez la carte : les raccords se font automatiquement.',
                  style: TextStyle(height: 1.6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StudioPanel(
              title: 'Premiers pas',
              compact: true,
              children: [
                Text(
                  widget.projectName == null
                      ? 'Ouvrez un projet existant pour retrouver vos cartes, vos ressources et votre histoire.'
                      : 'Reprenez une carte, enrichissez ses rencontres, puis testez le résultat dans le jeu.',
                  style: const TextStyle(height: 1.6),
                ),
                const SizedBox(height: 12),
                for (final action in [
                  ('Préparer les ressources', 'resources'),
                  ('Composer une carte', 'map'),
                  ('Écrire une rencontre', 'story'),
                ])
                  StudioButton(
                    label: action.$1,
                    variant: StudioButtonVariant.quiet,
                    icon: Icons.arrow_forward,
                    onPressed: widget.busy
                        ? null
                        : () => widget.onDestination(action.$2),
                  ),
              ],
            ),
          ],
        );
        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.statusAtTop && widget.status != null) widget.status!,
            StudioHomeHero(
              busy: widget.busy,
              onOpen: widget.onOpen,
              onResume: widget.onResume,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  StudioHomeTools(
                    onDestination: widget.onDestination,
                    hasProject: widget.projectName != null,
                    canTest: widget.canTest,
                    busy: widget.busy,
                  ),
                  const SizedBox(height: 10),
                  StudioHomeResume(
                    maps: maps,
                    onMap: widget.onMap,
                    hasProject: widget.projectName != null,
                    busy: widget.busy,
                  ),
                  const SizedBox(height: 12),
                  StudioPanel(
                    title: 'Imaginez. Créez. Jouez.',
                    compact: true,
                    children: [
                      const Text(
                        'Avelune Studio vous donne les outils.\nLe reste, c’est votre histoire.',
                        style: TextStyle(height: 1.6),
                      ),
                      if (widget.projectPath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.projectPath!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  if (bounds.maxWidth < 1150) ...[
                    const SizedBox(height: 12),
                    sidebar,
                  ],
                  if (!widget.statusAtTop && widget.status != null) ...[
                    const SizedBox(height: 12),
                    widget.status!,
                  ],
                ],
              ),
            ),
          ],
        );
        return Material(
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: bounds.maxWidth < 650
                          ? 48
                          : compact
                          ? 318
                          : 388,
                      height: 60,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          bounds.maxWidth < 650
                              ? 'assets/home/avelune_symbol.png'
                              : 'assets/home/avelune_logo.png',
                          width: bounds.maxWidth < 650 ? 36 : 200,
                          height: bounds.maxWidth < 650 ? 36 : 60,
                          fit: BoxFit.contain,
                          semanticLabel: 'Avelune Studio',
                        ),
                      ),
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: StudioSearchField(
                          controller: _search,
                          label: 'Rechercher dans vos projets et cartes',
                          onChanged: (value) => setState(
                            () => _query = value.trim().toLowerCase(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioHomeNavigation(
                      canTest: widget.canTest,
                      onDestination: widget.onDestination,
                      projectName: widget.projectName,
                      busy: widget.busy,
                      compact: compact,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1600),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: main),
                                if (bounds.maxWidth >= 1150)
                                  SizedBox(
                                    width: 300,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        4,
                                        20,
                                        12,
                                        12,
                                      ),
                                      child: sidebar,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
