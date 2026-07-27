import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_panel.dart';

typedef PersonalizationCategoryBuilder = Widget Function(
  BuildContext context,
  ProjectPresentationCategory category,
);

/// No-code entry shell shared by every project presentation editor.
class PersonalizationHubShell extends StatelessWidget {
  const PersonalizationHubShell({
    super.key,
    required this.profile,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryBuilder,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationCategory selectedCategory;
  final ValueChanged<ProjectPresentationCategory> onCategorySelected;
  final PersonalizationCategoryBuilder? categoryBuilder;

  @override
  Widget build(BuildContext context) {
    final diagnostics = validateProjectPresentationProfile(profile);
    return LayoutBuilder(
      builder: (context, constraints) {
        final navigation = _CategoryNavigation(
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
          fillAvailableHeight: constraints.maxWidth >= 760,
        );
        final detail = _CategoryDetail(
          profile: profile,
          category: selectedCategory,
          diagnostics: diagnostics,
          categoryBuilder: categoryBuilder,
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: constraints.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(width: 240, child: navigation),
                    const SizedBox(width: 16),
                    Expanded(child: detail),
                  ],
                )
              : ListView(
                  children: <Widget>[
                    navigation,
                    const SizedBox(height: 16),
                    detail,
                  ],
                ),
        );
      },
    );
  }
}

class _CategoryNavigation extends StatelessWidget {
  const _CategoryNavigation({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.fillAvailableHeight,
  });

  final ProjectPresentationCategory selectedCategory;
  final ValueChanged<ProjectPresentationCategory> onCategorySelected;
  final bool fillAvailableHeight;

  @override
  Widget build(BuildContext context) {
    final categoryCards = ProjectPresentationCategory.values
        .map(
          (category) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PokeMapCard(
              key: ValueKey<String>(
                'personalization-category-${category.name}',
              ),
              selected: category == selectedCategory,
              onTap: () => onCategorySelected(category),
              child: Row(
                children: <Widget>[
                  Icon(_categoryIcon(category), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _categoryLabel(category),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _categoryDescription(category),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(growable: false);
    return PokeMapPanel(
      header: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Personalization Hub',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text('Personnalisez l’identité visible de votre jeu.'),
          ],
        ),
      ),
      padding: const EdgeInsets.all(10),
      expandChild: fillAvailableHeight,
      child: fillAvailableHeight
          ? ListView(children: categoryCards)
          : Column(children: categoryCards),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.profile,
    required this.category,
    required this.diagnostics,
    required this.categoryBuilder,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationCategory category;
  final List<ProjectPresentationDiagnostic> diagnostics;
  final PersonalizationCategoryBuilder? categoryBuilder;

  @override
  Widget build(BuildContext context) {
    final categoryDiagnostics = diagnostics
        .where((diagnostic) => diagnostic.category == category)
        .toList(growable: false);
    final errorCount = categoryDiagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity ==
              ProjectPresentationDiagnosticSeverity.error,
        )
        .length;
    final isConfigured = profile.configuredCategories.contains(category);
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _categoryLabel(category),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PokeMapBadge(
              label: errorCount > 0
                  ? '$errorCount ${errorCount == 1 ? 'erreur' : 'erreurs'}'
                  : isConfigured
                      ? 'Configuré'
                      : 'Prêt à configurer',
              variant: errorCount > 0
                  ? PokeMapBadgeVariant.error
                  : isConfigured
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.info,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (categoryDiagnostics.isNotEmpty) ...<Widget>[
            for (final diagnostic in categoryDiagnostics)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PokeMapCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.error_outline, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(diagnostic.message)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          categoryBuilder?.call(context, category) ??
              Text(_emptyCategoryMessage(category)),
        ],
      ),
    );
  }
}

String _categoryLabel(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'Branding',
      ProjectPresentationCategory.intro => 'Intro vidéo',
      ProjectPresentationCategory.typography => 'Typographie',
      ProjectPresentationCategory.theme => 'Thème & HUD',
    };

String _categoryDescription(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'Logo, couvertures et titre',
      ProjectPresentationCategory.intro => 'Vidéo, poster et accessibilité',
      ProjectPresentationCategory.typography => 'Polices et rôles de texte',
      ProjectPresentationCategory.theme => 'Couleurs sémantiques et HUD',
    };

String _emptyCategoryMessage(ProjectPresentationCategory category) =>
    'Les réglages ${_categoryLabel(category).toLowerCase()} apparaîtront ici.';

IconData _categoryIcon(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => Icons.auto_awesome_outlined,
      ProjectPresentationCategory.intro => Icons.movie_outlined,
      ProjectPresentationCategory.typography => Icons.font_download_outlined,
      ProjectPresentationCategory.theme => Icons.palette_outlined,
    };
