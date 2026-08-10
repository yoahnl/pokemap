import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_panel.dart';
import '../../../ui/design_system/pokemap_sidebar_item.dart';
import '../application/personalization_publish_readiness.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import 'personalization_readiness_panel.dart';
import 'personalization_runtime_preview.dart';
import 'personalization_section_actions.dart';

typedef PersonalizationCategoryBuilder =
    Widget Function(BuildContext context, ProjectPresentationCategory category);

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
    this.readinessReport,
    this.requiresPreflight = false,
    this.hasCompletedPreflight = true,
    this.isPreflightRunning = false,
    this.isPreflightStale = false,
    this.hasUnsavedChanges = false,
    this.preflightError,
    this.onRunPreflight,
    this.onSaveDraft,
    this.canContinueToExport = false,
    this.onContinueToExport,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationCategory selectedCategory;
  final ValueChanged<ProjectPresentationCategory> onCategorySelected;
  final PersonalizationCategoryBuilder? categoryBuilder;
  final ProjectPresentationProfile? baselineProfile;
  final ValueChanged<ProjectPresentationProfile>? onProfileChanged;
  final String projectName;
  final String projectRootPath;
  final PersonalizationPublishReadiness? readinessReport;
  final bool requiresPreflight;
  final bool hasCompletedPreflight;
  final bool isPreflightRunning;
  final bool isPreflightStale;
  final bool hasUnsavedChanges;
  final String? preflightError;
  final VoidCallback? onRunPreflight;
  final VoidCallback? onSaveDraft;
  final bool canContinueToExport;
  final VoidCallback? onContinueToExport;

  @override
  Widget build(BuildContext context) {
    final diagnostics = validateProjectPresentationProfile(profile);
    final readiness =
        readinessReport ?? PersonalizationPublishReadiness.fromProfile(profile);
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
          requiresPreflight: requiresPreflight,
          hasCompletedPreflight: hasCompletedPreflight,
          isPreflightRunning: isPreflightRunning,
          isPreflightStale: isPreflightStale,
          hasUnsavedChanges: hasUnsavedChanges,
          preflightError: preflightError,
          onRunPreflight: onRunPreflight,
          onSaveDraft: onSaveDraft,
          canContinueToExport: canContinueToExport,
          onContinueToExport: onContinueToExport,
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
    final categoryItems = ProjectPresentationCategory.values
        .map(
          (category) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PokeMapSidebarItem(
              key: ValueKey<String>(
                'personalization-category-${category.name}',
              ),
              label: _categoryLabel(category),
              subtitle: _categoryDescription(category),
              subtitleMaxLines: 2,
              growForTextScale: true,
              selected: category == selectedCategory,
              icon: Icon(_categoryIcon(category), size: 20),
              onTap: () => onCategorySelected(category),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (fillAvailableHeight)
            Expanded(child: ListView(children: categoryItems))
          else
            ...categoryItems,
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
    required this.requiresPreflight,
    required this.hasCompletedPreflight,
    required this.isPreflightRunning,
    required this.isPreflightStale,
    required this.hasUnsavedChanges,
    required this.preflightError,
    required this.onRunPreflight,
    required this.onSaveDraft,
    required this.canContinueToExport,
    required this.onContinueToExport,
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
  final bool requiresPreflight;
  final bool hasCompletedPreflight;
  final bool isPreflightRunning;
  final bool isPreflightStale;
  final bool hasUnsavedChanges;
  final String? preflightError;
  final VoidCallback? onRunPreflight;
  final VoidCallback? onSaveDraft;
  final bool canContinueToExport;
  final VoidCallback? onContinueToExport;

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
      PersonalizationSectionActions(
        profile: profile,
        category: category,
        baselineProfile: baselineProfile,
        onProfileChanged: onProfileChanged,
      ),
      const SizedBox(height: 16),
      _CategoryWorkspace(
        editor:
            categoryBuilder?.call(context, category) ??
            Text(_emptyCategoryMessage(category)),
        preview: PersonalizationRuntimePreview(
          profile: profile,
          baselineProfile: baselineProfile,
          projectName: projectName,
          projectRootPath: projectRootPath,
          initialSurface:
              PersonalizationStudioSceneDescriptor.defaultForCategory(
                category,
              ).surface,
        ),
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
        requiresPreflight: requiresPreflight,
        hasCompletedPreflight: hasCompletedPreflight,
        isPreflightRunning: isPreflightRunning,
        isPreflightStale: isPreflightStale,
        hasUnsavedChanges: hasUnsavedChanges,
        preflightError: preflightError,
        onRunPreflight: onRunPreflight,
        onSaveDraft: onSaveDraft,
        canContinueToExport: canContinueToExport,
        onContinueToExport: onContinueToExport,
      ),
    ];
    return PokeMapPanel(
      key: ValueKey<String>('personalization-category-detail-${category.name}'),
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
          ? ListView(
              key: ValueKey<String>(
                'personalization-category-detail-scroll-${category.name}',
              ),
              children: content,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
    );
  }
}

class _CategoryWorkspace extends StatelessWidget {
  const _CategoryWorkspace({required this.editor, required this.preview});

  final Widget editor;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[editor, const SizedBox(height: 16), preview],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 9, child: editor),
            const SizedBox(width: 16),
            Expanded(flex: 11, child: preview),
          ],
        );
      },
    );
  }
}

String _categoryLabel(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'Identité & écran titre',
      ProjectPresentationCategory.intro => 'Intro du jeu',
      ProjectPresentationCategory.typography => 'Typographie',
      ProjectPresentationCategory.theme => 'Menus & interface',
      ProjectPresentationCategory.layouts => 'Mise en page',
    };

String _categoryDescription(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'Logo, visuels et titre',
      ProjectPresentationCategory.intro => 'Vidéo, poster et accessibilité',
      ProjectPresentationCategory.typography => 'Polices et rôles de texte',
      ProjectPresentationCategory.theme =>
        'Libellés, fenêtres, couleurs et HUD',
      ProjectPresentationCategory.layouts =>
        'Position des contenus selon la taille d’écran',
    };

String _emptyCategoryMessage(ProjectPresentationCategory category) =>
    'Les réglages ${_categoryLabel(category).toLowerCase()} apparaîtront ici.';

IconData _categoryIcon(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => Icons.auto_awesome_outlined,
      ProjectPresentationCategory.intro => Icons.movie_outlined,
      ProjectPresentationCategory.typography => Icons.font_download_outlined,
      ProjectPresentationCategory.theme => Icons.palette_outlined,
      ProjectPresentationCategory.layouts => Icons.dashboard_customize_outlined,
    };
