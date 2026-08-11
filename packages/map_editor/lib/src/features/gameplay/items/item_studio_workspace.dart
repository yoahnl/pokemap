import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../../editor/state/editor_selectors.dart';
import 'item_catalog_list.dart';
import 'item_definition_editor.dart';
import 'item_readiness_panel.dart';
import 'item_studio_gateway.dart';

final class ItemStudioWorkspace extends ConsumerStatefulWidget {
  const ItemStudioWorkspace({super.key, this.projectRootPath, this.gateway});

  final String? projectRootPath;
  final ItemStudioGateway? gateway;

  @override
  ConsumerState<ItemStudioWorkspace> createState() =>
      _ItemStudioWorkspaceState();
}

final class _ItemStudioWorkspaceState
    extends ConsumerState<ItemStudioWorkspace> {
  ItemStudioGateway? _canonicalGateway;
  Future<ItemStudioCatalogSnapshot>? _snapshotFuture;
  String? _loadedProjectRootPath;
  String? _selectedItemId;
  String? _lastReceiptId;
  String? _operationError;
  bool _creating = false;
  bool _isSaving = false;
  bool _isUndoing = false;
  bool _isSimulating = false;
  Map<String, Object?>? _simulation;

  ItemStudioGateway get _gateway {
    final injected = widget.gateway;
    if (injected != null) return injected;
    return _canonicalGateway ??= CanonicalItemStudioGateway(
      queries: ref.read(authoringQueryAdapterProvider),
      mutations: ref.read(authoringMutationAdapterProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath =
        widget.projectRootPath ?? ref.watch(editorProjectRootPathProvider);
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return const Center(
        child: SizedBox(
          width: 520,
          child: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Aucun projet ouvert',
            message: 'Ouvre un projet pour afficher le catalogue des items.',
          ),
        ),
      );
    }
    final future = _futureFor(projectRootPath);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _WorkspaceHeader(
          canUndo: _lastReceiptId != null && !_isSaving && !_isUndoing,
          isUndoing: _isUndoing,
          onCreate: _isSaving ? null : _create,
          onReload: _isSaving ? null : () => _reload(projectRootPath),
          onUndo: _lastReceiptId == null ? null : () => _undo(projectRootPath),
        ),
        const SizedBox(height: 10),
        if (_operationError case final error?) ...[
          PokeMapDiagnosticCallout(
            key: const Key('item-studio-operation-error'),
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Modification impossible',
            message: error,
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: FutureBuilder<ItemStudioCatalogSnapshot>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: SizedBox(
                    width: 620,
                    child: PokeMapDiagnosticCallout(
                      severity: PokeMapDiagnosticSeverity.error,
                      title: 'Catalogue illisible',
                      message: snapshot.error.toString(),
                      actionLabel: 'Réessayer',
                      onAction: () => _reload(projectRootPath),
                    ),
                  ),
                );
              }
              final catalog = snapshot.data!;
              return _buildStudio(projectRootPath, catalog);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudio(
    String projectRootPath,
    ItemStudioCatalogSnapshot catalog,
  ) {
    final selectedId = _resolvedSelection(catalog.definitions);
    final selected = catalog.definitions
        .where((definition) => definition.id == selectedId)
        .firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final list = ItemCatalogList(
          definitions: catalog.definitions,
          readinessByItemId: catalog.readinessByItemId,
          selectedItemId: selectedId,
          onSelected: (itemId) => setState(() {
            _selectedItemId = itemId;
            _creating = false;
            _simulation = null;
            _operationError = null;
          }),
        );
        final detail = _buildDetail(projectRootPath, catalog, selected);
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(width: 330, child: list),
              const SizedBox(width: 10),
              Expanded(child: detail),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 300, child: list),
            const SizedBox(height: 10),
            Expanded(child: detail),
          ],
        );
      },
    );
  }

  Widget _buildDetail(
    String projectRootPath,
    ItemStudioCatalogSnapshot catalog,
    ProjectItemDefinition? selected,
  ) {
    if (!_creating && selected == null) {
      return const PokeMapPanel(
        child: PokeMapEmptyState(
          title: 'Catalogue vide',
          description: 'Crée ton premier objet pour commencer.',
          icon: Icon(Icons.inventory_2_outlined),
        ),
      );
    }
    final originalItemId = _creating ? null : selected?.id;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ItemDefinitionEditor(
            key: ValueKey<String>(
              _creating
                  ? 'item-definition-new'
                  : 'item-definition-$originalItemId',
            ),
            initialDefinition: _creating ? null : selected,
            heldEffectOptions: catalog.heldEffectOptions,
            moveOptions: catalog.moveOptions,
            isSaving: _isSaving,
            onCancel: _creating
                ? () => setState(() {
                    _creating = false;
                    _operationError = null;
                  })
                : null,
            onSaved: (definition) {
              _save(projectRootPath, catalog, definition, originalItemId);
            },
          ),
          if (selected != null && !_creating) ...[
            const SizedBox(height: 10),
            ItemReadinessPanel(
              definition: selected,
              readiness: catalog.readinessByItemId[selected.id],
              usages:
                  catalog.usagesByItemId[selected.id] ??
                  const <ItemStudioUsage>[],
              simulation: _simulation,
              isSimulating: _isSimulating,
              onSimulate: (context) =>
                  _simulate(projectRootPath, selected.id, context),
            ),
          ],
        ],
      ),
    );
  }

  Future<ItemStudioCatalogSnapshot> _futureFor(String projectRootPath) {
    if (_loadedProjectRootPath != projectRootPath || _snapshotFuture == null) {
      _loadedProjectRootPath = projectRootPath;
      _snapshotFuture = _gateway.load(projectRootPath);
      _selectedItemId = null;
      _creating = false;
      _simulation = null;
      _operationError = null;
      _lastReceiptId = null;
    }
    return _snapshotFuture!;
  }

  void _create() {
    setState(() {
      _creating = true;
      _selectedItemId = null;
      _simulation = null;
      _operationError = null;
    });
  }

  Future<void> _save(
    String projectRootPath,
    ItemStudioCatalogSnapshot catalog,
    ProjectItemDefinition definition,
    String? originalItemId,
  ) async {
    setState(() {
      _isSaving = true;
      _operationError = null;
    });
    try {
      final receipt = await _gateway.save(
        projectRootPath,
        definition: definition,
        originalItemId: originalItemId,
        snapshotRevision: catalog.snapshotRevision,
      );
      if (!mounted) return;
      _lastReceiptId = receipt.receiptId;
      _selectedItemId = definition.id;
      _creating = false;
      _simulation = null;
      _snapshotFuture = _gateway.load(projectRootPath);
    } on Object catch (error) {
      if (!mounted) return;
      _operationError = error.toString();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _undo(String projectRootPath) async {
    final receiptId = _lastReceiptId;
    if (receiptId == null) return;
    setState(() {
      _isUndoing = true;
      _operationError = null;
    });
    try {
      await _gateway.undo(projectRootPath, receiptId: receiptId);
      if (!mounted) return;
      _lastReceiptId = null;
      _selectedItemId = null;
      _creating = false;
      _simulation = null;
      _snapshotFuture = _gateway.load(projectRootPath);
    } on Object catch (error) {
      if (!mounted) return;
      _operationError = error.toString();
    } finally {
      if (mounted) setState(() => _isUndoing = false);
    }
  }

  Future<void> _simulate(
    String projectRootPath,
    String itemId,
    ProjectItemUseContext context,
  ) async {
    setState(() {
      _isSimulating = true;
      _operationError = null;
    });
    try {
      final simulation = await _gateway.simulate(
        projectRootPath,
        itemId: itemId,
        context: context,
      );
      if (mounted) setState(() => _simulation = simulation);
    } on Object catch (error) {
      if (mounted) setState(() => _operationError = error.toString());
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  void _reload(String projectRootPath) {
    setState(() {
      _snapshotFuture = _gateway.load(projectRootPath);
      _simulation = null;
      _operationError = null;
    });
  }

  String? _resolvedSelection(List<ProjectItemDefinition> definitions) {
    if (_creating) return null;
    final selectedItemId = _selectedItemId;
    if (selectedItemId != null &&
        definitions.any((definition) => definition.id == selectedItemId)) {
      return selectedItemId;
    }
    return definitions.firstOrNull?.id;
  }
}

final class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.canUndo,
    required this.isUndoing,
    required this.onCreate,
    required this.onReload,
    required this.onUndo,
  });

  final bool canUndo;
  final bool isUndoing;
  final VoidCallback? onCreate;
  final VoidCallback? onReload;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Item Studio',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Catalogue canonique, usages, validation et simulation.',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          PokeMapButton(
            key: const Key('item-studio-reload-button'),
            onPressed: onReload,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            leading: const Icon(Icons.refresh_rounded),
            child: const Text('Recharger'),
          ),
          const SizedBox(width: 6),
          PokeMapButton(
            key: const Key('item-studio-undo-button'),
            onPressed: canUndo ? onUndo : null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            isLoading: isUndoing,
            leading: const Icon(Icons.undo_rounded),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 6),
          PokeMapButton(
            key: const Key('item-studio-create-button'),
            onPressed: onCreate,
            size: PokeMapButtonSize.small,
            leading: const Icon(Icons.add_rounded),
            child: const Text('Nouvel objet'),
          ),
        ],
      ),
    );
  }
}
