part of 'presentation_workspace_page.dart';

extension _PresentationDocumentSettings on _PresentationWorkspacePageState {
  Future<void> documentSettings(String owner) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, rebuild) {
          final session = controller.active;
          if (session == null || session.asset.id != owner) {
            return const SizedBox.shrink();
          }
          return AlertDialog(
            title: const Text('Durée et classement'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StudioCommitField(
                    label: 'Durée du montage (s)',
                    value: '${session.asset.durationUs / 1000000}',
                    tryCommit: (text) {
                      final valid = commitPresentationField(
                        view?.invalidFields ?? <String>{},
                        presentationDocumentDurationField,
                        parsePresentationDocumentDurationUs(text),
                        (durationUs) => controller.apply(
                          'presentationCinematic.update',
                          presentationDurationUpdate(
                            session.asset,
                            durationUs as int,
                          ),
                        ),
                      );
                      rebuild(() {});
                      return valid;
                    },
                  ),
                  const SizedBox(height: 12),
                  StudioSelect(
                    label: 'Classer dans',
                    value: session.folderId ?? '',
                    options: {
                      '': 'Sans dossier',
                      for (final folder in controller.catalog.folders)
                        folder.id: folder.name,
                    },
                    onChanged: (id) {
                      controller.setFolder(owner, id.isEmpty ? null : id);
                      rebuild(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  StudioButton(
                    label: 'Créer un dossier',
                    secondary: true,
                    onPressed: () async {
                      final name = await askNarrativeName(
                        context,
                        'Nouveau dossier de cinématiques',
                      );
                      if (name == null || controller.activeId != owner) return;
                      final id = await controller.createFolder(name);
                      if (id != null && controller.activeId == owner) {
                        controller.setFolder(owner, id);
                      }
                      if (context.mounted) rebuild(() {});
                    },
                  ),
                  if (controller.error case final error?)
                    StudioNotice(error, isError: true),
                ],
              ),
            ),
            actions: [
              StudioButton(
                label: 'Terminer',
                onPressed: () {
                  if (flush()) Navigator.pop(dialogContext);
                },
              ),
            ],
          );
        },
      ),
    );
    refresh();
  }
}
