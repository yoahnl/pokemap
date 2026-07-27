import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_diagnostic_callout.dart';
import '../../../ui/design_system/pokemap_dialog.dart';
import '../../../ui/design_system/pokemap_empty_state.dart';
import '../../../ui/design_system/pokemap_toggle_tile.dart';
import '../../editor/state/editor_notifier.dart';
import '../application/personalization_studio_asset_picker.dart';
import '../application/project_branding_image_import_service.dart';
import '../application/project_font_import_service.dart';
import '../application/project_intro_video_import_service.dart';
import 'personalization_hub_shell.dart';
import 'project_branding_editor.dart';
import 'project_intro_video_editor.dart';
import 'project_semantic_theme_editor.dart';
import 'project_theme_token_dialog.dart';
import 'project_typography_editor.dart';

/// Adapts the current editor project to the reusable Personalization Hub.
///
/// Phase 2 binds the crash-safe draft to the guided category editors.
class PersonalizationStudioWorkspace extends ConsumerStatefulWidget {
  const PersonalizationStudioWorkspace({super.key});

  @override
  ConsumerState<PersonalizationStudioWorkspace> createState() =>
      _PersonalizationStudioWorkspaceState();
}

class _PersonalizationStudioWorkspaceState
    extends ConsumerState<PersonalizationStudioWorkspace> {
  ProjectPresentationCategory _selectedCategory =
      ProjectPresentationCategory.branding;
  String? _requestedProjectRootPath;
  bool _isImportingAsset = false;
  String? _assetFeedback;
  bool _assetFeedbackIsError = false;
  final Map<ProjectTypographyRole, String> _fontPreviewFamilies =
      <ProjectTypographyRole, String>{};

  void _ensureSession(String projectRootPath) {
    if (_requestedProjectRootPath == projectRootPath) return;
    _requestedProjectRootPath = projectRootPath;
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(
        ref
            .read(editorNotifierProvider.notifier)
            .initializePersonalizationStudioSession(),
      );
    });
  }

  Future<void> _importBrandingImage({
    required String projectRootPath,
    required ProjectPresentationProfile profile,
    required ProjectBrandingImageRole role,
    required EditorNotifier notifier,
  }) async {
    if (_isImportingAsset) return;
    setState(() {
      _isImportingAsset = true;
      _assetFeedback = null;
    });
    try {
      final selectedPath = await ref
          .read(personalizationStudioBrandingImagePickerProvider)
          .pickBrandingImage(role);
      if (!mounted) return;
      if (selectedPath == null) {
        setState(() {
          _assetFeedbackIsError = false;
          _assetFeedback = 'Import d’image annulé.';
        });
        return;
      }
      final imported = await ref
          .read(projectBrandingImageImportServiceProvider)
          .importIntoProject(
            projectRoot: Directory(projectRootPath),
            role: role,
            sourceFile: File(selectedPath),
          );
      final branding = _replaceBrandingImagePath(
        profile.branding,
        role,
        imported.relativePath,
      );
      final applied = await notifier.applyPersonalizationStudioProfile(
        profile.copyWith(branding: branding),
        label: 'Importer ${_brandingImageRoleName(role)}',
      );
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = !applied;
        _assetFeedback = applied
            ? 'Image de branding importée dans le brouillon.'
            : 'L’image a été validée, mais le brouillon n’a pas pu être modifié.';
      });
    } on PersonalizationStudioAssetSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = error.message;
      });
    } on ProjectBrandingImageImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = _localizedBrandingImageImportError(error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = 'L’import de l’image de branding a échoué.';
      });
    } finally {
      if (mounted) {
        setState(() => _isImportingAsset = false);
      }
    }
  }

  Future<void> _importFont({
    required BuildContext context,
    required String projectRootPath,
    required ProjectPresentationProfile profile,
    required ProjectTypographyRole role,
    required EditorNotifier notifier,
  }) async {
    if (_isImportingAsset) return;
    final confirmed = await showPokeMapBinaryConfirmationDialog(
      context,
      title: 'Droit de redistribution',
      message: 'Confirmez que la licence choisie autorise l’intégration et la '
          'redistribution de cette fonte avec le jeu exporté.',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Je confirme',
      icon: Icons.verified_user_outlined,
    );
    if (!mounted || !confirmed) return;

    setState(() {
      _isImportingAsset = true;
      _assetFeedback = null;
    });
    try {
      final selection = await ref
          .read(personalizationStudioAssetPickerProvider)
          .pickFontAssets();
      if (!mounted) return;
      if (selection == null) {
        setState(() {
          _assetFeedbackIsError = false;
          _assetFeedback = 'Import de fonte annulé.';
        });
        return;
      }
      final typography = profile.typography ?? const ProjectTypographyProfile();
      final currentRole = _typographyRoleProfile(typography, role);
      final imported =
          await ref.read(projectFontImportServiceProvider).importIntoProject(
                projectRoot: Directory(projectRootPath),
                role: role,
                fontFile: File(selection.fontPath),
                licenseFile: File(selection.licensePath),
                redistributionConfirmed: true,
                fallbackFamilies: currentRole.fallbackFamilies,
              );
      final previewFamily =
          await ref.read(projectFontPreviewLoaderProvider).load(
                fontFile: File('$projectRootPath/${imported.fontPath}'),
                role: role,
              );
      final updatedTypography =
          _replaceTypographyRole(typography, role, imported);
      final applied = await notifier.applyPersonalizationStudioProfile(
        profile.copyWith(typography: updatedTypography),
        label: 'Importer la fonte ${_typographyRoleName(role)}',
      );
      if (!mounted) return;
      setState(() {
        if (applied) {
          _fontPreviewFamilies[role] = previewFamily;
        }
        _assetFeedbackIsError = !applied;
        _assetFeedback = applied
            ? 'Fonte et licence importées dans le brouillon.'
            : 'La fonte a été validée, mais le brouillon n’a pas pu être modifié.';
      });
    } on PersonalizationStudioAssetSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = error.message;
      });
    } on ProjectFontImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = _localizedFontImportError(error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = 'L’import de la fonte a échoué.';
      });
    } finally {
      if (mounted) {
        setState(() => _isImportingAsset = false);
      }
    }
  }

  Future<void> _editThemeToken({
    required BuildContext context,
    required String token,
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    final theme = profile.theme ?? safeProjectSemanticTheme;
    final currentValue = _themeTokenValue(theme, token);
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: _themeTokenName(token),
      currentValue: currentValue,
    );
    if (!mounted || value == null || value == currentValue) return;
    await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(theme: _replaceThemeToken(theme, token, value)),
      label: 'Modifier la couleur ${_themeTokenName(token)}',
    );
  }

  Future<void> _editBrandingAccent({
    required BuildContext context,
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    final currentValue =
        profile.branding.accentColor ?? safeProjectSemanticTheme.primary;
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: 'Accent du titre',
      currentValue: currentValue,
    );
    if (!mounted || value == null || value == profile.branding.accentColor) {
      return;
    }
    await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(
        branding: profile.branding.copyWith(accentColor: value),
      ),
      label: 'Modifier la couleur d’accent',
    );
  }

  Future<void> _importIntroVideo({
    required String projectRootPath,
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    if (_isImportingAsset) return;

    setState(() {
      _isImportingAsset = true;
      _assetFeedback = null;
    });
    try {
      final selection = await ref
          .read(personalizationStudioAssetPickerProvider)
          .pickIntroAssets();
      if (!mounted) return;
      if (selection == null) {
        setState(() {
          _assetFeedbackIsError = false;
          _assetFeedback = 'Import de vidéo annulé.';
        });
        return;
      }
      final imported = await ref
          .read(projectIntroVideoImportServiceProvider)
          .importIntoProject(
            projectRoot: Directory(projectRootPath),
            videoFile: File(selection.videoPath),
            posterFile: File(selection.posterPath),
            captionsFile: selection.captionsPath == null
                ? null
                : File(selection.captionsPath!),
            reducedMotionBehavior:
                profile.intro?.reducedMotionBehavior ?? 'poster',
            allowReplay: profile.intro?.allowReplay ?? true,
          );
      final applied = await notifier.applyPersonalizationStudioProfile(
        profile.copyWith(intro: imported),
        label: 'Importer la vidéo d’introduction',
      );
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = !applied;
        _assetFeedback = applied
            ? 'Vidéo, poster et sous-titres importés dans le brouillon.'
            : 'La vidéo a été validée, mais le brouillon n’a pas pu être modifié.';
      });
    } on PersonalizationStudioAssetSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = error.message;
      });
    } on ProjectIntroVideoImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = _localizedIntroImportError(error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = 'L’import de la vidéo a échoué.';
      });
    } finally {
      if (mounted) {
        setState(() => _isImportingAsset = false);
      }
    }
  }

  Widget _buildCategoryEditor({
    required BuildContext context,
    required ProjectPresentationCategory category,
    required ProjectPresentationProfile profile,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
  }) {
    final feedback = <Widget>[
      if (_isImportingAsset) ...<Widget>[
        const PokeMapDiagnosticCallout(
          key: ValueKey<String>('personalization-studio-asset-progress'),
          severity: PokeMapDiagnosticSeverity.info,
          message: 'Validation et copie sécurisée des assets en cours…',
        ),
        const SizedBox(height: 12),
      ],
      if (_assetFeedback != null) ...<Widget>[
        PokeMapDiagnosticCallout(
          key: const ValueKey<String>(
            'personalization-studio-asset-feedback',
          ),
          severity: _assetFeedbackIsError
              ? PokeMapDiagnosticSeverity.error
              : PokeMapDiagnosticSeverity.info,
          message: _assetFeedback!,
        ),
        const SizedBox(height: 12),
      ],
    ];
    if (category == ProjectPresentationCategory.branding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ...feedback,
          IgnorePointer(
            ignoring: !canEdit || _isImportingAsset,
            child: ProjectBrandingEditor(
              profile: profile.branding,
              onImportImage: (role) {
                unawaited(
                  _importBrandingImage(
                    projectRootPath: projectRootPath,
                    profile: profile,
                    role: role,
                    notifier: notifier,
                  ),
                );
              },
              onRemoveImage: (role) {
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(
                      branding: _replaceBrandingImagePath(
                        profile.branding,
                        role,
                        null,
                      ),
                    ),
                    label: 'Retirer ${_brandingImageRoleName(role)}',
                  ),
                );
              },
              onEditAccent: () {
                unawaited(
                  _editBrandingAccent(
                    context: context,
                    profile: profile,
                    notifier: notifier,
                  ),
                );
              },
              onResetAccent: () {
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(
                      branding: profile.branding.copyWith(accentColor: null),
                    ),
                    label: 'Réinitialiser la couleur d’accent',
                  ),
                );
              },
              onLayoutVariantChanged: (layoutVariant) {
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(
                      branding: profile.branding.copyWith(
                        layoutVariant: layoutVariant,
                      ),
                    ),
                    label: 'Modifier la disposition du titre',
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    if (category == ProjectPresentationCategory.intro) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ...feedback,
          IgnorePointer(
            ignoring: !canEdit || _isImportingAsset,
            child: ProjectIntroVideoEditor(
              profile: profile.intro,
              onImportPressed: () {
                unawaited(
                  _importIntroVideo(
                    projectRootPath: projectRootPath,
                    profile: profile,
                    notifier: notifier,
                  ),
                );
              },
              onChanged: (intro) {
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(intro: intro),
                    label: 'Modifier les préférences de l’intro',
                  ),
                );
              },
              onRemove: profile.intro == null
                  ? null
                  : () {
                      unawaited(
                        notifier.applyPersonalizationStudioProfile(
                          profile.copyWith(intro: null),
                          label: 'Retirer la vidéo d’introduction',
                        ),
                      );
                    },
            ),
          ),
        ],
      );
    }
    if (category == ProjectPresentationCategory.typography) {
      final typography = profile.typography ?? const ProjectTypographyProfile();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ...feedback,
          IgnorePointer(
            ignoring: !canEdit || _isImportingAsset,
            child: ProjectTypographyEditor(
              profile: typography,
              previewFamilies: _fontPreviewFamilies,
              onImportRole: (role) {
                unawaited(
                  _importFont(
                    context: context,
                    projectRootPath: projectRootPath,
                    profile: profile,
                    role: role,
                    notifier: notifier,
                  ),
                );
              },
              onUseSystemFont: (role) {
                final current = _typographyRoleProfile(typography, role);
                final systemRole = ProjectTypographyRoleProfile(
                  fallbackFamilies: current.fallbackFamilies,
                );
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(
                      typography:
                          _replaceTypographyRole(typography, role, systemRole),
                    ),
                    label: 'Utiliser le fallback ${_typographyRoleName(role)}',
                  ),
                );
                setState(() => _fontPreviewFamilies.remove(role));
              },
            ),
          ),
        ],
      );
    }
    if (category == ProjectPresentationCategory.theme) {
      final theme = profile.theme ?? safeProjectSemanticTheme;
      return IgnorePointer(
        ignoring: !canEdit,
        child: ProjectSemanticThemeEditor(
          profile: theme,
          onEditToken: (token) {
            unawaited(
              _editThemeToken(
                context: context,
                token: token,
                profile: profile,
                notifier: notifier,
              ),
            );
          },
          onUseSafeFallback: () {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(theme: safeProjectSemanticTheme),
                label: 'Appliquer la palette sûre',
              ),
            );
          },
        ),
      );
    }
    return Text(
      'Les réglages ${_categoryName(category)} apparaîtront ici.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorNotifierProvider);
    final project = editorState.project;
    if (project == null) {
      final errorMessage = editorState.errorMessage?.trim();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        return PokeMapEmptyState(
          key: const ValueKey<String>('personalization-studio-error'),
          title: 'Personalization Studio indisponible',
          description: errorMessage,
          icon: const Icon(Icons.error_outline_rounded),
        );
      }

      final projectRootPath = editorState.projectRootPath?.trim();
      if (projectRootPath != null && projectRootPath.isNotEmpty) {
        return const PokeMapEmptyState(
          key: ValueKey<String>('personalization-studio-loading'),
          title: 'Chargement du projet…',
          description:
              'Préparation du profil de présentation et de ses aperçus.',
          icon: Icon(Icons.hourglass_top_rounded),
        );
      }

      return const PokeMapEmptyState(
        key: ValueKey<String>('personalization-studio-no-project'),
        title: 'Aucun projet ouvert',
        description:
            'Ouvrez un projet pour consulter son profil de personnalisation.',
        icon: Icon(Icons.folder_open_rounded),
      );
    }

    final projectRootPath = editorState.projectRootPath!;
    _ensureSession(projectRootPath);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final studioSession = notifier.personalizationStudioSessionState;
    final canEdit = studioSession?.isInitialized == true &&
        studioSession?.hasFailed == false &&
        studioSession?.isConflicted == false &&
        studioSession?.isSaving == false;
    final profile =
        studioSession?.draftProfile ?? project.effectivePresentation;
    final baselineProfile = studioSession?.savedProfile;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PokeMapCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      studioSession?.isDirty == true
                          ? 'Le brouillon diffère de project.json.'
                          : 'La personnalisation correspond à project.json.',
                    ),
                  ),
                  if (studioSession?.isDirty == true)
                    const PokeMapBadge(
                      key: ValueKey<String>('personalization-studio-dirty'),
                      label: 'Modifications non enregistrées',
                      variant: PokeMapBadgeVariant.info,
                    )
                  else
                    const PokeMapBadge(
                      key: ValueKey<String>('personalization-studio-clean'),
                      label: 'Enregistré',
                      variant: PokeMapBadgeVariant.success,
                    ),
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'personalization-studio-undo',
                    ),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.undo_rounded),
                    onPressed: studioSession?.canUndo == true && canEdit
                        ? () {
                            unawaited(
                              notifier.undoPersonalizationStudio(),
                            );
                          }
                        : null,
                    child: const Text('Annuler'),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'personalization-studio-redo',
                    ),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.redo_rounded),
                    onPressed: studioSession?.canRedo == true && canEdit
                        ? () {
                            unawaited(
                              notifier.redoPersonalizationStudio(),
                            );
                          }
                        : null,
                    child: const Text('Rétablir'),
                  ),
                  SizedBox(
                    width: 230,
                    child: PokeMapToggleTile(
                      key: const ValueKey<String>(
                        'personalization-studio-autosave',
                      ),
                      label: 'Sauvegarde automatique',
                      value: studioSession?.autosaveEnabled == true,
                      onChanged: (enabled) {
                        unawaited(
                          notifier.setPersonalizationStudioAutosaveEnabled(
                            enabled,
                          ),
                        );
                      },
                    ),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'personalization-studio-save',
                    ),
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.save_outlined),
                    isLoading: studioSession?.isSaving == true,
                    onPressed: studioSession?.isDirty == true && canEdit
                        ? () {
                            unawaited(notifier.savePersonalizationStudio());
                          }
                        : null,
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PersonalizationHubShell(
              key: const ValueKey<String>(
                'personalization-studio-workspace',
              ),
              profile: profile,
              baselineProfile: baselineProfile,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
              categoryBuilder: (context, category) => _buildCategoryEditor(
                context: context,
                category: category,
                profile: profile,
                projectRootPath: projectRootPath,
                notifier: notifier,
                canEdit: canEdit,
              ),
              onProfileChanged: canEdit
                  ? (profile) {
                      unawaited(
                        notifier.applyPersonalizationStudioProfile(profile),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryName(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'branding',
      ProjectPresentationCategory.intro => 'intro vidéo',
      ProjectPresentationCategory.typography => 'typographie',
      ProjectPresentationCategory.theme => 'thème et HUD',
    };

ProjectTypographyRoleProfile _typographyRoleProfile(
  ProjectTypographyProfile profile,
  ProjectTypographyRole role,
) =>
    switch (role) {
      ProjectTypographyRole.display => profile.display,
      ProjectTypographyRole.body => profile.body,
      ProjectTypographyRole.dialogue => profile.dialogue,
      ProjectTypographyRole.numbers => profile.numbers,
    };

ProjectTypographyProfile _replaceTypographyRole(
  ProjectTypographyProfile profile,
  ProjectTypographyRole role,
  ProjectTypographyRoleProfile replacement,
) =>
    switch (role) {
      ProjectTypographyRole.display => profile.copyWith(display: replacement),
      ProjectTypographyRole.body => profile.copyWith(body: replacement),
      ProjectTypographyRole.dialogue => profile.copyWith(dialogue: replacement),
      ProjectTypographyRole.numbers => profile.copyWith(numbers: replacement),
    };

String _typographyRoleName(ProjectTypographyRole role) => switch (role) {
      ProjectTypographyRole.display => 'Titres & affichage',
      ProjectTypographyRole.body => 'Texte courant',
      ProjectTypographyRole.dialogue => 'Dialogues',
      ProjectTypographyRole.numbers => 'Nombres',
    };

String _themeTokenValue(ProjectSemanticThemeProfile profile, String token) =>
    switch (token) {
      'primary' => profile.primary,
      'onPrimary' => profile.onPrimary,
      'background' => profile.background,
      'surface' => profile.surface,
      'surfaceElevated' => profile.surfaceElevated,
      'textPrimary' => profile.textPrimary,
      'textSecondary' => profile.textSecondary,
      'outline' => profile.outline,
      'success' => profile.success,
      'warning' => profile.warning,
      'danger' => profile.danger,
      'titleSurface' => profile.titleSurface,
      'dialogueSurface' => profile.dialogueSurface,
      'menuSurface' => profile.menuSurface,
      'overworldHudSurface' => profile.overworldHudSurface,
      'battleHudSurface' => profile.battleHudSurface,
      _ => throw ArgumentError.value(token, 'token', 'Unknown theme token'),
    };

ProjectSemanticThemeProfile _replaceThemeToken(
  ProjectSemanticThemeProfile profile,
  String token,
  String value,
) =>
    switch (token) {
      'primary' => profile.copyWith(primary: value),
      'onPrimary' => profile.copyWith(onPrimary: value),
      'background' => profile.copyWith(background: value),
      'surface' => profile.copyWith(surface: value),
      'surfaceElevated' => profile.copyWith(surfaceElevated: value),
      'textPrimary' => profile.copyWith(textPrimary: value),
      'textSecondary' => profile.copyWith(textSecondary: value),
      'outline' => profile.copyWith(outline: value),
      'success' => profile.copyWith(success: value),
      'warning' => profile.copyWith(warning: value),
      'danger' => profile.copyWith(danger: value),
      'titleSurface' => profile.copyWith(titleSurface: value),
      'dialogueSurface' => profile.copyWith(dialogueSurface: value),
      'menuSurface' => profile.copyWith(menuSurface: value),
      'overworldHudSurface' => profile.copyWith(overworldHudSurface: value),
      'battleHudSurface' => profile.copyWith(battleHudSurface: value),
      _ => throw ArgumentError.value(token, 'token', 'Unknown theme token'),
    };

String _themeTokenName(String token) => switch (token) {
      'primary' => 'Action principale',
      'onPrimary' => 'Texte sur action',
      'background' => 'Fond global',
      'surface' => 'Surface',
      'surfaceElevated' => 'Surface élevée',
      'textPrimary' => 'Texte principal',
      'textSecondary' => 'Texte secondaire',
      'outline' => 'Contours',
      'success' => 'Succès',
      'warning' => 'Avertissement',
      'danger' => 'Danger',
      'titleSurface' => 'Fond du titre',
      'dialogueSurface' => 'Fond des dialogues',
      'menuSurface' => 'Fond des menus',
      'overworldHudSurface' => 'Fond du HUD exploration',
      'battleHudSurface' => 'Fond du HUD combat',
      _ => token,
    };

ProjectBrandingProfile _replaceBrandingImagePath(
  ProjectBrandingProfile profile,
  ProjectBrandingImageRole role,
  String? path,
) =>
    switch (role) {
      ProjectBrandingImageRole.icon => profile.copyWith(iconPath: path),
      ProjectBrandingImageRole.cover => profile.copyWith(coverPath: path),
      ProjectBrandingImageRole.hero => profile.copyWith(heroPath: path),
    };

String _brandingImageRoleName(ProjectBrandingImageRole role) => switch (role) {
      ProjectBrandingImageRole.icon => 'l’icône du jeu',
      ProjectBrandingImageRole.cover => 'la cover de bibliothèque',
      ProjectBrandingImageRole.hero => 'le logo / hero du titre',
    };

String _localizedBrandingImageImportError(
  ProjectBrandingImageImportException error,
) =>
    switch (error.code) {
      'brandingImageMissing' => 'L’image sélectionnée est introuvable.',
      'brandingImageFormatUnsupported' =>
        'Choisissez une image PNG, JPEG ou WebP.',
      'brandingImageCorrupt' =>
        'L’image sélectionnée ne peut pas être décodée.',
      'brandingImageWriteFailed' =>
        'L’image validée n’a pas pu être copiée dans le projet.',
      _ => error.message,
    };

String _localizedIntroImportError(ProjectIntroVideoImportException error) =>
    switch (error.code) {
      'introVideoMissing' => 'La vidéo sélectionnée est introuvable.',
      'introPosterMissing' => 'Le poster sélectionné est introuvable.',
      'introCaptionsMissing' =>
        'Le fichier de sous-titres sélectionné est introuvable.',
      'introSizeExceeded' => 'La vidéo dépasse la limite de 100 Mio.',
      'introCodecUnsupported' => 'Choisissez une vidéo MP4 encodée en H.264.',
      'introPosterInvalid' => 'Choisissez un poster PNG, JPEG ou WebP valide.',
      'introCaptionsInvalid' =>
        'Les sous-titres doivent être un fichier WebVTT UTF-8 valide.',
      'introDecoderRejected' =>
        'Le décodeur de cette plateforme ne peut pas lire cette vidéo.',
      'introDurationExceeded' =>
        'La vidéo dépasse la durée maximale de 2 minutes.',
      'introResolutionExceeded' =>
        'La vidéo dépasse la résolution maximale de 1920 × 1080.',
      'introBitrateExceeded' => 'Le débit de la vidéo dépasse 12 000 kbit/s.',
      'introImportWriteFailed' =>
        'Les assets validés n’ont pas pu être copiés dans le projet.',
      _ => error.message,
    };

String _localizedFontImportError(ProjectFontImportException error) =>
    switch (error.code) {
      'fontMissing' => 'La fonte sélectionnée est introuvable.',
      'fontLicenseMissing' => 'La licence sélectionnée est introuvable.',
      'fontRedistributionNotConfirmed' =>
        'Confirmez le droit de redistribution de cette fonte.',
      'fontFallbackMissing' =>
        'Conservez au moins une fonte système de secours.',
      'fontFormatUnsupported' => 'Choisissez une fonte TTF ou OTF.',
      'fontSizeUnsupported' => 'La fonte dépasse la limite de 10 Mio.',
      'fontSignatureInvalid' =>
        'La signature du fichier ne correspond pas à son extension.',
      'fontLicenseSizeUnsupported' =>
        'La licence doit être un fichier texte inférieur à 1 Mio.',
      'fontLicenseInvalid' => 'La licence doit contenir du texte UTF-8 valide.',
      'fontFamilyMissing' => 'La fonte ne déclare aucun nom de famille.',
      'fontGlyphCoverageIncomplete' =>
        'La fonte ne couvre pas tous les glyphes requis par le player.',
      'fontImportWriteFailed' =>
        'La fonte validée n’a pas pu être copiée dans le projet.',
      _ => error.message,
    };
