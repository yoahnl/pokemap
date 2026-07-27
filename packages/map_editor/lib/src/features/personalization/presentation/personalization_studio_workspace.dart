import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_empty_state.dart';
import '../../editor/state/editor_selectors.dart';
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
    final project = ref.watch(editorProjectManifestProvider);
    if (project == null) {
      return const PokeMapEmptyState(
        key: ValueKey<String>('personalization-studio-project-pending'),
        title: 'Personalization Studio indisponible',
        description: 'Chargez un projet pour consulter sa personnalisation.',
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
