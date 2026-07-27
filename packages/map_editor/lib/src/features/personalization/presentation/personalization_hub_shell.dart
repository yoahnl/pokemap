import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_panel.dart';
import '../../../ui/design_system/pokemap_search_field.dart';
import '../application/personalization_publish_readiness.dart';
import '../application/project_presentation_presets.dart';
import 'personalization_readiness_panel.dart';
import 'personalization_runtime_preview.dart';

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
    this.baselineProfile,
    this.onProfileChanged,
    this.projectName = 'Votre jeu',
    this.projectRootPath = '',
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationCategory selectedCategory;
  final ValueChanged<ProjectPresentationCategory> onCategorySelected;
  final PersonalizationCategoryBuilder? categoryBuilder;
  final ProjectPresentationProfile? baselineProfile;
  final ValueChanged<ProjectPresentationProfile>? onProfileChanged;
  final String projectName;
  final String projectRootPath;

  @override
  Widget build(BuildContext context) {
    final diagnostics = validateProjectPresentationProfile(profile);
    final readiness = PersonalizationPublishReadiness.fromProfile(profile);
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
          readiness: readiness,
          onCategorySelected: onCategorySelected,
          categoryBuilder: categoryBuilder,
          baselineProfile: baselineProfile,
          onProfileChanged: onProfileChanged,
          fillAvailableHeight: constraints.maxWidth >= 760,
          projectName: projectName,
          projectRootPath: projectRootPath,
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

class _CategoryNavigation extends StatefulWidget {
  const _CategoryNavigation({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.fillAvailableHeight,
  });

  final ProjectPresentationCategory selectedCategory;
  final ValueChanged<ProjectPresentationCategory> onCategorySelected;
  final bool fillAvailableHeight;

  @override
  State<_CategoryNavigation> createState() => _CategoryNavigationState();
}

class _CategoryNavigationState extends State<_CategoryNavigation> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final categoryCards = ProjectPresentationCategory.values
        .where((category) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) return true;
          return '${_categoryLabel(category)} '
                  '${_categoryDescription(category)}'
              .toLowerCase()
              .contains(query);
        })
        .map(
          (category) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PokeMapCard(
              key: ValueKey<String>(
                'personalization-category-${category.name}',
              ),
              selected: category == widget.selectedCategory,
              onTap: () => widget.onCategorySelected(category),
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
      expandChild: widget.fillAvailableHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSearchField(
            key: const ValueKey<String>('personalization-category-search'),
            hintText: 'Rechercher une catégorie…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          if (widget.fillAvailableHeight)
            Expanded(
              child: ListView(children: categoryCards),
            )
          else
            ...categoryCards,
          if (categoryCards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Aucune catégorie ne correspond.'),
            ),
        ],
      ),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.profile,
    required this.category,
    required this.diagnostics,
    required this.readiness,
    required this.onCategorySelected,
    required this.categoryBuilder,
    required this.baselineProfile,
    required this.onProfileChanged,
    required this.fillAvailableHeight,
    required this.projectName,
    required this.projectRootPath,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationCategory category;
  final List<ProjectPresentationDiagnostic> diagnostics;
  final PersonalizationPublishReadiness readiness;
  final ValueChanged<ProjectPresentationCategory> onCategorySelected;
  final PersonalizationCategoryBuilder? categoryBuilder;
  final ProjectPresentationProfile? baselineProfile;
  final ValueChanged<ProjectPresentationProfile>? onProfileChanged;
  final bool fillAvailableHeight;
  final String projectName;
  final String projectRootPath;

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
    final content = <Widget>[
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
      _PersonalizationActions(
        profile: profile,
        category: category,
        baselineProfile: baselineProfile,
        onProfileChanged: onProfileChanged,
      ),
      const SizedBox(height: 16),
      categoryBuilder?.call(context, category) ??
          Text(_emptyCategoryMessage(category)),
      const SizedBox(height: 16),
      PersonalizationRuntimePreview(
        profile: profile,
        baselineProfile: baselineProfile,
        projectName: projectName,
        projectRootPath: projectRootPath,
      ),
      const SizedBox(height: 16),
      PersonalizationReadinessPanel(
        report: readiness,
        onCorrectIssue: (issue) {
          onCategorySelected(issue.category);
          if (issue.correctionKind ==
                  PersonalizationCorrectionKind.useSafeTheme &&
              onProfileChanged != null) {
            onProfileChanged!(
              profile.copyWith(theme: safeProjectSemanticTheme),
            );
          }
        },
      ),
    ];
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
      expandChild: fillAvailableHeight,
      child: fillAvailableHeight
          ? ListView(children: content)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
    );
  }
}

class _PersonalizationActions extends StatelessWidget {
  const _PersonalizationActions({
    required this.profile,
    required this.category,
    required this.baselineProfile,
    required this.onProfileChanged,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationCategory category;
  final ProjectPresentationProfile? baselineProfile;
  final ValueChanged<ProjectPresentationProfile>? onProfileChanged;

  @override
  Widget build(BuildContext context) {
    final comparison = baselineProfile == null
        ? null
        : compareProjectPresentation(baselineProfile!, profile);
    final presets = projectPresentationPresets
        .where((preset) => preset.supports(category))
        .toList(growable: false);
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final preset in presets)
                PokeMapButton(
                  key: ValueKey<String>(
                    'personalization-preset-${preset.id}',
                  ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(Icons.auto_awesome_outlined),
                  onPressed: onProfileChanged == null
                      ? null
                      : () => onProfileChanged!(
                            preset.apply(profile, category),
                          ),
                  child: Text(preset.label),
                ),
              PokeMapButton(
                key: ValueKey<String>(
                  'personalization-reset-${category.name}',
                ),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(Icons.restart_alt),
                onPressed: onProfileChanged == null
                    ? null
                    : () => onProfileChanged!(
                          resetProjectPresentationCategory(
                            profile,
                            category,
                          ),
                        ),
                child: const Text('Réinitialiser cette section'),
              ),
              if (comparison != null)
                PokeMapBadge(
                  label: comparison.isIdentical
                      ? 'Aucun changement'
                      : '${comparison.changedPaths.length} changements',
                  variant: comparison.isIdentical
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.info,
                ),
            ],
          ),
          if (comparison != null && !comparison.isIdentical) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              comparison.changedPaths.join('  •  '),
              key: const ValueKey<String>('personalization-comparison-paths'),
            ),
          ],
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
