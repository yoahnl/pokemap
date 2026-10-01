import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'map_library_navigator.dart';
import 'map_catalogue_workspace_actions.dart';

class MapCatalogueEmptyView extends StatelessWidget {
  const MapCatalogueEmptyView({
    super.key,
    required this.controller,
    required this.onActivate,
    required this.onOrganize,
  });
  final MapWorkspaceController controller;
  final ValueChanged<ProjectMapEntry> onActivate;
  final OrganizeMapLibrary? onOrganize;

  @override
  Widget build(BuildContext context) {
    final project = controller.project;
    if (project == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final message = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              project.maps.isEmpty
                  ? 'Votre première carte'
                  : 'Choisissez une carte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez une carte vide ou ouvrez une carte du navigateur.',
            ),
            const SizedBox(height: 16),
            StudioButton(
              label: 'Nouvelle carte',
              icon: Icons.add,
              onPressed:
                  controller.catalogPort == null || controller.catalogBusy
                  ? null
                  : () => createWorkspaceMap(context, controller),
            ),
          ],
        );
        return Row(
          children: [
            if (constraints.maxWidth >= 650)
              MapLibraryNavigator(
                project: project,
                activeMapId: null,
                dirtyMapIds: {
                  for (final entry in controller.documents.entries)
                    if (entry.value.dirty) entry.key,
                },
                onRetryCatalogue: controller.pendingCatalogReceipt == null
                    ? null
                    : () => controller.retryCatalogRefresh(),
                onActivate: onActivate,
                onOrganize: onOrganize,
                onCreateMap: controller.catalogPort == null
                    ? null
                    : (groupId) => createWorkspaceMap(
                        context,
                        controller,
                        groupId: groupId,
                      ),
                onRenameMap: controller.catalogPort == null
                    ? null
                    : (entry) => renameWorkspaceMap(context, controller, entry),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: message,
              ),
            ),
          ],
        );
      },
    );
  }
}
