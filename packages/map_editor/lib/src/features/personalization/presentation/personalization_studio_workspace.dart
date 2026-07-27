import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_empty_state.dart';
import '../../editor/state/editor_notifier.dart';
import 'personalization_hub_shell.dart';

/// Adapts the current editor project to the reusable Personalization Hub.
///
/// Phase 1 binds the shell to a crash-safe project presentation draft.
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
          if (studioSession?.isDirty == true)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: PokeMapBadge(
                  key: ValueKey<String>('personalization-studio-dirty'),
                  label: 'Modifications non enregistrées',
                  variant: PokeMapBadgeVariant.info,
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
