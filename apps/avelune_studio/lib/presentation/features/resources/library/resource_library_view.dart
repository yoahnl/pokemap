import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart' show ResourceLibraryRole;

import '../../../../features/resources/domain/studio_search_text.dart';
import 'resource_library_controls.dart';
import 'resource_library_inspector.dart';
import 'resource_library_items.dart';
import 'resource_library_scope_panel.dart';
import 'resource_library_toolbar.dart';
import 'resource_library_view_data.dart';

part 'resource_library_results.dart';
part 'resource_library_inspection.dart';
part 'resource_library_organization.dart';

typedef ResourceLibraryEditAction = Future<ResourceLibraryItemView?> Function(
  BuildContext context,
  ResourceLibraryItemView item,
);

typedef ResourceLibraryPublication = ({
  ResourceLibraryItemView item,
  int token,
  bool imported,
});

class ResourceLibraryView extends StatefulWidget {
  const ResourceLibraryView({
    super.key,
    required this.items,
    required this.maps,
    this.activeMapId,
    this.workshops,
    this.buildWorkshops,
    this.canLeaveWorkshops,
    this.fullWidthWorkshop = false,
    this.workshopAction,
    this.onManageFamilies,
    this.onClassifySelection,
    this.onImport,
    this.onImportPack,
    this.onRefresh,
    this.onRename,
    this.onClassify,
    this.onModify,
    this.onDuplicate,
    this.onDelete,
    this.publication,
    this.navigation,
    this.detailPreview,
    this.tilePreview,
    this.familyLabels = const {},
    this.showRoles = false,
    this.showMapScopes = true,
    this.loadingMapUsages = false,
    this.dimensionStatus = ResourceLibraryDimensionStatus.ready,
    this.previewActions = false,
  });

  final List<ResourceLibraryItemView> items;
  final Map<String, String> maps;
  final String? activeMapId;
  final Widget? workshops;
  final ResourceLibraryWorkshopsBuilder? buildWorkshops;
  final bool Function()? canLeaveWorkshops;
  final bool fullWidthWorkshop;
  final ResourceLibraryWorkshopAction? Function(ResourceLibraryItemView)?
  workshopAction;
  final VoidCallback? onManageFamilies;
  final Future<void> Function(BuildContext, Set<String>)? onClassifySelection;
  final ValueChanged<BuildContext>? onImport;
  final ValueChanged<BuildContext>? onImportPack;
  final VoidCallback? onRefresh;
  final ResourceLibraryEditAction? onRename;
  final ResourceLibraryEditAction? onClassify;
  final ResourceLibraryEditAction? onModify;
  final ResourceLibraryEditAction? onDuplicate;
  final Future<bool> Function(BuildContext, ResourceLibraryItemView)? onDelete;
  final ResourceLibraryPublication? publication;
  final ResourceLibraryNavigation? navigation;
  final Widget? Function(ResourceLibraryItemView)? detailPreview;
  final Widget? Function(ResourceLibraryItemView)? tilePreview;
  final Map<String, String> familyLabels;
  final bool showRoles;
  final bool showMapScopes;
  final bool loadingMapUsages;
  final ResourceLibraryDimensionStatus dimensionStatus;
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
  var _marking = false;
  final _marked = <String>{};
  late Map<String, String> _searchable;
  late Map<String, String> _names;

  String? get _map =>
      _referenceMap ?? widget.activeMapId ?? widget.maps.keys.firstOrNull;
  bool get _hasWorkshops =>
      widget.workshops != null || widget.buildWorkshops != null;
  bool get _canLeaveWorkshops => widget.canLeaveWorkshops?.call() ?? true;
  ResourceLibraryDimension? get _activeDimension =>
      widget.dimensionStatus == ResourceLibraryDimensionStatus.ready
      ? _dimension
      : null;
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
    if (!widget.showMapScopes) _scope = ResourceLibraryScope.project;
    if (!widget.maps.containsKey(_referenceMap)) _referenceMap = null;
    if (_family != null && !widget.familyLabels.containsKey(_family)) {
      _family = null;
    }
    final publication = widget.publication;
    if (publication != null &&
        publication.token != oldWidget.publication?.token) {
      final item = publication.item;
      final name = studioSearchText(item.name);
      _names[item.id] = name;
      _searchable[item.id] = item.searchText ?? name;
      final revealInResults =
          publication.imported ||
          (widget.showRoles && _role != item.role) ||
          !_matchesFilters(item, _searchWords);
      if (revealInResults) _search.text = item.name;
      _reveal(item);
      if (revealInResults) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
        });
      }
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

  void _reveal(ResourceLibraryItemView item) {
    _selection = item.id;
    _showDetails = true;
    _role = item.role;
    if (_category != null && _category != item.category) _setCategory(null);
    if (_family != null && !item.familyIds.contains(_family)) _family = null;
    if (_dimension case final dimension?
        when !item.matchesDimension(dimension)) {
      _dimension = null;
    }
    if (!_inScope(item, _scope)) _scope = ResourceLibraryScope.project;
    if (!_searchWords.every((_searchable[item.id] ?? '').contains)) {
      _search.clear();
    }
  }

  Iterable<String> get _searchWords =>
      studioSearchText(_search.text).trim().split(RegExp(r'\s+'));

  bool _matchesFilters(ResourceLibraryItemView item, Iterable<String> words) =>
      (_category == null || _category == item.category) &&
      (_family == null || item.familyIds.contains(_family)) &&
      (_activeDimension == null || item.matchesDimension(_activeDimension!)) &&
      _inScope(item, _scope) &&
      words.every((_searchable[item.id] ?? '').contains);

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
          final focusedWorkshop =
              _section == ResourceLibrarySection.workshops &&
              widget.fullWidthWorkshop;
          final sidebar = bounds.maxWidth >= 740 && !focusedWorkshop;
          final docked = bounds.maxWidth >= 910;
          final words = _searchWords;
          final roleItems = _section == ResourceLibrarySection.library
              ? _roleItems
              : const <ResourceLibraryItemView>[];
          final categoryCounts = <ResourceLibraryCategory, int>{};
          final matches = [
            for (final item in roleItems)
              if (_matchesFilters(item, words)) item,
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
                    showWorkshops: _hasWorkshops,
                    allowLibraryNavigation: _canLeaveWorkshops,
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
                    if (!sidebar && !focusedWorkshop)
                      ResourceLibraryTabs(
                        section: _section,
                        onSelected: _setSection,
                        showWorkshops: _hasWorkshops,
                        allowLibraryNavigation: _canLeaveWorkshops,
                      ),
                    Expanded(
                      child:
                          _section == ResourceLibrarySection.workshops &&
                              _hasWorkshops
                          ? _workshopSection()
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
                  !_marking &&
                  _showDetails &&
                  selected != null) ...[
                const VerticalDivider(),
                SizedBox(
                  width: bounds.maxWidth >= 1200 ? 262 : 236,
                  child: _inspection(
                    selected,
                    () => setState(() => _showDetails = false),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );

  void _setSection(ResourceLibrarySection section) {
    if (section == _section ||
        (section == ResourceLibrarySection.library && !_canLeaveWorkshops)) {
      return;
    }
    setState(() => _section = section);
  }

  void _updateView(VoidCallback update) => setState(update);

  void _setCategory(ResourceLibraryCategory? value) {
    _category = value;
    _family = null;
  }
}
