part of 'project_library_page.dart';

extension _ProjectLibraryPacks on _ProjectLibraryPageState {
  ResourcePackTransferController? _createPackTransfer() {
    final port = widget.packPort;
    if (port == null) return null;
    late final ResourcePackTransferController transfer;
    transfer = ResourcePackTransferController(
      port: port,
      picker: () => widget.pickPack!(),
      accept: (receipt) => _acceptPackReceipt(transfer, receipt),
    );
    return transfer;
  }

  Future<void> _importPack(BuildContext context) async {
    final transfer = _packTransfer;
    if (!mounted ||
        !context.mounted ||
        !widget.active ||
        _pickingFile ||
        transfer == null ||
        transfer.routeActive) {
      return;
    }
    transfer.routeActive = true;
    _packWorkspace = widget.maps;
    final onDialogChanged = widget.onPackDialogChanged;
    onDialogChanged?.call(true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProjectLibraryPackDialog(transfer: transfer),
      );
    } finally {
      if (mounted && _packTransfer == transfer) {
        transfer.routeActive = false;
        _packWorkspace = null;
        onDialogChanged?.call(false);
      }
    }
  }

  Future<void> _acceptPackReceipt(
    ResourcePackTransferController transfer,
    ResourceMutationReceipt receipt,
  ) async {
    final maps = _packWorkspace;
    bool current() =>
        mounted && _packTransfer == transfer && widget.maps == maps;
    if (maps == null || !current() || !_acceptLibraryReceipt(receipt)) {
      throw const ResourceFailure(
        'La bibliothèque a changé pendant l’installation.',
      );
    }
    if (widget.visuals case final ScopedResourcePreviewVisuals previews) {
      previews.invalidateResourcePreviews(receipt.changedPaths.toSet());
    }
    final previousReading = _reading;
    final previous = await previousReading;
    final library = await _queryLibrary(maps, maps.project!);
    if (!current() || _reading != previousReading) {
      throw const ResourceFailure(
        'La bibliothèque a changé pendant la relecture.',
      );
    }
    final imported = transfer.firstImported;
    _updateView(
      () => _read(
        library: library,
        revealIdentity: imported == null
            ? null
            : '${imported.kind}:${imported.id}',
        publicationToken: (previous?.publication?.token ?? 0) + 1,
      ),
    );
  }
}
