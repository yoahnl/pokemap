part of 'resource_library_view.dart';

extension _ResourceLibraryInspection on _ResourceLibraryViewState {
  Widget _inspection(
    ResourceLibraryItemView item,
    VoidCallback close, {
    VoidCallback? dismiss,
  }) => _ResourceLibraryInspectionTrail(
    key: ValueKey('library-inspection-${item.id}'),
    origin: item,
    lookup: widget.navigation?.item,
    buildDetail: (target, onRelated, onUpdate, onBack) => _inspector(
      target,
      close,
      onRelated,
      update: onUpdate,
      onBack: onBack,
      dismiss: dismiss,
    ),
  );

  Widget _inspector(
    ResourceLibraryItemView item,
    VoidCallback close,
    ValueChanged<ResourceLibraryItemView> select, {
    ValueChanged<ResourceLibraryItemView>? update,
    VoidCallback? onBack,
    VoidCallback? dismiss,
  }) {
    VoidCallback? action(ResourceLibraryEditAction? edit) => edit == null
        ? null
        : () async {
            final saved = await edit(context, item);
            if (saved != null && mounted) update?.call(saved);
          };
    final delete = widget.onDelete;
    final openWorkshop = widget.workshopAction?.call(item);
    final navigation = widget.navigation;
    final loadRelations = navigation?.loadRelations;
    final openMap = navigation?.openMap;
    return ResourceLibraryInspector(
      key: ValueKey('library-detail-${item.id}'),
      item: item,
      maps: widget.maps,
      source: switch (item.sourceId) {
        final id? =>
          navigation?.item(id) ??
              widget.items.where((entry) => entry.id == id).firstOrNull,
        null => null,
      },
      consumers: loadRelations == null && navigation == null
          ? widget.items.where((entry) => entry.sourceId == item.id).toList()
          : const [],
      relationsRevision: navigation?.revision,
      loadRelations: loadRelations == null
          ? null
          : () => loadRelations(item.id),
      onOpenMap: openMap == null
          ? null
          : (id) {
              if (_scope != ResourceLibraryScope.project) {
                _referenceMap ??= _map;
              }
              return openMap(id);
            },
      onMapOpened: dismiss,
      onClose: close,
      onBack: onBack,
      onRelated: select,
      preview: widget.detailPreview?.call(item),
      previewActions: widget.previewActions,
      onOpenWorkshop: openWorkshop == null
          ? null
          : () {
              dismiss?.call();
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        void dismiss() {
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop();
          }
        }

        return FractionallySizedBox(
          heightFactor: .85,
          child: FutureBuilder<void>(
            future: widget.navigation?.mapUsagesReady,
            builder: (context, snapshot) =>
                _inspection(item, dismiss, dismiss: dismiss),
          ),
        );
      },
    );
  }
}

class _ResourceLibraryInspectionTrail extends StatefulWidget {
  const _ResourceLibraryInspectionTrail({
    super.key,
    required this.origin,
    required this.lookup,
    required this.buildDetail,
  });

  final ResourceLibraryItemView origin;
  final ResourceLibraryItemView? Function(String)? lookup;
  final Widget Function(
    ResourceLibraryItemView,
    ValueChanged<ResourceLibraryItemView>,
    ValueChanged<ResourceLibraryItemView>,
    VoidCallback?,
  )
  buildDetail;

  @override
  State<_ResourceLibraryInspectionTrail> createState() =>
      _ResourceLibraryInspectionTrailState();
}

class _ResourceLibraryInspectionTrailState
    extends State<_ResourceLibraryInspectionTrail> {
  final _trail = <ResourceLibraryItemView>[];
  ResourceLibraryItemView? _updatedOrigin;

  @override
  void didUpdateWidget(_ResourceLibraryInspectionTrail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin) _updatedOrigin = null;
  }

  void _open(ResourceLibraryItemView item) => setState(() {
    if (item.id == widget.origin.id) {
      _trail.clear();
    } else {
      final previous = _trail.indexWhere((entry) => entry.id == item.id);
      if (previous < 0) {
        _trail.add(item);
      } else {
        _trail.removeRange(previous + 1, _trail.length);
      }
    }
  });

  void _update(ResourceLibraryItemView item) => setState(() {
    if (_trail.isEmpty) {
      _updatedOrigin = item;
    } else {
      _trail[_trail.length - 1] = item;
    }
  });

  @override
  Widget build(BuildContext context) {
    final selected = _trail.lastOrNull ?? _updatedOrigin ?? widget.origin;
    final item = widget.lookup?.call(selected.id) ?? selected;
    return widget.buildDetail(
      item,
      _open,
      _update,
      _trail.isEmpty ? null : () => setState(_trail.removeLast),
    );
  }
}
