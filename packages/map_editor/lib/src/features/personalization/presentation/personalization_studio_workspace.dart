import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_diagnostic_callout.dart';
import '../../../ui/design_system/pokemap_empty_state.dart';
import '../../../ui/design_system/pokemap_toggle_tile.dart';
import '../../editor/state/editor_notifier.dart';
import '../application/project_intro_video_import_service.dart';
import 'personalization_hub_shell.dart';
import 'project_intro_video_editor.dart';

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

  Future<void> _importIntroVideo({
    required String projectRootPath,
    required ProjectPresentationProfile profile,
    required EditorNotifier notifier,
  }) async {
    if (_isImportingAsset) return;
    final selection = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choisir la vidéo, le poster et les sous-titres optionnels',
      type: FileType.custom,
      allowedExtensions: const <String>[
        'mp4',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'vtt',
      ],
      allowMultiple: true,
      withData: false,
      lockParentWindow: true,
    );
    if (!mounted || selection == null) return;
    final paths = selection.files
        .map((file) => file.path)
        .whereType<String>()
        .toList(growable: false);
    final videoPath = _singlePathWithExtensions(paths, const <String>['.mp4']);
    final posterPath = _singlePathWithExtensions(
      paths,
      const <String>['.png', '.jpg', '.jpeg', '.webp'],
    );
    final captionsPath =
        _singlePathWithExtensions(paths, const <String>['.vtt']);
    if (videoPath == null || posterPath == null) {
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback =
            'Sélectionnez exactement une vidéo MP4 et un poster PNG, JPEG ou WebP.';
      });
      return;
    }

    setState(() {
      _isImportingAsset = true;
      _assetFeedback = null;
    });
    try {
      final imported =
          await const ProjectIntroVideoImportService().importIntoProject(
        projectRoot: Directory(projectRootPath),
        videoFile: File(videoPath),
        posterFile: File(posterPath),
        captionsFile: captionsPath == null ? null : File(captionsPath),
        reducedMotionBehavior: profile.intro?.reducedMotionBehavior ?? 'poster',
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
    } on ProjectIntroVideoImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _assetFeedbackIsError = true;
        _assetFeedback = error.message;
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
    required ProjectPresentationCategory category,
    required ProjectPresentationProfile profile,
    required String projectRootPath,
    required EditorNotifier notifier,
    required bool canEdit,
  }) {
    if (category != ProjectPresentationCategory.intro) {
      return Text(
        'Les réglages ${_categoryName(category)} apparaîtront ici.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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

String? _singlePathWithExtensions(
  List<String> paths,
  List<String> extensions,
) {
  final matches = paths.where((path) {
    final lower = path.toLowerCase();
    return extensions.any(lower.endsWith);
  }).toList(growable: false);
  return matches.length == 1 ? matches.single : null;
}

String _categoryName(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'branding',
      ProjectPresentationCategory.intro => 'intro vidéo',
      ProjectPresentationCategory.typography => 'typographie',
      ProjectPresentationCategory.theme => 'thème et HUD',
    };
