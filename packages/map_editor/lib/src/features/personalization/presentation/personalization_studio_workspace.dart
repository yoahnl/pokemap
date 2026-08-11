import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart'
    show presentationPresetAssetReferences;
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/l10n.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_diagnostic_callout.dart';
import '../../../ui/design_system/pokemap_dialog.dart';
import '../../../ui/design_system/pokemap_empty_state.dart';
import '../../../ui/design_system/pokemap_toggle_tile.dart';
import '../../../ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart';
import '../../editor/state/editor_notifier.dart';
import '../application/personalization_capability_descriptor.dart';
import '../application/personalization_character_preview_source.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_context_source.dart';
import '../application/personalization_preview_fixtures.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import '../application/personalization_publish_readiness.dart';
import '../application/personalization_studio_asset_picker.dart';
import '../application/project_branding_image_import_service.dart';
import '../application/project_font_import_service.dart';
import '../application/project_intro_video_import_service.dart';
import '../application/project_presentation_preflight.dart';
import '../application/project_title_music_import_service.dart';
import '../application/project_title_music_preview_controller.dart';
import '../application/project_title_motion_import_service.dart';
import 'personalization_live_preview.dart';
import 'personalization_readiness_panel.dart';
import 'personalization_section_actions.dart';
import 'personalization_studio_shell.dart';
import 'inspectors/personalization_battle_inspector.dart';
import 'inspectors/personalization_global_style_inspector.dart';
import 'inspectors/personalization_dialogue_inspector.dart';
import 'inspectors/personalization_intro_inspector.dart';
import 'inspectors/personalization_pause_inspector.dart';
import 'inspectors/personalization_title_inspector.dart';
import 'project_layout_studio.dart';
import 'project_semantic_theme_editor.dart';
import 'project_menu_labels_editor.dart';
import 'project_presentation_preset_library.dart';
import 'project_theme_token_dialog.dart';
import 'project_typography_editor.dart';
import 'project_window_studio.dart';

typedef PersonalizationStudioExportLauncher =
    Future<void> Function(
      BuildContext context, {
      required String projectRootPath,
      required String projectName,
    });

final personalizationStudioExportLauncherProvider =
    Provider<PersonalizationStudioExportLauncher>((ref) {
      return showTopToolbarGameExportDialog;
    });

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
  PersonalizationStudioScene _selectedScene = PersonalizationStudioScene.title;
  PersonalizationInspectorTarget _selectedTarget =
      const TitlePresentationTarget();
  String? _requestedProjectRootPath;
  bool _isImportingAsset = false;
  bool _isManagingPreset = false;
  String? _assetFeedback;
  bool _assetFeedbackIsError = false;
  ProjectTitleMusicPreviewController? _titleMusicPreviewController;
  StreamSubscription<bool>? _titleMusicPreviewSubscription;
  bool _isTitleMusicPreviewPlaying = false;
  String? _selectedDialogueCharacterId;
  bool _showDialoguePortrait = true;
  bool _showDialogueName = true;
  bool _showDialogueChoices = false;
  PersonalizationBattlePreviewState _battlePreviewState =
      PersonalizationBattlePreviewState.commands;
  final Map<ProjectTypographyRole, String> _fontPreviewFamilies =
      <ProjectTypographyRole, String>{};
  ProjectPresentationPreflightResult? _preflightResult;
  ProjectPresentationProfile? _preflightProfile;
  String? _preflightProjectRootPath;
  String? _preflightError;
  bool _isPreflightRunning = false;
  int _preflightRequestId = 0;

  @override
  void dispose() {
    final subscription = _titleMusicPreviewSubscription;
    final controller = _titleMusicPreviewController;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    if (controller != null) {
      unawaited(controller.close());
    }
    super.dispose();
  }

  void _ensureSession(String projectRootPath) {
    if (_requestedProjectRootPath == projectRootPath) return;
    _requestedProjectRootPath = projectRootPath;
    scheduleMicrotask(() async {
      if (!mounted) return;
      await ref
          .read(editorNotifierProvider.notifier)
          .initializePersonalizationStudioSession();
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _runPreflight({
    required String projectRootPath,
    required ProjectPresentationProfile profile,
  }) async {
    final requestId = ++_preflightRequestId;
    setState(() {
      _isPreflightRunning = true;
      _preflightError = null;
    });
    try {
      final result = await ref
          .read(projectPresentationPreflightProvider)
          .inspect(projectRoot: Directory(projectRootPath), profile: profile);
      if (!mounted || requestId != _preflightRequestId) return;
      setState(() {
        _preflightResult = result;
        _preflightProfile = profile;
        _preflightProjectRootPath = projectRootPath;
        _isPreflightRunning = false;
      });
    } on Object {
      if (!mounted || requestId != _preflightRequestId) return;
      setState(() {
        _isPreflightRunning = false;
        _preflightError = context.pokeMapL10n.personalizationPreflightReadError;
      });
    }
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

  Future<void> _importTitleMusic({
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
      final selectedPath = await ref
          .read(personalizationStudioTitleMusicPickerProvider)
          .pickTitleMusic();
      if (!mounted) return;
      if (selectedPath == null) {
        setState(() {
          _assetFeedbackIsError = false;
          _assetFeedback = 'Import de musique annulé.';
        });
        return;
      }
      await _stopTitleMusicPreview();
      final imported = await ref
          .read(projectTitleMusicImportServiceProvider)
          .importIntoProject(
            projectRoot: Directory(projectRootPath),
            sourceFile: File(selectedPath),
          );
      final applied = await notifier.applyPersonalizationStudioProfile(
        profile.copyWith(
          branding: profile.branding.copyWith(
            titleMusicPath: imported.relativePath,
          ),
        ),
        label: 'Importer la musique du titre',
      );
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = !applied;
        _assetFeedback = applied
            ? 'Musique du titre importée dans le brouillon.'
            : 'La musique a été validée, mais le brouillon n’a pas pu être modifié.';
      });
    } on PersonalizationStudioAssetSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = error.message;
      });
    } on ProjectTitleMusicImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = _localizedTitleMusicImportError(error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = 'L’import de la musique du titre a échoué.';
      });
    } finally {
      if (mounted) {
        setState(() => _isImportingAsset = false);
      }
    }
  }

  Future<void> _toggleTitleMusicPreview({
    required String projectRootPath,
    required String relativePath,
  }) async {
    try {
      await _ensureTitleMusicPreviewController().toggle(
        File('$projectRootPath/$relativePath'),
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback =
            'La musique du titre ne peut pas être lue sur cette plateforme.';
      });
    }
  }

  Future<void> _removeTitleMusic({
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    await _stopTitleMusicPreview();
    final applied = await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(
        branding: profile.branding.copyWith(titleMusicPath: null),
      ),
      label: 'Retirer la musique du titre',
    );
    if (!mounted) return;
    setState(() {
      _assetFeedbackIsError = !applied;
      _assetFeedback = applied
          ? 'Musique du titre retirée du brouillon.'
          : 'Le brouillon n’a pas pu être modifié.';
    });
  }

  ProjectTitleMusicPreviewController _ensureTitleMusicPreviewController() {
    final current = _titleMusicPreviewController;
    if (current != null) return current;
    final controller = ref.read(
      projectTitleMusicPreviewControllerFactoryProvider,
    )();
    _titleMusicPreviewSubscription = controller.playingChanges.listen((
      isPlaying,
    ) {
      if (!mounted || _isTitleMusicPreviewPlaying == isPlaying) return;
      setState(() => _isTitleMusicPreviewPlaying = isPlaying);
    });
    _titleMusicPreviewController = controller;
    return controller;
  }

  Future<void> _stopTitleMusicPreview() async {
    final controller = _titleMusicPreviewController;
    if (controller == null) return;
    await controller.stop();
    if (mounted && _isTitleMusicPreviewPlaying) {
      setState(() => _isTitleMusicPreviewPlaying = false);
    }
  }

  Future<void> _importFont({
    required BuildContext context,
    required String projectRootPath,
    required ProjectPresentationProfile profile,
    required ProjectTypographyRole role,
    required EditorNotifier notifier,
    bool applyToAllRoles = false,
  }) async {
    if (_isImportingAsset) return;
    final confirmed = await showPokeMapBinaryConfirmationDialog(
      context,
      title: 'Droit de redistribution',
      message:
          'Confirmez que la licence choisie autorise l’intégration et la '
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
      final imported = await ref
          .read(projectFontImportServiceProvider)
          .importIntoProject(
            projectRoot: Directory(projectRootPath),
            role: role,
            fontFile: File(selection.fontPath),
            licenseFile: File(selection.licensePath),
            redistributionConfirmed: true,
            fallbackFamilies: currentRole.fallbackFamilies,
          );
      final previewFamily = await ref
          .read(projectFontPreviewLoaderProvider)
          .load(
            fontFile: File('$projectRootPath/${imported.fontPath}'),
            role: role,
          );
      final updatedTypography = applyToAllRoles
          ? ProjectTypographyProfile(
              display: imported,
              body: imported,
              dialogue: imported,
              combat: imported,
              numbers: imported,
            )
          : _replaceTypographyRole(typography, role, imported);
      final applied = await notifier.applyPersonalizationStudioProfile(
        profile.copyWith(typography: updatedTypography),
        label: applyToAllRoles
            ? 'Importer la police commune'
            : 'Importer la fonte ${_typographyRoleName(role)}',
      );
      if (!mounted) return;
      setState(() {
        if (applied) {
          if (applyToAllRoles) {
            for (final typographyRole in ProjectTypographyRole.values) {
              _fontPreviewFamilies[typographyRole] = previewFamily;
            }
          } else {
            _fontPreviewFamilies[role] = previewFamily;
          }
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
      tokenLabel: 'Cartouche Avelune et accent du titre',
      currentValue: currentValue,
    );
    if (!mounted || value == null || value == profile.branding.accentColor) {
      return;
    }
    await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(branding: profile.branding.copyWith(accentColor: value)),
      label: 'Modifier la couleur de cartouche et d’accent',
    );
  }

  Future<void> _editGlobalStyleAccent({
    required BuildContext context,
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    final theme = profile.theme ?? safeProjectSemanticTheme;
    final currentValue = profile.branding.accentColor ?? theme.outline;
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: 'l’accent',
      currentValue: currentValue,
    );
    if (!mounted || value == null || value == currentValue) return;
    await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(
        branding: profile.branding.copyWith(accentColor: value),
        theme: theme.copyWith(outline: value),
      ),
      label: 'Modifier la couleur d’accent commune',
    );
  }

  Future<void> _editGlobalStyleThemeToken({
    required BuildContext context,
    required String token,
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    final theme = profile.theme ?? safeProjectSemanticTheme;
    final currentValue = _themeTokenValue(theme, token);
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: switch (token) {
        'surface' => 'les fenêtres',
        'textPrimary' => 'le texte',
        'primary' => 'les boutons',
        _ => _themeTokenName(token),
      },
      currentValue: currentValue,
    );
    if (!mounted || value == null || value == currentValue) return;
    final updatedTheme = switch (token) {
      'surface' => theme.copyWith(
        surface: value,
        surfaceElevated: value,
        titleSurface: value,
        dialogueSurface: value,
        menuSurface: value,
        overworldHudSurface: value,
        battleHudSurface: value,
      ),
      _ => _replaceThemeToken(theme, token, value),
    };
    await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(theme: updatedTheme),
      label: 'Modifier la couleur globale ${_themeTokenName(token)}',
    );
  }

  Future<void> _useSystemCommonFont({
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    final typography = profile.typography ?? const ProjectTypographyProfile();
    final updated = ProjectTypographyProfile(
      display: ProjectTypographyRoleProfile(
        fallbackFamilies: typography.display.fallbackFamilies,
      ),
      body: ProjectTypographyRoleProfile(
        fallbackFamilies: typography.body.fallbackFamilies,
      ),
      dialogue: ProjectTypographyRoleProfile(
        fallbackFamilies: typography.dialogue.fallbackFamilies,
      ),
      combat: ProjectTypographyRoleProfile(
        fallbackFamilies:
            (typography.combat ?? typography.body).fallbackFamilies,
      ),
      numbers: ProjectTypographyRoleProfile(
        fallbackFamilies: typography.numbers.fallbackFamilies,
      ),
    );
    final applied = await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(typography: updated),
      label: 'Utiliser la police système commune',
    );
    if (!mounted || !applied) return;
    setState(_fontPreviewFamilies.clear);
  }

  Future<void> _resetGlobalTypography({
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    final applied = await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(typography: null),
      label: 'Réinitialiser la typographie globale',
    );
    if (!mounted || !applied) return;
    setState(_fontPreviewFamilies.clear);
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

  Future<void> _importTitleMotionLoop({
    required String projectRootPath,
    required ProjectPresentationProfile profile,
    required ProjectTitleMotionLoopRole role,
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
          .pickTitleMotionAssets();
      if (!mounted) return;
      if (selection == null) {
        setState(() {
          _assetFeedbackIsError = false;
          _assetFeedback = 'Import de boucle annulé.';
        });
        return;
      }
      final imported = await ref
          .read(projectTitleMotionImportServiceProvider)
          .importIntoProject(
            projectRoot: Directory(projectRootPath),
            videoFile: File(selection.videoPath),
            posterFile: File(selection.posterPath),
            captionsFile: selection.captionsPath == null
                ? null
                : File(selection.captionsPath!),
          );
      final current = profile.titleMotion ?? const ProjectTitleMotionProfile();
      final titleMotion = switch (role) {
        ProjectTitleMotionLoopRole.prompt => current.copyWith(
          promptLoop: imported,
        ),
        ProjectTitleMotionLoopRole.menu => current.copyWith(menuLoop: imported),
      };
      final applied = await notifier.applyPersonalizationStudioProfile(
        profile.copyWith(titleMotion: titleMotion),
        label: role == ProjectTitleMotionLoopRole.prompt
            ? 'Importer la boucle d’invitation'
            : 'Importer la boucle du menu titre',
      );
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = !applied;
        _assetFeedback = applied
            ? 'Boucle et poster importés dans le brouillon.'
            : 'La boucle a été validée, mais le brouillon n’a pas pu être modifié.';
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
        _assetFeedback = 'L’import de la boucle a échoué.';
      });
    } finally {
      if (mounted) setState(() => _isImportingAsset = false);
    }
  }

  Future<void> _removeTitleMotionLoop({
    required ProjectPresentationProfile profile,
    required ProjectTitleMotionLoopRole role,
    required EditorNotifier notifier,
  }) async {
    final current = profile.titleMotion;
    if (current == null) return;
    final updated = switch (role) {
      ProjectTitleMotionLoopRole.prompt => current.copyWith(promptLoop: null),
      ProjectTitleMotionLoopRole.menu => current.copyWith(menuLoop: null),
    };
    await notifier.applyPersonalizationStudioProfile(
      profile.copyWith(
        titleMotion: updated.promptLoop == null && updated.menuLoop == null
            ? null
            : updated,
      ),
      label: role == ProjectTitleMotionLoopRole.prompt
          ? 'Retirer la boucle d’invitation'
          : 'Retirer la boucle du menu titre',
    );
  }

  Future<void> _exportPresentationPreset({
    required String projectRootPath,
    required String projectName,
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    if (_isManagingPreset) return;
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final presetId = 'profile-$stamp';
    final picker = ref.read(personalizationStudioPresetFilePickerProvider);
    String? redistributionLicenseSourcePath;
    if (presentationPresetAssetReferences(
      profile,
    ).any((reference) => reference.licenseProjectPath == null)) {
      redistributionLicenseSourcePath = await picker
          .pickPresetRedistributionLicense();
      if (!mounted || redistributionLicenseSourcePath == null) return;
    }
    final destination = await picker.pickPresetExportPath(
      '$presetId.pokemapstyle',
    );
    if (!mounted || destination == null) return;
    setState(() {
      _isManagingPreset = true;
      _assetFeedback = null;
    });
    try {
      await ref
          .read(projectPresentationPresetServiceProvider)
          .exportCurrent(
            projectRootPath: projectRootPath,
            presetId: presetId,
            label: 'Profil de $projectName',
            description: 'Profil PokeMap exporté depuis $projectName.',
            destinationPath: destination.endsWith('.pokemapstyle')
                ? destination
                : '$destination.pokemapstyle',
            redistributionLicenseSourcePath: redistributionLicenseSourcePath,
          );
      await notifier.loadProject('$projectRootPath/project.json');
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = false;
        _assetFeedback = 'Profil exporté et ajouté à la bibliothèque.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = _presetFailureMessage(error);
      });
    } finally {
      if (mounted) setState(() => _isManagingPreset = false);
    }
  }

  Future<void> _importPresentationPreset({
    required String projectRootPath,
    required EditorNotifier notifier,
  }) async {
    if (_isManagingPreset) return;
    final source = await ref
        .read(personalizationStudioPresetFilePickerProvider)
        .pickPresetToImport();
    if (!mounted || source == null) return;
    setState(() {
      _isManagingPreset = true;
      _assetFeedback = null;
    });
    try {
      await ref
          .read(projectPresentationPresetServiceProvider)
          .importAndApply(projectRootPath: projectRootPath, sourcePath: source);
      await notifier.loadProject('$projectRootPath/project.json');
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = false;
        _assetFeedback = 'Profil importé, vérifié et appliqué au projet.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = _presetFailureMessage(error);
      });
    } finally {
      if (mounted) setState(() => _isManagingPreset = false);
    }
  }

  Future<void> _deletePresentationPreset({
    required BuildContext context,
    required String projectRootPath,
    required ProjectPresentationPresetRecord preset,
    required EditorNotifier notifier,
  }) async {
    if (_isManagingPreset) return;
    final confirmed = await showPokeMapBinaryConfirmationDialog(
      context,
      title: 'Supprimer « ${preset.label} » ?',
      message:
          'Le profil disparaîtra de cette bibliothèque. Les assets encore '
          'utilisés par le projet seront conservés.',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!mounted || !confirmed) return;
    setState(() => _isManagingPreset = true);
    try {
      await ref
          .read(projectPresentationPresetServiceProvider)
          .delete(projectRootPath: projectRootPath, presetId: preset.id);
      await notifier.loadProject('$projectRootPath/project.json');
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = false;
        _assetFeedback = 'Profil supprimé de la bibliothèque.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = _presetFailureMessage(error);
      });
    } finally {
      if (mounted) setState(() => _isManagingPreset = false);
    }
  }

  Widget _buildCategoryEditor({
    required BuildContext context,
    required ProjectPresentationCategory category,
    required ProjectPresentationProfile profile,
    required String projectName,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
    required List<ProjectPresentationPresetRecord> presets,
    required bool canManagePresets,
  }) {
    final feedback = <Widget>[
      if (_isImportingAsset || _isManagingPreset) ...<Widget>[
        PokeMapDiagnosticCallout(
          key: const ValueKey<String>('personalization-studio-asset-progress'),
          severity: PokeMapDiagnosticSeverity.info,
          message: _isManagingPreset
              ? 'Vérification du profil et transaction sécurisée en cours…'
              : 'Validation et copie sécurisée des assets en cours…',
        ),
        const SizedBox(height: 12),
      ],
      if (_assetFeedback != null) ...<Widget>[
        PokeMapDiagnosticCallout(
          key: const ValueKey<String>('personalization-studio-asset-feedback'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PersonalizationTitleInspector(
                  profile: profile,
                  projectName: projectName,
                  projectRootPath: projectRootPath,
                  onChanged: (nextProfile) {
                    unawaited(
                      notifier.applyPersonalizationStudioProfile(
                        nextProfile,
                        label: 'Modifier la composition du titre',
                      ),
                    );
                  },
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
                          branding: profile.branding.copyWith(
                            accentColor: null,
                          ),
                        ),
                        label:
                            'Réinitialiser la couleur de cartouche et d’accent',
                      ),
                    );
                  },
                  onImportTitleMusic: () {
                    unawaited(
                      _importTitleMusic(
                        projectRootPath: projectRootPath,
                        profile: profile,
                        notifier: notifier,
                      ),
                    );
                  },
                  onToggleTitleMusicPreview:
                      profile.branding.titleMusicPath == null
                      ? null
                      : () {
                          unawaited(
                            _toggleTitleMusicPreview(
                              projectRootPath: projectRootPath,
                              relativePath: profile.branding.titleMusicPath!,
                            ),
                          );
                        },
                  onRemoveTitleMusic: profile.branding.titleMusicPath == null
                      ? null
                      : () {
                          unawaited(
                            _removeTitleMusic(
                              profile: profile,
                              notifier: notifier,
                            ),
                          );
                        },
                  isTitleMusicPreviewPlaying: _isTitleMusicPreviewPlaying,
                  onImportMotion: (role) {
                    unawaited(
                      _importTitleMotionLoop(
                        projectRootPath: projectRootPath,
                        profile: profile,
                        role: role,
                        notifier: notifier,
                      ),
                    );
                  },
                  onRemoveMotion: (role) {
                    unawaited(
                      _removeTitleMotionLoop(
                        profile: profile,
                        role: role,
                        notifier: notifier,
                      ),
                    );
                  },
                  onSurfacePalettesChanged: (surfacePalettes) {
                    unawaited(
                      notifier.applyPersonalizationStudioProfile(
                        profile.copyWith(surfacePalettes: surfacePalettes),
                        label: 'Modifier les couleurs de l’écran titre',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                ProjectPresentationPresetLibrary(
                  presets: presets,
                  canManage: canManagePresets && !_isManagingPreset,
                  onApply: (preset) {
                    unawaited(
                      notifier.applyPersonalizationStudioProfile(
                        preset.profile,
                        label: 'Appliquer le profil ${preset.label}',
                      ),
                    );
                  },
                  onDelete: (preset) {
                    unawaited(
                      _deletePresentationPreset(
                        context: context,
                        projectRootPath: projectRootPath,
                        preset: preset,
                        notifier: notifier,
                      ),
                    );
                  },
                  onImport: () {
                    unawaited(
                      _importPresentationPreset(
                        projectRootPath: projectRootPath,
                        notifier: notifier,
                      ),
                    );
                  },
                  onExport: () {
                    unawaited(
                      _exportPresentationPreset(
                        projectRootPath: projectRootPath,
                        projectName: projectName,
                        profile: profile,
                        notifier: notifier,
                      ),
                    );
                  },
                ),
              ],
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
            child: PersonalizationIntroInspector(
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
                      typography: _replaceTypographyRole(
                        typography,
                        role,
                        systemRole,
                      ),
                    ),
                    label: 'Utiliser le fallback ${_typographyRoleName(role)}',
                  ),
                );
                setState(() => _fontPreviewFamilies.remove(role));
              },
              onMetricsChanged: (role, metrics) {
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(
                      typography: _replaceTypographyRoleMetrics(
                        typography,
                        role,
                        metrics,
                      ),
                    ),
                    label: 'Modifier le texte ${_typographyRoleName(role)}',
                  ),
                );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ProjectMenuLabelsEditor(
              profile: profile.menuLabels ?? const ProjectMenuLabelsProfile(),
              onChanged: (menuLabels) {
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(menuLabels: menuLabels),
                    label: 'Modifier les libellés du menu Pause',
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ProjectWindowStudio(
              profile: profile.windows ?? legacyProjectPresentationWindows,
              onChanged: (windows) {
                unawaited(
                  notifier.applyPersonalizationStudioProfile(
                    profile.copyWith(windows: windows),
                    label: windows == null
                        ? 'Réinitialiser les fenêtres du jeu'
                        : 'Modifier les fenêtres du jeu',
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ProjectSemanticThemeEditor(
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
          ],
        ),
      );
    }
    if (category == ProjectPresentationCategory.layouts) {
      return IgnorePointer(
        ignoring: !canEdit,
        child: ProjectLayoutStudio(
          profile: profile.layouts,
          brandingLayoutVariant: profile.branding.layoutVariant,
          onChanged: (layouts) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(layouts: layouts),
                label: layouts == null
                    ? 'Réinitialiser la mise en page du jeu'
                    : 'Modifier la mise en page du jeu',
              ),
            );
          },
        ),
      );
    }
    return Text('Les réglages ${_categoryName(category)} apparaîtront ici.');
  }

  Widget _buildInspectorEditor({
    required BuildContext context,
    required PersonalizationInspectorTarget target,
    required ProjectPresentationProfile profile,
    required String projectName,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
    required List<ProjectPresentationPresetRecord> presets,
    required bool canManagePresets,
    required List<PersonalizationCharacterPreviewOption> characterOptions,
  }) {
    final editor = switch (target) {
      GlobalColorsTarget() => _buildGlobalStyleTarget(
        context: context,
        section: PersonalizationGlobalStyleSection.colors,
        profile: profile,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
      ),
      GlobalTypographyTarget() => _buildGlobalStyleTarget(
        context: context,
        section: PersonalizationGlobalStyleSection.typography,
        profile: profile,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
      ),
      GlobalFormsTarget() => _buildGlobalStyleTarget(
        context: context,
        section: PersonalizationGlobalStyleSection.forms,
        profile: profile,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
      ),
      BattleCommandsTarget() || BattleAppearanceTarget() => _buildBattleTarget(
        context: context,
        profile: profile,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
      ),
      DialogueAppearanceTarget() ||
      DialogueTypographyTarget() ||
      DialogueLayoutTarget() => _buildDialogueTarget(
        context: context,
        profile: profile,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
        characterOptions: characterOptions,
      ),
      PauseLabelsTarget() ||
      PauseAppearanceTarget() ||
      PauseLayoutTarget() => _buildPauseTarget(
        context: context,
        profile: profile,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
      ),
      TitlePresentationTarget() => _buildCategoryEditor(
        context: context,
        category: ProjectPresentationCategory.branding,
        profile: profile,
        projectName: projectName,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
        presets: presets,
        canManagePresets: canManagePresets,
      ),
      IntroPresentationTarget() => _buildCategoryEditor(
        context: context,
        category: ProjectPresentationCategory.intro,
        profile: profile,
        projectName: projectName,
        projectRootPath: projectRootPath,
        notifier: notifier,
        canEdit: canEdit,
        presets: presets,
        canManagePresets: canManagePresets,
      ),
    };
    return KeyedSubtree(
      key: ValueKey<String>(
        'personalization-target-editor-${_inspectorTargetId(target)}',
      ),
      child: editor,
    );
  }

  Widget _buildGlobalStyleTarget({
    required BuildContext context,
    required PersonalizationGlobalStyleSection section,
    required ProjectPresentationProfile profile,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (_isImportingAsset) ...<Widget>[
        const PokeMapDiagnosticCallout(
          key: ValueKey<String>('personalization-studio-asset-progress'),
          severity: PokeMapDiagnosticSeverity.info,
          message: 'Validation et copie sécurisée de la police en cours…',
        ),
        const SizedBox(height: 12),
      ],
      if (_assetFeedback != null) ...<Widget>[
        PokeMapDiagnosticCallout(
          key: const ValueKey<String>('personalization-studio-asset-feedback'),
          severity: _assetFeedbackIsError
              ? PokeMapDiagnosticSeverity.error
              : PokeMapDiagnosticSeverity.info,
          message: _assetFeedback!,
        ),
        const SizedBox(height: 12),
      ],
      IgnorePointer(
        ignoring: !canEdit || _isImportingAsset,
        child: PersonalizationGlobalStyleInspector(
          profile: profile,
          section: section,
          previewFamilies: _fontPreviewFamilies,
          onSectionChanged: (selectedSection) {
            setState(
              () => _selectedTarget = switch (selectedSection) {
                PersonalizationGlobalStyleSection.colors =>
                  const GlobalColorsTarget(),
                PersonalizationGlobalStyleSection.forms =>
                  const GlobalFormsTarget(),
                PersonalizationGlobalStyleSection.typography =>
                  const GlobalTypographyTarget(),
              },
            );
          },
          onEditAccent: () {
            unawaited(
              _editGlobalStyleAccent(
                context: context,
                profile: profile,
                notifier: notifier,
              ),
            );
          },
          onEditThemeToken: (token) {
            unawaited(
              _editGlobalStyleThemeToken(
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
          onWindowsChanged: (windows) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(windows: windows),
                label: 'Modifier la forme globale des fenêtres',
              ),
            );
          },
          onImportCommonFont: () {
            unawaited(
              _importFont(
                context: context,
                projectRootPath: projectRootPath,
                profile: profile,
                role: ProjectTypographyRole.body,
                notifier: notifier,
                applyToAllRoles: true,
              ),
            );
          },
          onUseSystemCommonFont: () {
            unawaited(
              _useSystemCommonFont(profile: profile, notifier: notifier),
            );
          },
          onResetColors: () {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(
                  branding: profile.branding.copyWith(accentColor: null),
                  theme: null,
                ),
                label: 'Réinitialiser les couleurs globales',
              ),
            );
          },
          onResetWindows: () {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(windows: null),
                label: 'Réinitialiser les fenêtres globales',
              ),
            );
          },
          onResetTypography: () {
            unawaited(
              _resetGlobalTypography(profile: profile, notifier: notifier),
            );
          },
          onCommonMetricsChanged: (metrics) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(
                  typography: _replaceCommonTypographyMetrics(
                    profile.typography ?? const ProjectTypographyProfile(),
                    metrics,
                  ),
                ),
                label: 'Modifier les réglages du texte commun',
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildPauseTarget({
    required BuildContext context,
    required ProjectPresentationProfile profile,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (_isImportingAsset) ...<Widget>[
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          message: 'Validation et copie sécurisée de la police en cours…',
        ),
        const SizedBox(height: 12),
      ],
      if (_assetFeedback != null) ...<Widget>[
        PokeMapDiagnosticCallout(
          severity: _assetFeedbackIsError
              ? PokeMapDiagnosticSeverity.error
              : PokeMapDiagnosticSeverity.info,
          message: _assetFeedback!,
        ),
        const SizedBox(height: 12),
      ],
      IgnorePointer(
        ignoring: !canEdit || _isImportingAsset,
        child: PersonalizationPauseInspector(
          profile: profile,
          previewFamilies: _fontPreviewFamilies,
          onMenuLabelsChanged: (menuLabels) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(menuLabels: menuLabels),
                label: 'Modifier les libellés du menu Pause',
              ),
            );
          },
          onWindowsChanged: (windows) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(windows: windows),
                label: 'Modifier l’apparence du menu Pause',
              ),
            );
          },
          onSurfacePalettesChanged: (surfacePalettes) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(surfacePalettes: surfacePalettes),
                label: 'Modifier les couleurs du menu Pause',
              ),
            );
          },
          onLayoutsChanged: (layouts) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(layouts: layouts),
                label: 'Modifier la disposition du menu Pause',
              ),
            );
          },
          onImportCommonFont: () {
            unawaited(
              _importFont(
                context: context,
                projectRootPath: projectRootPath,
                profile: profile,
                role: ProjectTypographyRole.body,
                notifier: notifier,
                applyToAllRoles: true,
              ),
            );
          },
          onUseSystemCommonFont: () {
            unawaited(
              _useSystemCommonFont(profile: profile, notifier: notifier),
            );
          },
          onCommonMetricsChanged: (metrics) {
            unawaited(
              notifier.applyPersonalizationStudioProfile(
                profile.copyWith(
                  typography: _replaceCommonTypographyMetrics(
                    profile.typography ?? const ProjectTypographyProfile(),
                    metrics,
                  ),
                ),
                label: 'Modifier le texte du menu Pause',
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildDialogueTarget({
    required BuildContext context,
    required ProjectPresentationProfile profile,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
    required List<PersonalizationCharacterPreviewOption> characterOptions,
  }) {
    final typography = profile.typography ?? const ProjectTypographyProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_isImportingAsset) ...<Widget>[
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            message: 'Validation et copie sécurisée de la police en cours…',
          ),
          const SizedBox(height: 12),
        ],
        if (_assetFeedback != null) ...<Widget>[
          PokeMapDiagnosticCallout(
            severity: _assetFeedbackIsError
                ? PokeMapDiagnosticSeverity.error
                : PokeMapDiagnosticSeverity.info,
            message: _assetFeedback!,
          ),
          const SizedBox(height: 12),
        ],
        IgnorePointer(
          ignoring: !canEdit || _isImportingAsset,
          child: PersonalizationDialogueInspector(
            profile: profile,
            characterOptions: characterOptions,
            selectedCharacterId: _selectedDialogueCharacterId,
            showPortrait: _showDialoguePortrait,
            showName: _showDialogueName,
            showChoices: _showDialogueChoices,
            previewFamilies: _fontPreviewFamilies,
            onCharacterSelected: (characterId) {
              setState(() => _selectedDialogueCharacterId = characterId);
            },
            onShowPortraitChanged: (value) {
              setState(() => _showDialoguePortrait = value);
            },
            onShowNameChanged: (value) {
              setState(() => _showDialogueName = value);
            },
            onShowChoicesChanged: (value) {
              setState(() => _showDialogueChoices = value);
            },
            onWindowsChanged: (windows) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(windows: windows),
                  label: 'Modifier l’apparence de la bulle de dialogue',
                ),
              );
            },
            onSurfacePalettesChanged: (surfacePalettes) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(surfacePalettes: surfacePalettes),
                  label: 'Modifier les couleurs des dialogues',
                ),
              );
            },
            onLayoutsChanged: (layouts) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(layouts: layouts),
                  label: 'Modifier la disposition de la bulle de dialogue',
                ),
              );
            },
            onImportDialogueFont: () {
              unawaited(
                _importFont(
                  context: context,
                  projectRootPath: projectRootPath,
                  profile: profile,
                  role: ProjectTypographyRole.dialogue,
                  notifier: notifier,
                ),
              );
            },
            onUseSystemDialogueFont: () {
              final current = typography.dialogue;
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(
                    typography: typography.copyWith(
                      dialogue: ProjectTypographyRoleProfile(
                        fallbackFamilies: current.fallbackFamilies,
                      ),
                    ),
                  ),
                  label: 'Utiliser le fallback Dialogues',
                ),
              );
              setState(
                () =>
                    _fontPreviewFamilies.remove(ProjectTypographyRole.dialogue),
              );
            },
            onDialogueMetricsChanged: (metrics) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(
                    typography: _replaceTypographyRoleMetrics(
                      typography,
                      ProjectTypographyRole.dialogue,
                      metrics,
                    ),
                  ),
                  label: 'Modifier le texte des dialogues',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBattleTarget({
    required BuildContext context,
    required ProjectPresentationProfile profile,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
  }) {
    final typography = profile.typography ?? const ProjectTypographyProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_isImportingAsset) ...<Widget>[
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            message: 'Validation et copie sécurisée de la police en cours…',
          ),
          const SizedBox(height: 12),
        ],
        if (_assetFeedback != null) ...<Widget>[
          PokeMapDiagnosticCallout(
            severity: _assetFeedbackIsError
                ? PokeMapDiagnosticSeverity.error
                : PokeMapDiagnosticSeverity.info,
            message: _assetFeedback!,
          ),
          const SizedBox(height: 12),
        ],
        IgnorePointer(
          ignoring: !canEdit || _isImportingAsset,
          child: PersonalizationBattleInspector(
            profile: profile,
            previewState: _battlePreviewState,
            previewFamilies: _fontPreviewFamilies,
            onPreviewStateChanged: (state) {
              setState(() => _battlePreviewState = state);
            },
            onWindowsChanged: (windows) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(windows: windows),
                  label: 'Modifier l’apparence du menu de combat',
                ),
              );
            },
            onSurfacePalettesChanged: (surfacePalettes) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(surfacePalettes: surfacePalettes),
                  label: 'Modifier les couleurs des combats',
                ),
              );
            },
            onLayoutsChanged: (layouts) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(layouts: layouts),
                  label: 'Modifier la disposition du menu de combat',
                ),
              );
            },
            onImportCombatFont: () {
              unawaited(
                _importFont(
                  context: context,
                  projectRootPath: projectRootPath,
                  profile: profile,
                  role: ProjectTypographyRole.combat,
                  notifier: notifier,
                ),
              );
            },
            onUseSystemCombatFont: () {
              final current = typography.combat ?? typography.body;
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(
                    typography: typography.copyWith(
                      combat: ProjectTypographyRoleProfile(
                        fallbackFamilies: current.fallbackFamilies,
                      ),
                    ),
                  ),
                  label: 'Utiliser le fallback Combats',
                ),
              );
              setState(
                () => _fontPreviewFamilies.remove(ProjectTypographyRole.combat),
              );
            },
            onCombatMetricsChanged: (metrics) {
              unawaited(
                notifier.applyPersonalizationStudioProfile(
                  profile.copyWith(
                    typography: _replaceTypographyRoleMetrics(
                      typography,
                      ProjectTypographyRole.combat,
                      metrics,
                    ),
                  ),
                  label: 'Modifier le texte des combats',
                ),
              );
            },
          ),
        ),
      ],
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
    final canEdit =
        studioSession?.isInitialized == true &&
        studioSession?.hasFailed == false &&
        studioSession?.isConflicted == false &&
        studioSession?.isSaving == false;
    final profile =
        studioSession?.draftProfile ?? project.effectivePresentation;
    final baselineProfile = studioSession?.savedProfile;
    final hasBlockingDiagnostics = validateProjectPresentationProfile(profile)
        .any(
          (diagnostic) =>
              diagnostic.severity ==
              ProjectPresentationDiagnosticSeverity.error,
        );
    final isPreflightStale =
        _preflightResult != null &&
        (_preflightProjectRootPath != projectRootPath ||
            _preflightProfile != profile);
    final activePreflightResult = isPreflightStale ? null : _preflightResult;
    final previewContextState = ref.watch(
      personalizationPreviewContextOptionsProvider(projectRootPath),
    );
    final previewContexts =
        previewContextState.value ??
        const <PersonalizationPreviewContextOption>[];
    final characterOptions =
        _selectedScene == PersonalizationStudioScene.dialogue
        ? _characterOptionsFromContexts(previewContexts)
        : const <PersonalizationCharacterPreviewOption>[];
    final dialogueCharacter = _resolveDialogueCharacter(
      characterOptions,
      _selectedDialogueCharacterId,
    );

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
                  if (hasBlockingDiagnostics)
                    const PokeMapBadge(
                      key: ValueKey<String>(
                        'personalization-studio-validation-blocked',
                      ),
                      label: 'Contraste à corriger',
                      variant: PokeMapBadgeVariant.error,
                      icon: Icon(Icons.error_outline_rounded),
                    ),
                  PokeMapButton(
                    key: const ValueKey<String>('personalization-studio-undo'),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.undo_rounded),
                    onPressed: studioSession?.canUndo == true && canEdit
                        ? () {
                            unawaited(notifier.undoPersonalizationStudio());
                          }
                        : null,
                    child: const Text('Annuler'),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>('personalization-studio-redo'),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.redo_rounded),
                    onPressed: studioSession?.canRedo == true && canEdit
                        ? () {
                            unawaited(notifier.redoPersonalizationStudio());
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
                    key: const ValueKey<String>('personalization-studio-save'),
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.save_outlined),
                    isLoading: studioSession?.isSaving == true,
                    onPressed:
                        studioSession?.isDirty == true &&
                            canEdit &&
                            !hasBlockingDiagnostics
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
            child: PersonalizationStudioShell(
              key: const ValueKey<String>('personalization-studio-workspace'),
              selectedScene: _selectedScene,
              onSceneSelected: (scene) {
                setState(() {
                  _selectedScene = scene;
                  _selectedTarget = _defaultInspectorTarget(scene);
                });
              },
              preview: PersonalizationLivePreview(
                profile: profile,
                projectName: project.name,
                projectRootPath: projectRootPath,
                baselineProfile: baselineProfile,
                scene: _selectedScene,
                dialogueCharacter: dialogueCharacter,
                showDialoguePortrait: _showDialoguePortrait,
                showDialogueName: _showDialogueName,
                showDialogueChoices: _showDialogueChoices,
                battleState: _battlePreviewState,
                contentSource: PersonalizationPreviewContentSource.project,
                contexts: previewContexts,
                contextsLoading:
                    previewContextState.isLoading && previewContexts.isEmpty,
                contextsErrorMessage: previewContextState.hasError
                    ? 'Les données du projet nécessaires à l’aperçu '
                          'n’ont pas pu être chargées.'
                    : null,
                projectManifest: project,
                resolveTilesetPath: notifier.getTilesetAbsolutePathById,
                onTargeted: (target) {
                  setState(() {
                    _selectedScene = _sceneForInspectorTarget(target);
                    _selectedTarget = target;
                  });
                },
              ),
              inspectorTitle: PersonalizationStudioSceneDescriptor.forSurface(
                _selectedScene,
              ).label,
              inspectorDescription: _sceneDescription(_selectedScene),
              selectedTarget: _selectedTarget,
              onTargetSelected: (target) {
                setState(() => _selectedTarget = target);
              },
              inspector: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PersonalizationSectionActions(
                    profile: profile,
                    category: _categoryForInspectorTarget(_selectedTarget),
                    baselineProfile: baselineProfile,
                    onProfileChanged: canEdit
                        ? (updatedProfile) {
                            unawaited(
                              notifier.applyPersonalizationStudioProfile(
                                updatedProfile,
                              ),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildInspectorEditor(
                    context: context,
                    target: _selectedTarget,
                    profile: profile,
                    projectName: project.name,
                    projectRootPath: projectRootPath,
                    notifier: notifier,
                    canEdit: canEdit,
                    presets: project.presentationPresets,
                    canManagePresets: canEdit && studioSession?.isDirty != true,
                    characterOptions: characterOptions,
                  ),
                  const SizedBox(height: 16),
                  PersonalizationReadinessPanel(
                    report:
                        activePreflightResult?.report ??
                        PersonalizationPublishReadiness.fromProfile(profile),
                    onCorrectIssue: (issue) {
                      setState(() {
                        _selectedScene = _sceneForCategory(issue.category);
                        _selectedTarget = _targetForCategory(issue.category);
                      });
                      if (issue.correctionKind ==
                          PersonalizationCorrectionKind.useSafeTheme) {
                        unawaited(
                          notifier.applyPersonalizationStudioProfile(
                            profile.copyWith(theme: safeProjectSemanticTheme),
                          ),
                        );
                      }
                    },
                    requiresPreflight: true,
                    hasCompletedPreflight: _preflightResult != null,
                    isPreflightRunning: _isPreflightRunning,
                    isPreflightStale: isPreflightStale,
                    hasUnsavedChanges: studioSession?.isDirty == true,
                    preflightError: _preflightError,
                    onRunPreflight: canEdit && !_isPreflightRunning
                        ? () {
                            unawaited(
                              _runPreflight(
                                projectRootPath: projectRootPath,
                                profile: profile,
                              ),
                            );
                          }
                        : null,
                    onSaveDraft:
                        studioSession?.isDirty == true &&
                            canEdit &&
                            !hasBlockingDiagnostics
                        ? () {
                            unawaited(notifier.savePersonalizationStudio());
                          }
                        : null,
                    canContinueToExport:
                        activePreflightResult != null &&
                        activePreflightResult.report.isReadyToExport &&
                        studioSession?.isDirty != true &&
                        !_isPreflightRunning &&
                        _preflightError == null &&
                        canEdit,
                    onContinueToExport:
                        activePreflightResult != null &&
                            activePreflightResult.report.isReadyToExport &&
                            studioSession?.isDirty != true &&
                            !_isPreflightRunning &&
                            _preflightError == null &&
                            canEdit
                        ? () {
                            unawaited(
                              ref.read(
                                personalizationStudioExportLauncherProvider,
                              )(
                                context,
                                projectRootPath: projectRootPath,
                                projectName: project.name,
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PersonalizationInspectorTarget _defaultInspectorTarget(
  PersonalizationStudioScene scene,
) => switch (scene) {
  PersonalizationStudioScene.globalStyle => const GlobalColorsTarget(),
  PersonalizationStudioScene.title => const TitlePresentationTarget(),
  PersonalizationStudioScene.intro => const IntroPresentationTarget(),
  PersonalizationStudioScene.pause => const PauseLabelsTarget(),
  PersonalizationStudioScene.dialogue => const DialogueAppearanceTarget(),
  PersonalizationStudioScene.battle => const BattleCommandsTarget(),
};

PersonalizationStudioScene _sceneForInspectorTarget(
  PersonalizationInspectorTarget target,
) => switch (target) {
  GlobalColorsTarget() ||
  GlobalTypographyTarget() ||
  GlobalFormsTarget() => PersonalizationStudioScene.globalStyle,
  TitlePresentationTarget() => PersonalizationStudioScene.title,
  IntroPresentationTarget() => PersonalizationStudioScene.intro,
  PauseLabelsTarget() ||
  PauseAppearanceTarget() ||
  PauseLayoutTarget() => PersonalizationStudioScene.pause,
  DialogueAppearanceTarget() ||
  DialogueTypographyTarget() ||
  DialogueLayoutTarget() => PersonalizationStudioScene.dialogue,
  BattleCommandsTarget() ||
  BattleAppearanceTarget() => PersonalizationStudioScene.battle,
};

ProjectPresentationCategory _categoryForInspectorTarget(
  PersonalizationInspectorTarget target,
) => switch (target) {
  TitlePresentationTarget() => ProjectPresentationCategory.branding,
  IntroPresentationTarget() => ProjectPresentationCategory.intro,
  GlobalTypographyTarget() ||
  DialogueTypographyTarget() => ProjectPresentationCategory.typography,
  PauseLayoutTarget() ||
  DialogueLayoutTarget() => ProjectPresentationCategory.layouts,
  GlobalColorsTarget() ||
  GlobalFormsTarget() ||
  PauseLabelsTarget() ||
  PauseAppearanceTarget() ||
  DialogueAppearanceTarget() ||
  BattleCommandsTarget() ||
  BattleAppearanceTarget() => ProjectPresentationCategory.theme,
};

PersonalizationStudioScene _sceneForCategory(
  ProjectPresentationCategory category,
) => switch (category) {
  ProjectPresentationCategory.branding => PersonalizationStudioScene.title,
  ProjectPresentationCategory.intro => PersonalizationStudioScene.intro,
  ProjectPresentationCategory.typography ||
  ProjectPresentationCategory.theme => PersonalizationStudioScene.globalStyle,
  ProjectPresentationCategory.layouts => PersonalizationStudioScene.pause,
};

PersonalizationCharacterPreviewOption? _resolveDialogueCharacter(
  List<PersonalizationCharacterPreviewOption> options,
  String? selectedCharacterId,
) {
  if (options.isEmpty) return null;
  for (final option in options) {
    if (option.characterId == selectedCharacterId) return option;
  }
  return options.first;
}

List<PersonalizationCharacterPreviewOption> _characterOptionsFromContexts(
  List<PersonalizationPreviewContextOption> contexts,
) => List.unmodifiable(
  contexts
      .where(
        (context) =>
            context.kind == PersonalizationPreviewContextKind.characterPortrait,
      )
      .map(
        (context) => PersonalizationCharacterPreviewOption(
          characterId: context.sourceId,
          displayName:
              context.detail['characterName'] as String? ?? context.label,
          portraitPath: context.detail['portraitPath'] as String?,
          expressionId: context.detail['portraitStateId'] as String?,
          portraitBytes: context.mediaBytes,
        ),
      ),
);

PersonalizationInspectorTarget _targetForCategory(
  ProjectPresentationCategory category,
) => switch (category) {
  ProjectPresentationCategory.branding => const TitlePresentationTarget(),
  ProjectPresentationCategory.intro => const IntroPresentationTarget(),
  ProjectPresentationCategory.typography => const GlobalTypographyTarget(),
  ProjectPresentationCategory.theme => const GlobalColorsTarget(),
  ProjectPresentationCategory.layouts => const PauseLayoutTarget(),
};

String _sceneDescription(PersonalizationStudioScene scene) => switch (scene) {
  PersonalizationStudioScene.globalStyle =>
    'Couleurs, formes et typographie communes.',
  PersonalizationStudioScene.title =>
    'Titre, visuels et présentation de l’écran d’accueil.',
  PersonalizationStudioScene.intro =>
    'Vidéo, poster et comportement d’introduction.',
  PersonalizationStudioScene.pause =>
    'Libellés, apparence et disposition du menu de pause.',
  PersonalizationStudioScene.dialogue =>
    'Bulle, texte et disposition des dialogues.',
  PersonalizationStudioScene.battle =>
    'Commandes et présentation de l’interface de combat.',
};

String _inspectorTargetId(PersonalizationInspectorTarget target) =>
    switch (target) {
      GlobalColorsTarget() => 'globalColors',
      GlobalTypographyTarget() => 'globalTypography',
      GlobalFormsTarget() => 'globalForms',
      TitlePresentationTarget() => 'titlePresentation',
      IntroPresentationTarget() => 'introPresentation',
      PauseLabelsTarget() => 'pauseLabels',
      PauseAppearanceTarget() => 'pauseAppearance',
      PauseLayoutTarget() => 'pauseLayout',
      DialogueAppearanceTarget() => 'dialogueAppearance',
      DialogueTypographyTarget() => 'dialogueTypography',
      DialogueLayoutTarget() => 'dialogueLayout',
      BattleCommandsTarget() => 'battleCommands',
      BattleAppearanceTarget() => 'battleAppearance',
    };

String _categoryName(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'branding',
      ProjectPresentationCategory.intro => 'intro vidéo',
      ProjectPresentationCategory.typography => 'typographie',
      ProjectPresentationCategory.theme => 'thème et HUD',
      ProjectPresentationCategory.layouts => 'mise en page',
    };

ProjectTypographyRoleProfile _typographyRoleProfile(
  ProjectTypographyProfile profile,
  ProjectTypographyRole role,
) => switch (role) {
  ProjectTypographyRole.display => profile.display,
  ProjectTypographyRole.body => profile.body,
  ProjectTypographyRole.dialogue => profile.dialogue,
  ProjectTypographyRole.combat => profile.combat ?? profile.body,
  ProjectTypographyRole.numbers => profile.numbers,
};

ProjectTypographyProfile _replaceTypographyRole(
  ProjectTypographyProfile profile,
  ProjectTypographyRole role,
  ProjectTypographyRoleProfile replacement,
) => switch (role) {
  ProjectTypographyRole.display => profile.copyWith(display: replacement),
  ProjectTypographyRole.body => profile.copyWith(body: replacement),
  ProjectTypographyRole.dialogue => profile.copyWith(dialogue: replacement),
  ProjectTypographyRole.combat => profile.copyWith(combat: replacement),
  ProjectTypographyRole.numbers => profile.copyWith(numbers: replacement),
};

ProjectTypographyProfile _replaceTypographyRoleMetrics(
  ProjectTypographyProfile profile,
  ProjectTypographyRole role,
  ProjectTypographyMetricsProfile metrics,
) => _replaceTypographyRole(
  profile,
  role,
  _typographyRoleProfile(profile, role).copyWith(metrics: metrics),
);

ProjectTypographyProfile _replaceCommonTypographyMetrics(
  ProjectTypographyProfile profile,
  ProjectTypographyMetricsProfile metrics,
) => profile.copyWith(
  display: profile.display.copyWith(metrics: metrics),
  body: profile.body.copyWith(metrics: metrics),
  dialogue: profile.dialogue.copyWith(metrics: metrics),
  combat: (profile.combat ?? profile.body).copyWith(metrics: metrics),
  numbers: profile.numbers.copyWith(metrics: metrics),
);

String _typographyRoleName(ProjectTypographyRole role) => switch (role) {
  ProjectTypographyRole.display => 'Titres & affichage',
  ProjectTypographyRole.body => 'Texte courant',
  ProjectTypographyRole.dialogue => 'Dialogues',
  ProjectTypographyRole.combat => 'Combats',
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
) => switch (token) {
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
  'overworldHudSurface' => 'Surface exploration',
  'battleHudSurface' => 'Fond du combat',
  _ => token,
};

ProjectBrandingProfile _replaceBrandingImagePath(
  ProjectBrandingProfile profile,
  ProjectBrandingImageRole role,
  String? path,
) => switch (role) {
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
) => switch (error.code) {
  'brandingImageMissing' => 'L’image sélectionnée est introuvable.',
  'brandingImageFormatUnsupported' => 'Choisissez une image PNG, JPEG ou WebP.',
  'brandingImageCorrupt' => 'L’image sélectionnée ne peut pas être décodée.',
  'brandingImageSizeExceeded' => 'L’image dépasse la limite de 10 Mio.',
  'brandingImageDimensionsExceeded' =>
    'L’image dépasse 4096 pixels sur au moins un côté.',
  'brandingIconMustBeSquare' => 'L’icône du jeu doit être carrée.',
  'brandingIconDimensionsUnsupported' =>
    'L’icône doit mesurer entre 64 × 64 et 1024 × 1024 pixels.',
  'brandingCoverDimensionsUnsupported' =>
    'La cover doit mesurer au minimum 640 × 360 pixels.',
  'brandingHeroDimensionsUnsupported' =>
    'Le logo / hero doit mesurer au minimum 256 × 128 pixels.',
  'brandingImageWriteFailed' =>
    'L’image validée n’a pas pu être copiée dans le projet.',
  _ => error.message,
};

String _localizedTitleMusicImportError(
  ProjectTitleMusicImportException error,
) => switch (error.code) {
  'titleMusicMissing' => 'La musique sélectionnée est introuvable.',
  'titleMusicFormatUnsupported' =>
    'Choisissez un fichier OGG, WAV, MP3, FLAC ou M4A.',
  'titleMusicSignatureInvalid' =>
    'La signature audio ne correspond pas à l’extension du fichier.',
  'titleMusicSizeExceeded' =>
    'La musique du titre dépasse la limite de 30 Mio.',
  'titleMusicWriteFailed' =>
    'La musique validée n’a pas pu être copiée dans le projet.',
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

String _presetFailureMessage(Object error) {
  final value = error.toString();
  if (value.contains('presentation.preset.asset_unmanaged')) {
    return 'Un asset de ce profil n’est pas encore géré par le catalogue du '
        'projet. Réimporte-le depuis le Studio avant l’export.';
  }
  if (value.contains('presentation.preset.license_required') ||
      value.contains('presentation.preset.license_invalid')) {
    return 'Chaque asset partagé doit posséder une licence de redistribution '
        'texte valide.';
  }
  if (value.contains('presentation.preset')) {
    return 'Ce profil .pokemapstyle est invalide, incompatible ou déjà présent.';
  }
  return 'La bibliothèque de profils n’a pas pu terminer cette opération.';
}

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
