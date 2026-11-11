part of 'resource_workspace_pane.dart';

extension ResourceWorkspaceActions on ResourceWorkspacePane {
  Future<void> import(
    BuildContext context, {
    ResourceImportIntent intent = ResourceImportIntent.source,
  }) async {
    final workflow = ResourceWorkspaceImportWorkflow(
      navigation: navigation,
      isActive: () => context.mounted,
    );
    await workflow.importImage(
      picker: picker,
      intent: intent,
      confirm: (image, project) => confirmImageImport(
        context,
        image,
        project.settings.tileWidth,
        project.settings.tileHeight,
        existingNames: {for (final tileset in project.tilesets) tileset.name},
        intent: intent,
      ),
    );
  }
}
