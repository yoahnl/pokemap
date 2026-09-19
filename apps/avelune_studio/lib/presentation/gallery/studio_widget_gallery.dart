import 'package:flutter/material.dart';
import '../shared/widgets/buttons/studio_button.dart';
import '../shared/widgets/feedback/studio_badge.dart';
import '../shared/widgets/feedback/studio_empty_state.dart';
import '../shared/widgets/feedback/studio_notice.dart';
import '../shared/widgets/inputs/studio_resource_card.dart';
import '../shared/widgets/inputs/studio_search_field.dart';
import '../shared/widgets/inputs/studio_tabs.dart';
import '../shared/widgets/inputs/studio_toggle_row.dart';
import '../shared/widgets/layout/studio_app_shell.dart';
import '../shared/widgets/layout/studio_page_header.dart';
import '../shared/widgets/layout/studio_panel.dart';
import '../shared/widgets/layout/studio_resource_grid.dart';
import '../shared/widgets/layout/studio_section.dart';
import '../theme/studio_tokens.dart';

class StudioWidgetGallery extends StatefulWidget {
  const StudioWidgetGallery({super.key});
  @override
  State<StudioWidgetGallery> createState() => _StudioWidgetGalleryState();
}

class _StudioWidgetGalleryState extends State<StudioWidgetGallery> {
  final _search = TextEditingController();
  int _page = 0;
  double _width = double.infinity;
  bool _grid = true;
  bool _loading = false;
  String _category = 'Tous';
  String _selected = 'Forêt';
  String _message = 'Les commandes de cette démonstration restent en mémoire.';
  static const _resources = {
    'Forêt': Icons.forest,
    'Rivière': Icons.water,
    'Maison': Icons.house,
    'Personnage': Icons.person,
  };
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _demonstrateLoading() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = 'Démonstration terminée : aucun fichier écrit.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StudioAppShell(
      projectName: 'Catalogue interactif · aucun projet ouvert',
      destinations: [
        for (final (index, label, icon) in [
          (0, 'Contrôles', Icons.tune),
          (1, 'Ressources', Icons.grid_view),
          (2, 'Charte', Icons.palette_outlined),
        ])
          StudioDestination(
            label: label,
            icon: icon,
            selected: _page == index,
            onTap: () => setState(() => _page = index),
          ),
      ],
      child: Column(
        children: [
          const StudioPageHeader(
            title: 'Catalogue des widgets',
            description:
                'Composants Avelune et états interactifs de démonstration.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StudioTabs<double>(
              items: {
                double.infinity: 'Largeur disponible',
                840: '840 px',
                480: '480 px',
              },
              selected: _width,
              onChanged: (value) => setState(() => _width = value),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _width),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_page == 0) ..._controls(),
                    if (_page == 1) ..._resourceExamples(),
                    if (_page == 2) ..._tokens(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _controls() => [
    StudioPanel(
      title: 'Actions',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, variant) in [
              ('Principale', StudioButtonVariant.primary),
              ('Secondaire', StudioButtonVariant.secondary),
              ('Discrète', StudioButtonVariant.quiet),
            ])
              StudioButton(
                label: label,
                variant: variant,
                onPressed: () => setState(() => _message = '$label activée.'),
              ),
            StudioButton(
              label: 'Réinitialiser la démo',
              icon: Icons.restart_alt,
              variant: StudioButtonVariant.destructive,
              onPressed: () => setState(() {
                _grid = true;
                _message = 'Réglages de démonstration réinitialisés.';
              }),
            ),
            const StudioButton(label: 'Indisponible', onPressed: null),
            StudioButton(
              label: _loading ? 'Chargement…' : 'Simuler un chargement',
              loading: _loading,
              onPressed: _demonstrateLoading,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioNotice(_message),
      ],
    ),
    const SizedBox(height: 12),
    StudioPanel(
      title: 'Réglages et informations',
      children: [
        StudioToggleRow(
          label: 'Afficher la grille',
          value: _grid,
          description:
              'État local de démonstration : ${_grid ? 'activé' : 'désactivé'}.',
          onChanged: (value) => setState(() => _grid = value),
        ),
        StudioSection(
          title: 'Détails repliables',
          collapsible: true,
          children: [
            Text('Grille ${_grid ? 'visible' : 'masquée'} dans cet exemple.'),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, tone) in [
              ('Neutre', StudioTone.neutral),
              ('Information', StudioTone.info),
              ('Succès', StudioTone.success),
              ('Attention', StudioTone.warning),
              ('Erreur', StudioTone.danger),
              ('Histoire', StudioTone.feature),
            ])
              StudioBadge(label, tone: tone),
          ],
        ),
        const SizedBox(height: 12),
        const StudioNotice(
          'Exemple de message d’erreur explicite.',
          isError: true,
        ),
      ],
    ),
  ];

  List<Widget> _resourceExamples() {
    final entries = _resources.entries
        .where(
          (entry) =>
              entry.key.toLowerCase().contains(_search.text.toLowerCase()) &&
              (_category == 'Tous' ||
                  (_category == 'Nature' &&
                      (entry.key == 'Forêt' || entry.key == 'Rivière'))),
        )
        .toList();
    return [
      StudioPanel(
        title: 'Bibliothèque de démonstration',
        children: [
          const StudioNotice(
            'Les pictogrammes ci-dessous illustrent les cartes. '
            'Ils ne sont pas des ressources de projet.',
          ),
          const SizedBox(height: 16),
          StudioSearchField(
            controller: _search,
            label: 'Rechercher un exemple',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          StudioTabs<String>(
            items: const {'Tous': 'Tous', 'Nature': 'Nature'},
            selected: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 12),
          Text('Sélection : $_selected · ${entries.length} résultats'),
          SizedBox(
            height: 380,
            child: entries.isEmpty
                ? const StudioEmptyState(
                    title: 'Aucun exemple trouvé',
                    description: 'Essayez « Forêt » ou effacez la recherche.',
                  )
                : StudioResourceGrid(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return StudioResourceCard(
                        name: entry.key,
                        selected: _selected == entry.key,
                        category: 'Démonstration',
                        metadata: 'Aucune donnée projet',
                        preview: Icon(
                          entry.value,
                          size: 64,
                          color: StudioColors.of(context).success,
                        ),
                        onTap: () => setState(() => _selected = entry.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _tokens(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final studio = StudioColors.of(context);
    return [
      StudioPanel(
        title: 'Couleurs sémantiques',
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (label, color) in [
                ('Fond', colors.surfaceContainerLowest),
                ('Panneau', colors.surface),
                ('Surface élevée', colors.surfaceContainer),
                ('Bordure', colors.outline),
                ('Action', colors.primary),
                ('Sélection carte', studio.canvasSelection),
                ('Succès', studio.success),
                ('Attention', studio.warning),
                ('Histoire', studio.featureAccent),
                ('Erreur', colors.error),
              ])
                SizedBox(
                  width: 142,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        width: 142,
                        child: ColoredBox(color: color),
                      ),
                      const SizedBox(height: 6),
                      Text(label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ];
  }
}
