part of 'resource_library_view.dart';

extension _ResourceLibraryInspection on _ResourceLibraryViewState {
  Widget _inspector(
    ResourceLibraryItemView item,
    VoidCallback close,
    ValueChanged<ResourceLibraryItemView> select, {
    ValueChanged<ResourceLibraryItemView>? update,
    VoidCallback? dismissForWorkshop,
  }) {
    VoidCallback? action(ResourceLibraryEditAction? edit) => edit == null
        ? null
        : () async {
            final saved = await edit(context, item);
            if (saved != null && mounted) update?.call(saved);
          };
    final delete = widget.onDelete;
    final openWorkshop = widget.workshopAction?.call(item);
    return ResourceLibraryInspector(
      key: ValueKey('library-detail-${item.id}'),
      item: item,
      maps: widget.maps,
      source: widget.items
          .where((entry) => entry.id == item.sourceId)
          .firstOrNull,
      consumers: widget.items
          .where((entry) => entry.sourceId == item.id)
          .toList(),
      onClose: close,
      onRelated: select,
      preview: widget.detailPreview?.call(item),
      previewActions: widget.previewActions,
      onOpenWorkshop: openWorkshop == null
          ? null
          : () {
              dismissForWorkshop?.call();
              openWorkshop();
              _setSection(ResourceLibrarySection.workshops);
            },
      onRename: action(widget.onRename),
      onClassify: action(widget.onClassify),
      onModify: action(widget.onModify),
      onDuplicate: item.canDuplicate ? action(widget.onDuplicate) : null,
      onDelete: delete == null
          ? null
          : () async {
              if (await delete(context, item) && mounted) close();
            },
    );
  }

  Future<void> _select(
    ResourceLibraryItemView item, {
    required bool docked,
  }) async {
    _updateView(() {
      _selection = item.id;
      _showDetails = true;
    });
    if (docked) return;
    var detail = item;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) => FractionallySizedBox(
        heightFactor: .85,
        child: StatefulBuilder(
          builder: (context, setDetail) => _inspector(
            detail,
            () => Navigator.of(context).pop(),
            (target) {
              _updateView(() => _reveal(target));
              setDetail(() => detail = target);
            },
            update: (saved) {
              if (context.mounted) setDetail(() => detail = saved);
            },
            dismissForWorkshop: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
