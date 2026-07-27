import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_empty_state.dart';
import '../../editor/state/editor_notifier.dart';
import 'personalization_hub_shell.dart';

/// Adapts the current editor project to the reusable Personalization Hub.
///
/// Phase 0 intentionally keeps the profile read-only: category selection is
/// local UI state and no profile mutation callback is exposed.
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          project: state.project,
          projectRootPath: state.projectRootPath,
          errorMessage: state.errorMessage,
        ),
      ),
    );
    final project = session.project;
    if (project == null) {
      final errorMessage = session.errorMessage?.trim();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        return PokeMapEmptyState(
          key: const ValueKey<String>('personalization-studio-error'),
          title: 'Personalization Studio indisponible',
          description: errorMessage,
          icon: const Icon(Icons.error_outline_rounded),
        );
      }

      final projectRootPath = session.projectRootPath?.trim();
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

    return Material(
      type: MaterialType.transparency,
      child: PersonalizationHubShell(
        key: const ValueKey<String>('personalization-studio-workspace'),
        profile: project.effectivePresentation,
        selectedCategory: _selectedCategory,
        onCategorySelected: (category) {
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }
}
