import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart' show ResourceLibraryRole;

import '../../../../features/resources/domain/studio_search_text.dart';
import 'resource_library_controls.dart';
import 'resource_library_inspector.dart';
import 'resource_library_items.dart';
import 'resource_library_toolbar.dart';
import 'resource_library_view_data.dart';

part 'resource_library_results.dart';

class ResourceLibraryView extends StatefulWidget {
  const ResourceLibraryView({
    super.key,
    required this.items,
    required this.maps,
    this.workshops,
    this.onImport,
    this.onRefresh,
    this.detailPreview,
    this.tilePreview,
    this.familyLabels = const {},
    this.showRoles = false,
    this.showMapScopes = true,
    this.previewActions = false,
  });

  final List<ResourceLibraryItemView> items;
  final Map<String, String> maps;
  final Widget? workshops;
  final ValueChanged<BuildContext>? onImport;
  final VoidCallback? onRefresh;
  final Widget? Function(ResourceLibraryItemView)? detailPreview;
  final Widget? Function(ResourceLibraryItemView)? tilePreview;
  final Map<String, String> familyLabels;
  final bool showRoles;
  final bool showMapScopes;
  final bool previewActions;

  @override
  State<ResourceLibraryView> createState() => _ResourceLibraryViewState();
}

class _ResourceLibraryViewState extends State<ResourceLibraryView> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();
  var _section = ResourceLibrarySection.library;
  var _scope = ResourceLibraryScope.project;
  var _sort = ResourceLibrarySort.project;
  ResourceLibraryCategory? _category;
  var _role = ResourceLibraryRole.standard;
  String? _family;
  ResourceLibraryDimension? _dimension;
  String? _referenceMap;
  String? _selection;
  var _showDetails = true;
  var _grid = true;
  late Map<String, String> _searchable;
  late Map<String, String> _names;

  String? get _map => _referenceMap ?? widget.maps.keys.firstOrNull;
  Iterable<ResourceLibraryItemView> get _roleItems => widget.showRoles
      ? widget.items.where((item) => item.role == _role)
      : widget.items;

  @override
  void initState() {
    super.initState();
    if (widget.previewActions) _selection = widget.items.firstOrNull?.id;
    _indexItems();
  }

  @override
  void didUpdateWidget(ResourceLibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.items, oldWidget.items)) _indexItems();
    if (_family != null && !widget.familyLabels.containsKey(_family)) {
      _family = null;
    }
  }

  void _indexItems() {
    _names = {
      for (final item in widget.items) item.id: studioSearchText(item.name),
    };
    _searchable = {
      for (final item in widget.items)
        item.id: item.searchText ?? _names[item.id]!,
    };
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _inScope(ResourceLibraryItemView item, ResourceLibraryScope scope) =>
      switch (scope) {
        ResourceLibraryScope.project => true,
        ResourceLibraryScope.used => item.usedOn?.contains(_map) == true,
        ResourceLibraryScope.exclusive =>
          item.usedOn?.length == 1 && item.usedOn!.contains(_map),
      };

  void _focusSearch() {
    if (_section != ResourceLibrarySection.library) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _searchFocus.requestFocus();
  }

  void _reveal(ResourceLibraryItemView item) => setState(() {
    _selection = item.id;
    _showDetails = true;
    _role = item.role;
    if (_category != null && _category != item.category) _setCategory(null);
    if (_family != null && !item.familyIds.contains(_family)) _family = null;
    if (_dimension != null && _dimension != item.dimension) _dimension = null;
    if (!_inScope(item, _scope)) _scope = ResourceLibraryScope.project;
    if (!(_searchable[item.id] ?? '').contains(
      studioSearchText(_search.text).trim(),
    )) {
      _search.clear();
    }
  });

  Widget _inspector(
    ResourceLibraryItemView item,
    VoidCallback close,
    ValueChanged<ResourceLibraryItemView> select,
  ) => ResourceLibraryInspector(
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
  );

  Future<void> _select(
    ResourceLibraryItemView item, {
    required bool docked,
  }) async {
    setState(() {
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
          builder: (context, setDetail) =>
              _inspector(detail, () => Navigator.of(context).pop(), (target) {
                _reveal(target);
                setDetail(() => detail = target);
              }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _focusSearch,
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          _focusSearch,
    },
    child: Focus(
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final sidebar = bounds.maxWidth >= 740;
          final docked = bounds.maxWidth >= 910;
          final words = studioSearchText(_search.text)
              .trim()
              .split(RegExp(r'\s+'));
          final roleItems = _roleItems;
          final categoryCounts = <ResourceLibraryCategory, int>{};
          final matches = [
            for (final item in roleItems)
              if ((_category == null || _category == item.category) &&
                  (_family == null || item.familyIds.contains(_family)) &&
                  (_dimension == null || _dimension == item.dimension) &&
                  _inScope(item, _scope) &&
                  words.every((_searchable[item.id] ?? '').contains))
                item,
          ];
          var total = 0;
          for (final item in roleItems) {
            categoryCounts.update(
              item.category,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
            total++;
          }
          if (_sort != ResourceLibrarySort.project) {
            matches.sort((a, b) {
              final order = _names[a.id]!.compareTo(_names[b.id]!);
              return _sort == ResourceLibrarySort.alphabetical ? order : -order;
            });
          }
          final selected = matches
              .where((item) => item.id == _selection)
              .firstOrNull;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sidebar) ...[
                SizedBox(
                  width: bounds.maxWidth >= 1200 ? 264 : 224,
                  child: ResourceLibrarySidebar(
                    section: _section,
                    onSection: _setSection,
                    showWorkshops: widget.workshops != null,
                    category: _category,
                    categoryCounts: categoryCounts,
                    onCategory: (category) =>
                        setState(() => _setCategory(category)),
                    total: total,
                  ),
                ),
                const VerticalDivider(),
              ],
              Expanded(
                child: Column(
                  children: [
                    if (!sidebar)
                      ResourceLibraryTabs(
                        section: _section,
                        onSelected: _setSection,
                        showWorkshops: widget.workshops != null,
                      ),
                    Expanded(
                      child:
                          _section == ResourceLibrarySection.workshops &&
                              widget.workshops != null
                          ? widget.workshops!
                          : _library(
                              context,
                              matches,
                              sidebar: sidebar,
                              docked: docked,
                              selected: selected,
                            ),
                    ),
                  ],
                ),
              ),
              if (_section == ResourceLibrarySection.library &&
                  docked &&
                  _showDetails &&
                  selected != null) ...[
                const VerticalDivider(),
                SizedBox(
                  width: bounds.maxWidth >= 1200 ? 262 : 236,
                  child: _inspector(
                    selected,
                    () => setState(() => _showDetails = false),
                    _reveal,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );

  void _setSection(ResourceLibrarySection section) =>
      setState(() => _section = section);

  void _updateView(VoidCallback update) => setState(update);

  void _setCategory(ResourceLibraryCategory? value) {
    _category = value;
    _family = null;
  }
}
