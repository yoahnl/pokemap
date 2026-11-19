import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_view.dart';
import 'package:avelune_studio/presentation/shared/widgets/avelune_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'resource_library_preview_data.dart';

class ResourceLibraryPreviewApp extends StatelessWidget {
  const ResourceLibraryPreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Avelune Studio · Bibliothèque',
    theme: studioTheme(),
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const _PreviewShell(),
  );
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 660;
    return Scaffold(
      body: Column(
        children: [
          ColoredBox(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.xl),
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    AveluneWordmark(height: compact ? 25 : 32),
                    const SizedBox(width: StudioSpacing.xl),
                    if (!compact) ...[
                      Text('Vallée d’Ambre', style: theme.textTheme.bodyMedium),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: StudioSpacing.l,
                        ),
                        child: Icon(Icons.chevron_right, size: 16),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        'Ressources',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const StudioBadge(
                      'Aperçu',
                      icon: Icons.visibility_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!compact) ...[
                  const _PreviewRail(),
                  const VerticalDivider(),
                ],
                Expanded(
                  child: ResourceLibraryView(
                    items: resourceLibraryPreviewItems,
                    maps: resourceLibraryPreviewMaps,
                    workshops: const _PreviewWorkshops(),
                    onImport: _showImport,
                    previewActions: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRail extends StatelessWidget {
  const _PreviewRail();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: SizedBox(
      width: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: StudioSpacing.l),
        child: Column(
          children: [
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.home_outlined),
              tooltip: 'Accueil du projet',
            ),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.map_outlined),
              tooltip: 'Constructeur de carte',
            ),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.explore_outlined),
              tooltip: 'Carte régionale',
            ),
            Semantics(
              label: 'Ressources',
              selected: true,
              child: const StudioBadge(
                '',
                icon: Icons.view_in_ar_outlined,
                tone: StudioTone.info,
              ),
            ),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.menu_book_outlined),
              tooltip: 'Histoire',
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreviewWorkshops extends StatelessWidget {
  const _PreviewWorkshops();

  static const _workshops = [
    (
      'Sols, chemins et eau',
      'Préparer les surfaces et leurs raccords.',
      Icons.layers_outlined,
    ),
    (
      'Bordures et parois',
      'Assembler une clôture, une rive ou une falaise.',
      Icons.terrain_outlined,
    ),
    (
      'Décors 2D',
      'Découper une image et préparer un décor à placer.',
      Icons.image_outlined,
    ),
    (
      'Modèles 3D',
      'Régler l’échelle, les collisions et les animations.',
      Icons.view_in_ar_outlined,
    ),
    (
      'Personnages',
      'Préparer une apparence et ses animations.',
      Icons.person_outline,
    ),
    (
      'Ensembles de décors',
      'Préparer une palette à répartir sur une zone.',
      Icons.grass_outlined,
    ),
    (
      'Images et tuiles',
      'Définir la grille de découpe d’une image.',
      Icons.grid_on_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(StudioSpacing.xxl),
    children: [
      Text(
        'Ateliers de création',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: StudioSpacing.xxl),
      Wrap(
        spacing: StudioSpacing.l,
        runSpacing: StudioSpacing.l,
        children: [
          for (final (title, text, icon) in _workshops)
            SizedBox(
              width: 248,
              child: StudioPanel(
                title: title,
                icon: icon,
                children: [Text(text)],
              ),
            ),
        ],
      ),
    ],
  );
}

void _showImport(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _ImportPreview());
}

class _ImportPreview extends StatefulWidget {
  const _ImportPreview();

  @override
  State<_ImportPreview> createState() => _ImportPreviewState();
}

class _ImportPreviewState extends State<_ImportPreview> {
  static const _formats = [
    ('Image', Icons.image_outlined),
    ('Modèle 3D', Icons.view_in_ar_outlined),
    ('Son ou musique', Icons.music_note_outlined),
    ('Vidéo', Icons.movie_outlined),
    ('Effet visuel', Icons.auto_awesome_outlined),
  ];
  String? _format;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Importer une ressource'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisis un type de fichier pour prévisualiser le parcours.',
          ),
          const SizedBox(height: StudioSpacing.l),
          Wrap(
            spacing: StudioSpacing.m,
            runSpacing: StudioSpacing.m,
            children: [
              for (final (label, icon) in _formats)
                ChoiceChip(
                  label: Text(label),
                  avatar: Icon(icon, size: 16),
                  selected: _format == label,
                  onSelected: (_) => setState(() => _format = label),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      StudioButton(
        label: 'Fermer',
        secondary: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      const StudioButton(label: 'Choisir un fichier', onPressed: null),
    ],
  );
}
