import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/project_session/domain/project_session.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import '../../../features/resources/coordination/resource_pack_transfer_controller.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/project_library_organization.dart';
import '../../../features/resources/domain/project_model_workshop_port.dart';
import '../../../features/resources/domain/resource_pack_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import '../../../features/resources/domain/studio_search_text.dart';
import 'library/resource_library_view.dart';
import 'library/resource_library_view_data.dart';
import 'project_library_catalog_view.dart';
import 'project_library_delete_dialog.dart';
import 'project_library_edit_dialog.dart';
import 'project_library_organization_dialog.dart';
import 'project_library_pack_dialog.dart';
import 'project_library_preview.dart';
import 'project_model_workshop.dart';

part 'project_library_page_edits.dart';
part 'project_library_page_lifecycle.dart';
part 'project_library_page_loading.dart';
part 'project_library_page_navigation.dart';
part 'project_library_page_organization.dart';
part 'project_library_page_packs.dart';
part 'project_library_page_workshops.dart';

class ProjectLibraryPage extends StatefulWidget {
  const ProjectLibraryPage({
    super.key,
    required this.active,
    required this.maps,
    required this.visuals,
    this.management,
    this.onModelWorkshopPublished,
    this.onOpenMap,
    this.packPort,
    this.pickPack,
    this.onPackDialogChanged,
  }) : assert((packPort == null) == (pickPack == null));

  final bool active;
  final MapWorkspaceController maps;
  final MapWorkspaceVisuals? visuals;
  final ProjectLibraryManagement? management;
  final Future<bool> Function(String)? onOpenMap;
  final ResourcePackPort? packPort;
  final PickResourcePack? pickPack;
  final ValueChanged<bool>? onPackDialogChanged;
  final Future<void> Function(ResourceMutationReceipt)?
  onModelWorkshopPublished;

  @override
  State<ProjectLibraryPage> createState() => _ProjectLibraryPageState();
}

class _ProjectLibraryPageState extends State<ProjectLibraryPage> {
  Future<_ProjectLibraryRead>? _reading;
  ResourcePackTransferController? _packTransfer;
  MapWorkspaceController? _packWorkspace;
  bool _pickingFile = false;
  String? _workshopModel;
  bool _workshopBusy = false;
  final _workshopReceipts = <String, ResourceMutationReceipt>{};

  void _updateView(VoidCallback update) => setState(update);

  void _refresh() => setState(_read);

  void _setPickingFile(bool value) => setState(() => _pickingFile = value);

  void _removeEntry(_ProjectLibraryRead read, String id, String revision) {
    setState(() {
      read.revision = revision;
      read.catalog.remove(id);
      read.enriched?.remove(id);
    });
  }

  ResourceLibraryItemView _publish(
    _ProjectLibraryRead read,
    ProjectLibraryEdit edit, {
    required bool imported,
  }) {
    final item = read.publish(edit, imported: imported);
    setState(() {});
    return item;
  }

  @override
  void initState() {
    super.initState();
    _packTransfer = _createPackTransfer();
    if (widget.active) _read();
  }

  @override
  void didUpdateWidget(ProjectLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packPort != widget.packPort) {
      _packTransfer?.dispose();
      _packTransfer = _createPackTransfer();
    }
    if (oldWidget.maps != widget.maps) {
      _reading = null;
      _workshopModel = null;
      _workshopBusy = false;
      _workshopReceipts.clear();
    }
    if (widget.active && _reading == null) _read();
  }

  @override
  void dispose() {
    _packTransfer?.dispose();
    super.dispose();
  }

  void _read({
    ProjectResourceLibrary? library,
    String? revealIdentity,
    int publicationToken = 1,
  }) {
    final maps = widget.maps;
    final manifest = maps.project;
    if (manifest == null) return;
    final port = maps.port;
    final complete = maps.hasCompleteProject;
    final previews = ProjectResourcePreviews(
      (entry) => switch (port) {
        _ when complete => Future.value(maps.project ?? manifest),
        final ProjectResourcePreviewPort reader => reader.readResourcePreview(
          maps.session,
          entry.kind,
          entry.id,
        ),
        _ => Future.error(StateError('Lecteur d’aperçu indisponible.')),
      },
    );
    final result = library == null
        ? _queryLibrary(maps, manifest)
        : Future.value(library);
    late final Future<_ProjectLibraryRead> reading;
    bool isCurrent() => mounted && identical(_reading, reading);
    reading = result.then((library) {
      final revision = library.revision;
      final read = _ProjectLibraryRead(library, previews);
      final item = revealIdentity == null
          ? null
          : read.catalog.item(revealIdentity);
      if (item != null) {
        read.publication = (
          item: item,
          token: publicationToken,
          imported: true,
        );
      }
      if (revision != null && isCurrent()) {
        if (port case final ProjectResourceLibraryDimensionsPort reader) {
          read.withDimensions = _withDimensions(
            reader,
            maps.session,
            read,
            isCurrent,
          );
        }
        if (port case final ProjectResourceLibraryMapUsagesPort reader) {
          read.withUsages = _withUsages(
            reader,
            maps.session,
            library,
            revision,
            read,
          );
        }
      }
      return read;
    });
    _reading = reading;
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    if (reading == null) {
      return widget.active
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    return ExcludeFocus(
      excluding: !widget.active,
      child: FutureBuilder<_ProjectLibraryRead>(
        future: reading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StudioEmptyState(
                    title: 'Bibliothèque indisponible',
                    description:
                        'Le catalogue des ressources n’a pas pu être lu.',
                  ),
                  const SizedBox(height: StudioSpacing.l),
                  StudioButton(label: 'Réessayer', onPressed: _refresh),
                ],
              ),
            );
          }
          final result = snapshot.data;
          if (result == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<void>(
            future: result.withDimensions,
            builder: (context, dimensions) => FutureBuilder<void>(
              future: result.withUsages,
              builder: (context, usage) => _library(
                result,
                refreshing: snapshot.connectionState != ConnectionState.done,
                loadingMapUsages:
                    result.withUsages != null &&
                    usage.connectionState != ConnectionState.done,
                dimensionStatus: result.dimensionStatus(
                  dimensions.connectionState,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _library(
    _ProjectLibraryRead read, {
    required bool refreshing,
    required bool loadingMapUsages,
    required ResourceLibraryDimensionStatus dimensionStatus,
  }) {
    final catalog = read.enriched ?? read.catalog;
    final maps = widget.maps;
    final visuals = widget.active ? widget.visuals : null;
    final management = refreshing || _pickingFile ? null : widget.management;
    final editable = management != null && read.revision != null;
    final organization =
        editable && management.editor is ProjectLibraryOrganization
        ? management.editor as ProjectLibraryOrganization
        : null;
    Widget? preview(String identity, {required bool compact}) {
      final entry = catalog.entries[identity];
      if (entry == null || visuals == null) return null;
      return ProjectLibraryPreview(
        entry: entry,
        previews: read.previews,
        visuals: visuals,
        compact: compact,
      );
    }

    return ResourceLibraryView(
      key: ValueKey(maps.session.sessionId),
      items: catalog.items,
      familyLabels: catalog.familyLabels,
      maps: {
        for (final entry in maps.project?.maps ?? const [])
          entry.id: entry.name,
      },
      activeMapId: maps.active?.base.mapId,
      showRoles: true,
      showMapScopes: catalog.hasMapUsages,
      loadingMapUsages: loadingMapUsages,
      dimensionStatus: dimensionStatus,
      buildWorkshops: (back) =>
          _workshops(read, visuals, management?.editor, back),
      canLeaveWorkshops: () => !_workshopBusy,
      workshopAction: (item) => _modelWorkshopAction(read, item.id),
      onManageFamilies: organization == null
          ? null
          : () => _manageFamilies(context, read, organization),
      onClassifySelection: organization == null
          ? null
          : (context, identities) =>
                _classifySelection(context, read, organization, identities),
      onRefresh: refreshing || _pickingFile ? null : _refresh,
      onImport: editable
          ? (context) => _importFile(context, read, management)
          : null,
      onImportPack: editable && _packTransfer != null ? _importPack : null,
      onRename: editable
          ? (context, item) =>
                _rename(context, read, management.editor, item.id)
          : null,
      onClassify: editable
          ? (context, item) =>
                _classify(context, read, management.editor, item.id)
          : null,
      onModify: editable
          ? (context, item) =>
                _modify(context, read, management.editor, item.id)
          : null,
      onDuplicate: editable
          ? (context, item) =>
                _duplicate(context, read, management.editor, item.id)
          : null,
      onDelete: editable
          ? (context, item) =>
                _delete(context, read, management.editor, item.id)
          : null,
      publication: read.publication,
      navigation: _libraryNavigation(read),
      tilePreview: (item) => preview(item.id, compact: true),
      detailPreview: (item) => preview(item.id, compact: false),
    );
  }
}
