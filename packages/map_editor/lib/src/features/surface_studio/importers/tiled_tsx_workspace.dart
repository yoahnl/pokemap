import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        DropdownButton,
        DropdownMenuItem,
        ElevatedButton,
        Material,
        MaterialType;
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../editor/application/editor_ai_settings.dart';
import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../surface_studio_vertical_atlas_role_mapping.dart';
import '../surface_studio_vertical_atlas_preset_generator.dart';
import 'tiled_tsx_animated_tileset_parser.dart';
import 'tiled_tsx_animation_browser.dart';
import 'tiled_tsx_animation_browser_models.dart';
import 'tiled_tsx_catalog_append.dart';
import 'tiled_tsx_mistral_grouping_models.dart';
import 'tiled_tsx_mistral_grouping_suggester.dart';
import 'tiled_tsx_role_mapping_builder.dart';
import 'tiled_tsx_surface_animation_importer.dart';
import 'tiled_tsx_surface_preset_draft.dart';
import 'tiled_tsx_transparent_color.dart';

final class TiledTsxLoadedFile {
  const TiledTsxLoadedFile({
    required this.path,
    required this.fileName,
    required this.xml,
  });

  final String path;
  final String fileName;
  final String xml;
}

const MethodChannel _macOsTiledTsxFileAccessChannel =
    MethodChannel('map_editor/file_access');

abstract interface class TiledTsxFileLoader {
  Future<TiledTsxLoadedFile?> pickAndLoadTsx();
}

final class TiledTsxPlatformFileLoader implements TiledTsxFileLoader {
  const TiledTsxPlatformFileLoader();

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['tsx'],
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) {
      return null;
    }
    await _beginTiledTsxImportBundleAccessIfNeeded(path);
    final xml = await File(path).readAsString();
    return TiledTsxLoadedFile(
      path: path,
      fileName: p.basename(path),
      xml: xml,
    );
  }
}

Future<void> _beginTiledTsxImportBundleAccessIfNeeded(
    String selectedPath) async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsTiledTsxFileAccessChannel.invokeMethod<void>(
      'beginImportBundleAccess',
      <String, String>{'selectedPath': selectedPath},
    );
  } catch (_) {
    // Best effort only: non-macOS tests and unsandboxed builds do not need it.
  }
}

class TiledTsxWorkspace extends StatefulWidget {
  const TiledTsxWorkspace({
    super.key,
    required this.catalog,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.onSurfaceCatalogChanged,
    this.fileLoader = const TiledTsxPlatformFileLoader(),
    this.atlasImageBytes,
    this.projectSettings,
    this.groupingSuggester,
  });

  final ProjectSurfaceCatalog catalog;
  final List<ProjectTilesetEntry> projectTilesets;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final TiledTsxFileLoader fileLoader;
  final Uint8List? atlasImageBytes;
  final ProjectSettings? projectSettings;
  final TiledTsxAnimationGroupingSuggester? groupingSuggester;

  @override
  State<TiledTsxWorkspace> createState() => _TiledTsxWorkspaceState();
}

class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
  TiledTsxLoadedFile? _loadedFile;
  TiledTsxTilesetAudit? _audit;
  ProjectTilesetEntry? _selectedTileset;
  ProjectSurfaceCatalog? _localCatalog;
  bool _loading = false;
  String? _statusMessage;
  List<String> _errors = const <String>[];
  Uint8List? _transparentPreviewSourceBytes;
  Uint8List? _transparentPreviewBytes;
  String? _transparentPreviewColor;
  String? _activeGroupId;
  Map<SurfaceVariantRole, String> _roleAnimationIds =
      const <SurfaceVariantRole, String>{};
  Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> _roleSources =
      const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{};
  List<String> _surfaceSaveErrors = const <String>[];
  List<String> _surfaceSaveWarnings = const <String>[];
  String? _surfaceSaveNote;
  String? _detectionMessage;
  bool _showAllAnimations = false;
  bool _mistralConfirmOpen = false;
  bool _mistralPending = false;
  TiledTsxMistralGroupingResult? _mistralResult;
  Map<SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>
      _acceptedSuggestions =
      const <SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>{};

  @override
  void didUpdateWidget(covariant TiledTsxWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog) {
      _localCatalog = null;
    }
    if (widget.projectTilesets != oldWidget.projectTilesets) {
      _selectedTileset = _pickMatchingTileset(_audit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final effectiveCatalog = _localCatalog ?? widget.catalog;
    final atlas = _atlasForBrowser(effectiveCatalog);
    final animations = effectiveCatalog.animations;
    final previewAtlasImageBytes = _previewAtlasImageBytes();
    final hasMistralKey = hasEditorMistralApiKey(widget.projectSettings);
    return SingleChildScrollView(
      key: const ValueKey('surface_studio.tsx_workspace'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TsxWorkspaceHeader(label: label, subtle: subtle),
          const SizedBox(height: 12),
          _TsxReferenceActionBar(
            loading: _loading,
            mistralPending: _mistralPending,
            hasAnimations: animations.isNotEmpty,
            hasMistralKey: hasMistralKey,
            hasAcceptedSuggestions: _acceptedSuggestions.isNotEmpty,
            onImport: _pickTsx,
            onDetect: _runLocalDetection,
            onApplySuggestions: _applyPreparedSuggestions,
            onRunMistral: _openMistralConfirmation,
          ),
          const SizedBox(height: 12),
          _ImportSection(
            loadedFile: _loadedFile,
            audit: _audit,
            projectTilesets: widget.projectTilesets,
            selectedTileset: _selectedTileset,
            loading: _loading,
            statusMessage: _statusMessage,
            errors: _errors,
            atlasImageBytesAvailable: widget.atlasImageBytes != null,
            onPickTsx: _pickTsx,
            onTilesetChanged: (tileset) {
              setState(() => _selectedTileset = tileset);
            },
            onConfirmImport: _canConfirmImport ? _confirmImport : null,
          ),
          const SizedBox(height: 14),
          if (animations.isEmpty)
            _TsxEmptyState(onImportPressed: _pickTsx)
          else ...[
            if (_mistralConfirmOpen ||
                _mistralPending ||
                _mistralResult != null) ...[
              _ReferenceMistralGroupingPanel(
                result: _mistralResult,
                pending: _mistralPending,
                confirming: _mistralConfirmOpen,
                acceptedSuggestions: _acceptedSuggestions,
                atlas: atlas,
                animations: animations,
                atlasImageBytes: previewAtlasImageBytes,
                onConfirm: _runMistralGrouping,
                onCancel: _cancelMistralGrouping,
                onAccept: _acceptMistralSuggestion,
                onReject: _rejectMistralSuggestion,
              ),
              const SizedBox(height: 14),
            ],
            _ReferenceTsxSurfaceBuilder(
              atlas: atlas,
              animations: animations,
              atlasImageBytes: previewAtlasImageBytes,
              catalog: effectiveCatalog,
              activeGroupId: _activeGroupId,
              roleAnimationIds: _roleAnimationIds,
              roleSources: _roleSources,
              detectionMessage: _detectionMessage,
              saveErrors: _surfaceSaveErrors,
              saveWarnings: _surfaceSaveWarnings,
              saveNote: _surfaceSaveNote,
              onGroupSelected: (id) {
                setState(() {
                  _activeGroupId = id;
                  _detectionMessage = null;
                });
              },
              onRoleAssignmentsChanged: _replaceRoleAssignments,
              onSaveSurface: widget.onSurfaceCatalogChanged == null
                  ? null
                  : _saveReferenceSurface,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                key: const ValueKey('tiled_tsx_reference.show_all_animations'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: EditorChrome.islandFillElevated(context),
                borderRadius: BorderRadius.circular(10),
                onPressed: () {
                  setState(() => _showAllAnimations = true);
                },
                child: const Text(
                  'Voir toutes les animations',
                  style: TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (_showAllAnimations) ...[
              const SizedBox(height: 10),
              _SecondaryAnimationBrowserPanel(
                child: TiledTsxAnimationBrowser(
                  atlas: atlas,
                  animations: animations,
                  atlasImageBytes: previewAtlasImageBytes,
                  sourceLabel: _loadedFile?.fileName ?? 'Catalogue de travail',
                  catalog: effectiveCatalog,
                  onSurfaceCatalogChanged: widget.onSurfaceCatalogChanged,
                  projectSettings: widget.projectSettings,
                  groupingSuggester: widget.groupingSuggester,
                ),
                onClose: () {
                  setState(() => _showAllAnimations = false);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Uint8List? _previewAtlasImageBytes() {
    final source = widget.atlasImageBytes;
    if (source == null) {
      _transparentPreviewSourceBytes = null;
      _transparentPreviewBytes = null;
      _transparentPreviewColor = null;
      return null;
    }
    final transparentColor = _audit?.summary.transparentColor;
    if (parseTiledTsxTransparentColor(transparentColor) == null) {
      return source;
    }
    if (identical(source, _transparentPreviewSourceBytes) &&
        transparentColor == _transparentPreviewColor &&
        _transparentPreviewBytes != null) {
      return _transparentPreviewBytes;
    }
    final transformed = applyTiledTsxTransparentColorToPngBytes(
      imageBytes: source,
      transparentColor: transparentColor,
    );
    _transparentPreviewSourceBytes = source;
    _transparentPreviewColor = transparentColor;
    _transparentPreviewBytes = transformed;
    return transformed;
  }

  bool get _canConfirmImport =>
      !_loading &&
      _audit != null &&
      _audit!.hasErrors == false &&
      _audit!.summary.animationCount > 0 &&
      _selectedTileset != null;

  Future<void> _pickTsx() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
      _errors = const <String>[];
    });
    try {
      final loaded = await widget.fileLoader.pickAndLoadTsx();
      if (!mounted) {
        return;
      }
      if (loaded == null) {
        setState(() {
          _loading = false;
          _statusMessage = 'Import TSX annulé.';
        });
        return;
      }
      final audit = parseTiledTsxAnimatedTileset(loaded.xml);
      final errors = <String>[
        if (audit.hasErrors) 'Le fichier XML TSX est invalide ou incomplet.',
        if (!audit.hasErrors && audit.summary.animationCount == 0)
          'Le TSX ne contient aucune animation.',
        ...audit.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity == TiledTsxDiagnosticSeverity.error,
            )
            .map((diagnostic) => diagnostic.message),
      ];
      setState(() {
        _loadedFile = loaded;
        _audit = audit;
        _selectedTileset = _pickMatchingTileset(audit);
        _loading = false;
        _statusMessage = null;
        _errors = List<String>.unmodifiable(errors);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errors = ['Le fichier XML TSX est invalide ou incomplet.', '$error'];
      });
    }
  }

  void _confirmImport() {
    final audit = _audit;
    final tileset = _selectedTileset;
    if (audit == null || tileset == null) {
      return;
    }
    final prefix = _slugify(audit.summary.name);
    final imported = importTiledTsxSurfaceAnimations(
      audit: audit,
      options: TiledTsxSurfaceAnimationImportOptions(
        atlasId: prefix,
        tilesetId: tileset.id,
        animationIdPrefix: prefix,
        sortOrderBase: widget.catalog.animationCount,
      ),
    );
    if (imported.hasErrors || imported.atlas == null) {
      setState(() {
        _errors = imported.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity ==
                  TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
            )
            .map((diagnostic) => diagnostic.message)
            .toList(growable: false);
        _statusMessage = null;
      });
      return;
    }
    final appended = appendTiledTsxSurfaceImportToCatalog(
      catalog: _localCatalog ?? widget.catalog,
      atlas: imported.atlas!,
      animations: imported.animations,
    );
    if (appended.hasErrors || appended.catalog == null) {
      setState(() {
        _errors = appended.errors;
        _statusMessage = null;
      });
      return;
    }
    widget.onSurfaceCatalogChanged?.call(appended.catalog!);
    setState(() {
      _localCatalog = appended.catalog;
      _errors = const <String>[];
      _roleAnimationIds = const <SurfaceVariantRole, String>{};
      _roleSources = const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{};
      _surfaceSaveErrors = const <String>[];
      _surfaceSaveWarnings = const <String>[];
      _surfaceSaveNote = null;
      _detectionMessage = null;
      _activeGroupId = null;
      _showAllAnimations = false;
      _mistralConfirmOpen = false;
      _mistralPending = false;
      _mistralResult = null;
      _acceptedSuggestions =
          const <SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>{};
      _statusMessage =
          'Import TSX prêt : ${imported.animations.length} animations ajoutées.';
    });
  }

  void _runLocalDetection() {
    final groups = buildTiledTsxDetectedAnimationGroups(
      animations: (_localCatalog ?? widget.catalog).animations,
    );
    setState(() {
      _activeGroupId = groups.isEmpty ? null : groups.first.id;
      _detectionMessage = groups.isEmpty
          ? 'Aucune animation disponible pour la détection locale.'
          : 'Détection locale basique appliquée.';
    });
  }

  void _applyPreparedSuggestions() {
    if (_acceptedSuggestions.isEmpty) {
      setState(() {
        _surfaceSaveNote =
            'Aucune suggestion acceptée en attente : validez les suggestions Mistral avant application.';
      });
      return;
    }
    final next = Map<SurfaceVariantRole, String>.of(_roleAnimationIds);
    final nextSources = Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.of(
      _roleSources,
    );
    for (final entry in _acceptedSuggestions.entries) {
      next[entry.key] = entry.value.animationId;
      nextSources[entry.key] = TiledTsxRoleAssignmentMeta(
        source: TiledTsxRoleAssignmentSource.mistral,
        confidence: entry.value.confidence,
      );
    }
    final count = _acceptedSuggestions.length;
    setState(() {
      _roleAnimationIds = Map<SurfaceVariantRole, String>.unmodifiable(next);
      _roleSources =
          Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.unmodifiable(
        nextSources,
      );
      _acceptedSuggestions =
          const <SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>{};
      _surfaceSaveErrors = const <String>[];
      _surfaceSaveWarnings = const <String>[];
      _surfaceSaveNote = count == 1
          ? '1 suggestion appliquée au draft.'
          : '$count suggestions appliquées au draft.';
    });
  }

  void _openMistralConfirmation() {
    final catalog = _localCatalog ?? widget.catalog;
    if (catalog.animations.isEmpty ||
        !hasEditorMistralApiKey(widget.projectSettings)) {
      return;
    }
    setState(() {
      _mistralConfirmOpen = true;
      _mistralResult = null;
      _surfaceSaveNote = null;
    });
  }

  void _cancelMistralGrouping() {
    setState(() {
      _mistralConfirmOpen = false;
      if (!_mistralPending) {
        _mistralResult = null;
      }
    });
  }

  Future<void> _runMistralGrouping() async {
    final catalog = _localCatalog ?? widget.catalog;
    final atlas = _atlasForBrowser(catalog);
    if (atlas == null) {
      setState(() {
        _mistralConfirmOpen = false;
        _mistralResult = const TiledTsxMistralGroupingResult(
          suggestions: <TiledTsxRoleAnimationSuggestion>[],
          rejectedAnimationIds: <String>[],
          warnings: <String>['Atlas Surface indisponible pour Mistral.'],
        );
      });
      return;
    }
    final animations = _animationsForActiveGroup(catalog.animations);
    if (animations.isEmpty) {
      setState(() {
        _mistralConfirmOpen = false;
        _mistralResult = const TiledTsxMistralGroupingResult(
          suggestions: <TiledTsxRoleAnimationSuggestion>[],
          rejectedAnimationIds: <String>[],
          warnings: <String>['Aucune animation sélectionnée pour Mistral.'],
        );
      });
      return;
    }
    setState(() {
      _mistralConfirmOpen = false;
      _mistralPending = true;
      _mistralResult = null;
    });
    final suggester =
        widget.groupingSuggester ?? TiledTsxMistralAnimationGroupingSuggester();
    final result = await suggester.suggest(
      apiKey: resolveEditorMistralApiKey(widget.projectSettings),
      request: TiledTsxMistralGroupingRequest(
        animations: animations,
        tileWidth: atlas.geometry.tileSize.width,
        tileHeight: atlas.geometry.tileSize.height,
        atlasColumns: atlas.geometry.gridSize.columns,
        atlasRows: atlas.geometry.gridSize.rows,
        availableRoles: standardSurfaceVariantRoleOrder,
      ),
      atlasImageBytes: _previewAtlasImageBytes(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _mistralPending = false;
      _mistralResult = result;
      _acceptedSuggestions =
          const <SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>{};
    });
  }

  List<ProjectSurfaceAnimation> _animationsForActiveGroup(
    List<ProjectSurfaceAnimation> animations,
  ) {
    final groups = buildTiledTsxDetectedAnimationGroups(animations: animations);
    TiledTsxDetectedAnimationGroup? activeGroup;
    if (_activeGroupId != null) {
      for (final group in groups) {
        if (group.id == _activeGroupId) {
          activeGroup = group;
          break;
        }
      }
    }
    final ids = activeGroup?.animationIds.toSet();
    if (ids == null) {
      return animations;
    }
    return animations.where((animation) => ids.contains(animation.id)).toList(
          growable: false,
        );
  }

  void _acceptMistralSuggestion(TiledTsxRoleAnimationSuggestion suggestion) {
    final next = Map<SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>.of(
      _acceptedSuggestions,
    );
    next[suggestion.role] = suggestion;
    setState(() {
      _acceptedSuggestions =
          Map<SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>.unmodifiable(
        next,
      );
      _surfaceSaveNote =
          'Suggestion acceptée : ${_referenceRoleLabel(suggestion.role)}.';
    });
  }

  void _rejectMistralSuggestion(TiledTsxRoleAnimationSuggestion suggestion) {
    final next = Map<SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>.of(
      _acceptedSuggestions,
    )..remove(suggestion.role);
    setState(() {
      _acceptedSuggestions =
          Map<SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>.unmodifiable(
        next,
      );
      _surfaceSaveNote =
          'Suggestion rejetée : ${_referenceRoleLabel(suggestion.role)}.';
    });
  }

  void _replaceRoleAssignments(Map<SurfaceVariantRole, String> next) {
    final previous = _roleAnimationIds;
    final nextSources = Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.of(
      _roleSources,
    );
    for (final role in standardSurfaceVariantRoleOrder) {
      final value = next[role];
      if (value == null || value.trim().isEmpty) {
        nextSources.remove(role);
      } else if (previous[role] != value) {
        nextSources[role] = const TiledTsxRoleAssignmentMeta(
          source: TiledTsxRoleAssignmentSource.manual,
        );
      }
    }
    setState(() {
      _roleAnimationIds = Map<SurfaceVariantRole, String>.unmodifiable(next);
      _roleSources =
          Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.unmodifiable(
        nextSources,
      );
      _surfaceSaveErrors = const <String>[];
      _surfaceSaveWarnings = const <String>[];
      _surfaceSaveNote = null;
    });
  }

  void _saveReferenceSurface() {
    final catalog = _localCatalog ?? widget.catalog;
    final draft = TiledTsxSurfacePresetDraft(
      id: _nextSurfacePresetId(catalog),
      name: 'Surface TSX',
      categoryId: null,
      sortOrder: catalog.presetCount,
      roleAnimationIds: _roleAnimationIds,
    );
    final validation = validateTiledTsxSurfacePresetDraft(
      draft: draft,
      catalog: catalog,
    );
    if (!validation.canCreate) {
      setState(() {
        _surfaceSaveErrors = validation.errors;
        _surfaceSaveWarnings = validation.warnings;
        _surfaceSaveNote = null;
      });
      return;
    }
    final preset = buildTiledTsxSurfacePresetFromDraft(
      draft: draft,
      catalog: catalog,
    );
    final next = surfaceStudioAppendPresetToWorkCatalog(
      catalog: catalog,
      preset: preset,
    );
    widget.onSurfaceCatalogChanged?.call(next);
    setState(() {
      _localCatalog = next;
      _surfaceSaveErrors = const <String>[];
      _surfaceSaveWarnings = validation.warnings;
      _surfaceSaveNote = 'Surface ${preset.id} ajoutée au catalogue.';
    });
  }

  ProjectTilesetEntry? _pickMatchingTileset(TiledTsxTilesetAudit? audit) {
    if (widget.projectTilesets.isEmpty) {
      return null;
    }
    final imageSource = audit?.summary.imageSource;
    if (imageSource != null && imageSource.isNotEmpty) {
      final expectedBasename = p.basename(imageSource).toLowerCase();
      for (final tileset in widget.projectTilesets) {
        if (p.basename(tileset.relativePath).toLowerCase() ==
            expectedBasename) {
          return tileset;
        }
      }
    }
    return widget.projectTilesets.first;
  }
}

class _ImportSection extends StatelessWidget {
  const _ImportSection({
    required this.loadedFile,
    required this.audit,
    required this.projectTilesets,
    required this.selectedTileset,
    required this.loading,
    required this.statusMessage,
    required this.errors,
    required this.atlasImageBytesAvailable,
    required this.onPickTsx,
    required this.onTilesetChanged,
    required this.onConfirmImport,
  });

  final TiledTsxLoadedFile? loadedFile;
  final TiledTsxTilesetAudit? audit;
  final List<ProjectTilesetEntry> projectTilesets;
  final ProjectTilesetEntry? selectedTileset;
  final bool loading;
  final String? statusMessage;
  final List<String> errors;
  final bool atlasImageBytesAvailable;
  final VoidCallback onPickTsx;
  final ValueChanged<ProjectTilesetEntry?> onTilesetChanged;
  final VoidCallback? onConfirmImport;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final border = EditorChrome.editorIslandRim(context);
    return Container(
      key: const ValueKey('tiled_tsx_workspace.import_section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importer un fichier TSX',
                      style: TextStyle(
                        color: label,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Les frames et durées viennent du fichier Tiled. Aucun preset Surface n’est créé à l’import.',
                      style: TextStyle(color: subtle, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                key: const ValueKey('tiled_tsx_workspace.import'),
                onPressed: loading ? null : onPickTsx,
                child:
                    Text(loading ? 'Chargement…' : 'Importer un fichier TSX'),
              ),
            ],
          ),
          if (audit != null) ...[
            const SizedBox(height: 12),
            _TsxSummary(
              audit: audit!,
              loadedFile: loadedFile,
              atlasImageBytesAvailable: atlasImageBytesAvailable,
            ),
            const SizedBox(height: 12),
            _TilesetPicker(
              tilesets: projectTilesets,
              selectedTileset: selectedTileset,
              onChanged: onTilesetChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                key: const ValueKey('tiled_tsx_workspace.confirm_import'),
                onPressed: onConfirmImport,
                child: const Text('Confirmer l’import TSX'),
              ),
            ),
          ],
          if (projectTilesets.isEmpty && audit != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Ajoutez d’abord l’image comme tileset du projet, puis relancez l’import TSX.',
              style: TextStyle(
                color: CupertinoColors.systemOrange,
                fontSize: 12,
              ),
            ),
          ],
          if (statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              statusMessage!,
              style: const TextStyle(
                color: CupertinoColors.systemGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Erreur import TSX',
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final error in errors)
              Text(
                error,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 12,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TsxSummary extends StatelessWidget {
  const _TsxSummary({
    required this.audit,
    required this.loadedFile,
    required this.atlasImageBytesAvailable,
  });

  final TiledTsxTilesetAudit audit;
  final TiledTsxLoadedFile? loadedFile;
  final bool atlasImageBytesAvailable;

  @override
  Widget build(BuildContext context) {
    final s = audit.summary;
    final transparentColor = s.transparentColor;
    final hasTransparentColor =
        transparentColor != null && transparentColor.trim().isNotEmpty;
    final validTransparentColor =
        parseTiledTsxTransparentColor(transparentColor) != null;
    final transparentColorLabel = !hasTransparentColor
        ? 'aucune'
        : validTransparentColor
            ? formatTiledTsxTransparentColor(transparentColor)
            : transparentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBlock(
          title: 'Résumé TSX',
          rows: [
            ('Fichier', loadedFile?.fileName ?? 'TSX'),
            ('name', s.name),
            ('tileWidth', '${s.tileWidth}'),
            ('tileHeight', '${s.tileHeight}'),
            ('columns', '${s.columns}'),
            ('tileCount', '${s.tileCount}'),
            ('imageSource', s.imageSource),
            ('imageWidth', '${s.imageWidth}'),
            ('imageHeight', '${s.imageHeight}'),
            ('animations', '${s.animationCount} animations'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Couleur transparente : $transparentColorLabel',
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasTransparentColor && validTransparentColor) ...[
          const SizedBox(height: 4),
          Text(
            atlasImageBytesAvailable
                ? 'Transparence appliquée aux previews.'
                : 'Transparence prête dès que l’image atlas est disponible.',
            style: const TextStyle(
              color: CupertinoColors.systemGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (hasTransparentColor) ...[
          const SizedBox(height: 4),
          Text(
            'Couleur transparente TSX invalide : $transparentColor. Les previews utilisent l’image brute.',
            style: const TextStyle(
              color: CupertinoColors.systemOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TilesetPicker extends StatelessWidget {
  const _TilesetPicker({
    required this.tilesets,
    required this.selectedTileset,
    required this.onChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectTilesetEntry? selectedTileset;
  final ValueChanged<ProjectTilesetEntry?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    if (tilesets.isEmpty) {
      return Text(
        'Aucun tileset image PokeMap disponible.',
        style: TextStyle(color: subtle, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir le tileset image correspondant',
          style: TextStyle(
            color: label,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          type: MaterialType.transparency,
          child: DropdownButton<ProjectTilesetEntry>(
            key: const ValueKey('tiled_tsx_workspace.tileset_picker'),
            value: selectedTileset,
            isExpanded: true,
            items: [
              for (final tileset in tilesets)
                DropdownMenuItem<ProjectTilesetEntry>(
                  value: tileset,
                  child: Text(
                    '${tileset.name} · ${tileset.id} · ${tileset.relativePath}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TsxEmptyState extends StatelessWidget {
  const _TsxEmptyState({
    required this.onImportPressed,
  });

  final VoidCallback onImportPressed;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucune animation TSX importée.',
            style: TextStyle(
              color: label,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Importez un fichier .tsx pour générer des animations Surface depuis un tileset Tiled.',
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const ValueKey('tiled_tsx_workspace.empty_import'),
            onPressed: onImportPressed,
            child: const Text('Importer un fichier TSX'),
          ),
        ],
      ),
    );
  }
}

class _TsxWorkspaceHeader extends StatelessWidget {
  const _TsxWorkspaceHeader({
    required this.label,
    required this.subtle,
  });

  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              CupertinoIcons.square_stack_3d_down_right_fill,
              color: Color(0xFF2DD4BF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer une surface',
                  style: TextStyle(
                    color: label,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Créez des surfaces animées à partir d’atlas TSX en quelques étapes simples.',
                  style: TextStyle(color: subtle, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TsxReferenceActionBar extends StatelessWidget {
  const _TsxReferenceActionBar({
    required this.loading,
    required this.mistralPending,
    required this.hasAnimations,
    required this.hasMistralKey,
    required this.hasAcceptedSuggestions,
    required this.onImport,
    required this.onDetect,
    required this.onApplySuggestions,
    required this.onRunMistral,
  });

  final bool loading;
  final bool mistralPending;
  final bool hasAnimations;
  final bool hasMistralKey;
  final bool hasAcceptedSuggestions;
  final VoidCallback onImport;
  final VoidCallback onDetect;
  final VoidCallback onApplySuggestions;
  final VoidCallback onRunMistral;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('tiled_tsx_reference.action_bar'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ElevatedButton(
            key: const ValueKey('tiled_tsx_reference.import'),
            onPressed: loading ? null : onImport,
            child: Text(loading ? 'Import en cours…' : 'Importer un TSX'),
          ),
          _ReferenceActionButton(
            key: const ValueKey('tiled_tsx_reference.detect'),
            label: 'Détection auto',
            enabled: hasAnimations,
            onPressed: onDetect,
          ),
          _ReferenceActionButton(
            key: const ValueKey('tiled_tsx_reference.apply_suggestions'),
            label: 'Appliquer les suggestions',
            enabled: hasAcceptedSuggestions && !mistralPending,
            onPressed: onApplySuggestions,
          ),
          _ReferenceActionButton(
            key: const ValueKey('tiled_tsx_reference.run_mistral'),
            label: 'Proposer avec Mistral',
            enabled: hasAnimations && hasMistralKey && !mistralPending,
            onPressed: onRunMistral,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading || mistralPending) ...[
                  const CupertinoActivityIndicator(radius: 6),
                  const SizedBox(width: 7),
                  Text(
                    mistralPending
                        ? 'Analyse Mistral en cours…'
                        : 'Import TSX en cours…',
                    style: const TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else
                  Text(
                    hasMistralKey
                        ? 'Assistant IA prêt'
                        : 'Assistant IA optionnel',
                    style: TextStyle(
                      color: hasMistralKey ? const Color(0xFF2DD4BF) : subtle,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceActionButton extends StatelessWidget {
  const _ReferenceActionButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: enabled
          ? const Color(0xFF2563EB).withValues(alpha: 0.20)
          : EditorChrome.islandFillElevated(context),
      borderRadius: BorderRadius.circular(10),
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? const Color(0xFFA5B4FC) : subtle,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SecondaryAnimationBrowserPanel extends StatelessWidget {
  const _SecondaryAnimationBrowserPanel({
    required this.child,
    required this.onClose,
  });

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            key: const ValueKey('tiled_tsx_reference.close_all_animations'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(10),
            onPressed: onClose,
            child: const Text(
              'Retour au builder',
              style: TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ReferenceMistralGroupingPanel extends StatelessWidget {
  const _ReferenceMistralGroupingPanel({
    required this.result,
    required this.pending,
    required this.confirming,
    required this.acceptedSuggestions,
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.onConfirm,
    required this.onCancel,
    required this.onAccept,
    required this.onReject,
  });

  final TiledTsxMistralGroupingResult? result;
  final bool pending;
  final bool confirming;
  final Map<SurfaceVariantRole, TiledTsxRoleAnimationSuggestion>
      acceptedSuggestions;
  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final ValueChanged<TiledTsxRoleAnimationSuggestion> onAccept;
  final ValueChanged<TiledTsxRoleAnimationSuggestion> onReject;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('tiled_tsx_reference.mistral_panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            confirming || pending ? 'Assistant Mistral' : 'Suggestions Mistral',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mistral propose uniquement role → animationId depuis les animations TSX déjà importées. Rien n’est appliqué sans validation.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (confirming) _buildConfirmation(),
          if (pending) _buildProgress(label),
          if (!confirming && !pending && result != null)
            _buildReview(context, result!),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cette analyse enverra une planche visuelle des animations sélectionnées au fournisseur IA configuré. Aucune modification ne sera appliquée automatiquement.',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            CupertinoButton.filled(
              key: const ValueKey('tiled_tsx_reference.mistral_confirm'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: onConfirm,
              child: const Text(
                'Confirmer l’analyse IA',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: onCancel,
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Color(0xFF2DD4BF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgress(Color label) {
    return Row(
      key: const ValueKey('tiled_tsx_reference.mistral_progress'),
      children: [
        const CupertinoActivityIndicator(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mistral analyse les animations sélectionnées avec un niveau de réflexion élevé.',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(
    BuildContext context,
    TiledTsxMistralGroupingResult result,
  ) {
    final groupedWarnings = _groupReferenceMistralWarnings(result.warnings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groupedWarnings.hasWarnings) ...[
          _ReferenceMistralWarningSummary(groupedWarnings: groupedWarnings),
          const SizedBox(height: 8),
        ],
        if (result.suggestions.isEmpty)
          Text(
            'Aucune suggestion exploitable.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11.5,
            ),
          )
        else
          for (final suggestion in result.suggestions)
            _ReferenceMistralSuggestionCard(
              suggestion: suggestion,
              accepted: acceptedSuggestions[suggestion.role]?.animationId ==
                  suggestion.animationId,
              animation: _animationForSuggestion(suggestion),
              atlas: atlas,
              atlasImageBytes: atlasImageBytes,
              onAccept: () => onAccept(suggestion),
              onReject: () => onReject(suggestion),
            ),
      ],
    );
  }

  ProjectSurfaceAnimation? _animationForSuggestion(
    TiledTsxRoleAnimationSuggestion suggestion,
  ) {
    for (final animation in animations) {
      if (animation.id == suggestion.animationId) {
        return animation;
      }
    }
    return null;
  }
}

class _ReferenceMistralSuggestionCard extends StatelessWidget {
  const _ReferenceMistralSuggestionCard({
    required this.suggestion,
    required this.accepted,
    required this.animation,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onAccept,
    required this.onReject,
  });

  final TiledTsxRoleAnimationSuggestion suggestion;
  final bool accepted;
  final ProjectSurfaceAnimation? animation;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accepted
            ? const Color(0xFF2DD4BF).withValues(alpha: 0.12)
            : EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: accepted
              ? const Color(0xFF2DD4BF).withValues(alpha: 0.45)
              : EditorChrome.editorIslandRim(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: animation == null
                ? const _ReferencePreviewFallback()
                : TiledTsxAnimationTilePreview(
                    atlas: atlas,
                    animation: animation!,
                    atlasImageBytes: atlasImageBytes,
                    compact: true,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _referenceRoleLabel(suggestion.role),
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  suggestion.animationId,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Confiance : ${suggestion.confidence.name}',
                  style: TextStyle(color: subtle, fontSize: 11.2),
                ),
                Text(
                  suggestion.reason,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11.2,
                    height: 1.25,
                  ),
                ),
                if (accepted)
                  const Text(
                    'Acceptée, prête à appliquer au draft.',
                    style: TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 11.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    CupertinoButton(
                      key: ValueKey(
                        'tiled_tsx_reference.accept.${suggestion.role.name}',
                      ),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      onPressed: onAccept,
                      child: const Text(
                        'Accepter',
                        style: TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      key: ValueKey(
                        'tiled_tsx_reference.reject.${suggestion.role.name}',
                      ),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      onPressed: onReject,
                      child: const Text(
                        'Rejeter',
                        style: TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceMistralWarningSummary extends StatelessWidget {
  const _ReferenceMistralWarningSummary({required this.groupedWarnings});

  final _ReferenceGroupedMistralWarnings groupedWarnings;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      for (final entry in groupedWarnings.duplicateRoleCounts.entries)
        '${entry.value} suggestions ont été ignorées car elles proposaient déjà ${_mistralWarningRoleLabel(entry.key)}.',
      ...groupedWarnings.otherWarnings,
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFACC15).withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions ignorées',
            style: TextStyle(
              color: Color(0xFFFACC15),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          for (final line in lines)
            Text(
              line,
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReferenceTsxSurfaceBuilder extends StatelessWidget {
  const _ReferenceTsxSurfaceBuilder({
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.catalog,
    required this.activeGroupId,
    required this.roleAnimationIds,
    required this.roleSources,
    required this.detectionMessage,
    required this.saveErrors,
    required this.saveWarnings,
    required this.saveNote,
    required this.onGroupSelected,
    required this.onRoleAssignmentsChanged,
    required this.onSaveSurface,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final ProjectSurfaceCatalog catalog;
  final String? activeGroupId;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
  final String? detectionMessage;
  final List<String> saveErrors;
  final List<String> saveWarnings;
  final String? saveNote;
  final ValueChanged<String> onGroupSelected;
  final ValueChanged<Map<SurfaceVariantRole, String>> onRoleAssignmentsChanged;
  final VoidCallback? onSaveSurface;

  @override
  Widget build(BuildContext context) {
    final groups = buildTiledTsxDetectedAnimationGroups(animations: animations);
    final activeGroup = _activeGroup(groups);
    final selectedIds = activeGroup?.animationIds.toSet() ??
        animations.map((a) => a.id).toSet();
    final canSave = onSaveSurface != null &&
        roleAnimationIds.containsKey(SurfaceVariantRole.isolated);

    return Container(
      key: const ValueKey('tiled_tsx_reference_builder.root'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReferenceStepper(
            hasGroups: groups.isNotEmpty,
            hasCenter:
                roleAnimationIds.containsKey(SurfaceVariantRole.isolated),
            canSave: canSave,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1120) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetectedGroupsColumn(
                      groups: groups,
                      activeGroup: activeGroup,
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      detectionMessage: detectionMessage,
                      onGroupSelected: onGroupSelected,
                    ),
                    const SizedBox(height: 10),
                    _RolesColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      selectedIds: selectedIds,
                      roleAnimationIds: roleAnimationIds,
                      roleSources: roleSources,
                      onChanged: onRoleAssignmentsChanged,
                    ),
                    const SizedBox(height: 10),
                    _PreviewAndSaveColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      roleAnimationIds: roleAnimationIds,
                      canSave: canSave,
                      errors: saveErrors,
                      warnings: saveWarnings,
                      note: saveNote,
                      onSaveSurface: onSaveSurface,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 310,
                    child: _DetectedGroupsColumn(
                      groups: groups,
                      activeGroup: activeGroup,
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      detectionMessage: detectionMessage,
                      onGroupSelected: onGroupSelected,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RolesColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      selectedIds: selectedIds,
                      roleAnimationIds: roleAnimationIds,
                      roleSources: roleSources,
                      onChanged: onRoleAssignmentsChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 360,
                    child: _PreviewAndSaveColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      roleAnimationIds: roleAnimationIds,
                      canSave: canSave,
                      errors: saveErrors,
                      warnings: saveWarnings,
                      note: saveNote,
                      onSaveSurface: onSaveSurface,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  TiledTsxDetectedAnimationGroup? _activeGroup(
    List<TiledTsxDetectedAnimationGroup> groups,
  ) {
    if (activeGroupId == null) {
      return null;
    }
    for (final group in groups) {
      if (group.id == activeGroupId) {
        return group;
      }
    }
    return null;
  }
}

class _ReferenceStepper extends StatelessWidget {
  const _ReferenceStepper({
    required this.hasGroups,
    required this.hasCenter,
    required this.canSave,
  });

  final bool hasGroups;
  final bool hasCenter;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('tiled_tsx_reference.stepper'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StepItem(
              number: '1',
              title: '1. Choisir un groupe d’animations',
              subtitle: 'Sélectionnez un groupe détecté',
              complete: hasGroups,
            ),
          ),
          Expanded(
            child: _StepItem(
              number: '2',
              title: '2. Assigner les rôles',
              subtitle: 'Glissez ou choisissez chaque rôle',
              complete: hasCenter,
            ),
          ),
          Expanded(
            child: _StepItem(
              number: '3',
              title: '3. Prévisualiser et enregistrer',
              subtitle: 'Vérifiez et enregistrez votre surface',
              complete: canSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.complete,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: complete
                ? const Color(0xFF2DD4BF)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: complete ? const Color(0xFF062826) : label,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subtle, fontSize: 10.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetectedGroupsColumn extends StatelessWidget {
  const _DetectedGroupsColumn({
    required this.groups,
    required this.activeGroup,
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.detectionMessage,
    required this.onGroupSelected,
  });

  final List<TiledTsxDetectedAnimationGroup> groups;
  final TiledTsxDetectedAnimationGroup? activeGroup;
  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final String? detectionMessage;
  final ValueChanged<String> onGroupSelected;

  @override
  Widget build(BuildContext context) {
    return _ReferencePanel(
      title: 'Groupes détectés',
      badge: '${groups.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (groups.isEmpty)
            Text(
              'Aucune animation disponible.',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 12,
              ),
            )
          else
            for (final group in groups) ...[
              _DetectedGroupCard(
                group: group,
                active: activeGroup?.id == group.id,
                atlas: atlas,
                animation: _firstAnimationForGroup(group),
                atlasImageBytes: atlasImageBytes,
                onUse: () => onGroupSelected(group.id),
              ),
              if (group != groups.last) const SizedBox(height: 8),
            ],
          if (activeGroup != null) ...[
            const SizedBox(height: 10),
            Text(
              'Groupe actif : ${activeGroup!.label}',
              style: const TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Filtre appliqué au picker : ${activeGroup!.animationIds.length} animations proches dans le TSX.',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          if (detectionMessage != null) ...[
            const SizedBox(height: 10),
            _HintBox(text: detectionMessage!),
          ] else ...[
            const SizedBox(height: 10),
            const _HintBox(
              text:
                  'Astuce : sélectionnez un groupe pour limiter le picker aux animations pertinentes.',
            ),
          ],
        ],
      ),
    );
  }

  ProjectSurfaceAnimation? _firstAnimationForGroup(
    TiledTsxDetectedAnimationGroup group,
  ) {
    for (final id in group.animationIds) {
      for (final animation in animations) {
        if (animation.id == id) {
          return animation;
        }
      }
    }
    return null;
  }
}

class _DetectedGroupCard extends StatelessWidget {
  const _DetectedGroupCard({
    required this.group,
    required this.active,
    required this.atlas,
    required this.animation,
    required this.atlasImageBytes,
    required this.onUse,
  });

  final TiledTsxDetectedAnimationGroup group;
  final bool active;
  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation? animation;
  final Uint8List? atlasImageBytes;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: ValueKey('tiled_tsx_reference.group.${group.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2DD4BF).withValues(alpha: 0.12)
            : EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: active
              ? const Color(0xFF2DD4BF).withValues(alpha: 0.55)
              : EditorChrome.editorIslandRim(context),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 54,
            child: animation == null
                ? const _ReferencePreviewFallback()
                : TiledTsxAnimationTilePreview(
                    atlas: atlas,
                    animation: animation!,
                    atlasImageBytes: atlasImageBytes,
                    compact: true,
                  ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${group.animationIds.length} animations',
                  style: TextStyle(color: subtle, fontSize: 11.2),
                ),
              ],
            ),
          ),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            onPressed: onUse,
            child: const Text(
              'Utiliser',
              style: TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolesColumn extends StatelessWidget {
  const _RolesColumn({
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.selectedIds,
    required this.roleAnimationIds,
    required this.roleSources,
    required this.onChanged,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final Set<String> selectedIds;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
  final ValueChanged<Map<SurfaceVariantRole, String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ReferencePanel(
      title: 'Rôles de surface',
      child: TiledTsxRoleMappingBuilder(
        atlas: atlas,
        animations: animations,
        selectedAnimationIds: selectedIds,
        roleAnimationIds: roleAnimationIds,
        roleSources: roleSources,
        atlasImageBytes: atlasImageBytes,
        onChanged: onChanged,
      ),
    );
  }
}

class _PreviewAndSaveColumn extends StatelessWidget {
  const _PreviewAndSaveColumn({
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.roleAnimationIds,
    required this.canSave,
    required this.errors,
    required this.warnings,
    required this.note,
    required this.onSaveSurface,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final bool canSave;
  final List<String> errors;
  final List<String> warnings;
  final String? note;
  final VoidCallback? onSaveSurface;

  @override
  Widget build(BuildContext context) {
    final center = _animationForRole(SurfaceVariantRole.isolated);
    final onlyCenterAssigned = center != null && roleAnimationIds.length == 1;
    final edgeCount = [
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
    ].where(roleAnimationIds.containsKey).length;
    final cornerCount = [
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ].where(roleAnimationIds.containsKey).length;
    return _ReferencePanel(
      title: 'Prévisualisation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 190,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF101820),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EditorChrome.editorIslandRim(context)),
            ),
            child: center == null
                ? const Center(
                    child: Text(
                      'Assignez Plein(center) pour voir la preview.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : _PreviewTileMosaic(
                    atlas: atlas,
                    animationsByRole: _animationsByRole(),
                    atlasImageBytes: atlasImageBytes,
                  ),
          ),
          if (onlyCenterAssigned) ...[
            const SizedBox(height: 8),
            const Text(
              'Preview partielle : seuls les centres sont assignés.',
              style: TextStyle(
                color: CupertinoColors.systemOrange,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (center != null && roleAnimationIds.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final role in standardSurfaceVariantRoleOrder)
                  if (roleAnimationIds.containsKey(role))
                    _UsedRoleChip(role: role),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const _MiniControl(label: 'Play'),
              const SizedBox(width: 8),
              const Expanded(child: _FrameTrack()),
              const SizedBox(width: 8),
              Text(
                'Boucle',
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'État de la surface',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _StatusChecklistRow(
            label: 'Centre',
            value: center == null ? 'Manquant' : 'OK',
            good: center != null,
          ),
          _StatusChecklistRow(
            label: 'Bords',
            value: '$edgeCount / 4 assignés',
            good: edgeCount == 4,
          ),
          _StatusChecklistRow(
            label: 'Coins',
            value: '$cornerCount / 4 assignés',
            good: cornerCount == 4,
          ),
          _StatusChecklistRow(
            label: 'Cohérence',
            value: center == null ? 'À vérifier' : 'Bonne correspondance',
            good: center != null,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            key: const ValueKey('tiled_tsx_reference_builder.save_surface'),
            onPressed: canSave ? onSaveSurface : null,
            child: const Text('Enregistrer la surface'),
          ),
          const SizedBox(height: 6),
          Text(
            'Enregistrer comme brouillon',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final error in errors) ...[
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          for (final warning in warnings) ...[
            const SizedBox(height: 6),
            Text(
              warning,
              style: const TextStyle(
                color: CupertinoColors.systemOrange,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: const TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ProjectSurfaceAnimation? _animationForRole(SurfaceVariantRole role) {
    final id = roleAnimationIds[role];
    if (id == null) {
      return null;
    }
    for (final animation in animations) {
      if (animation.id == id) {
        return animation;
      }
    }
    return null;
  }

  Map<SurfaceVariantRole, ProjectSurfaceAnimation> _animationsByRole() {
    final mapped = <SurfaceVariantRole, ProjectSurfaceAnimation>{};
    for (final role in standardSurfaceVariantRoleOrder) {
      final animation = _animationForRole(role);
      if (animation != null) {
        mapped[role] = animation;
      }
    }
    return mapped;
  }
}

class _PreviewTileMosaic extends StatelessWidget {
  const _PreviewTileMosaic({
    required this.atlas,
    required this.animationsByRole,
    required this.atlasImageBytes,
  });

  final ProjectSurfaceAtlas? atlas;
  final Map<SurfaceVariantRole, ProjectSurfaceAnimation> animationsByRole;
  final Uint8List? atlasImageBytes;

  @override
  Widget build(BuildContext context) {
    final center = animationsByRole[SurfaceVariantRole.isolated];
    return GridView.count(
      crossAxisCount: 5,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 5; column++)
            _PreviewRoleTile(
              atlas: atlas,
              animation: _animationForCell(row, column, center),
              role: _roleForCell(row, column),
              atlasImageBytes: atlasImageBytes,
            ),
      ],
    );
  }

  SurfaceVariantRole _roleForCell(int row, int column) {
    if (row == 0 && column == 0) {
      return SurfaceVariantRole.cornerNW;
    }
    if (row == 0 && column == 4) {
      return SurfaceVariantRole.cornerNE;
    }
    if (row == 4 && column == 0) {
      return SurfaceVariantRole.cornerSW;
    }
    if (row == 4 && column == 4) {
      return SurfaceVariantRole.cornerSE;
    }
    if (row == 0) {
      return SurfaceVariantRole.endNorth;
    }
    if (row == 4) {
      return SurfaceVariantRole.endSouth;
    }
    if (column == 0) {
      return SurfaceVariantRole.endWest;
    }
    if (column == 4) {
      return SurfaceVariantRole.endEast;
    }
    return SurfaceVariantRole.isolated;
  }

  ProjectSurfaceAnimation _animationForCell(
    int row,
    int column,
    ProjectSurfaceAnimation? center,
  ) {
    final role = _roleForCell(row, column);
    return animationsByRole[role] ?? center!;
  }
}

class _PreviewRoleTile extends StatelessWidget {
  const _PreviewRoleTile({
    required this.atlas,
    required this.animation,
    required this.role,
    required this.atlasImageBytes,
  });

  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation animation;
  final SurfaceVariantRole role;
  final Uint8List? atlasImageBytes;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('tiled_tsx_reference_preview.role.${role.name}'),
      child: TiledTsxAnimationTilePreview(
        atlas: atlas,
        animation: animation,
        atlasImageBytes: atlasImageBytes,
        compact: true,
      ),
    );
  }
}

class _UsedRoleChip extends StatelessWidget {
  const _UsedRoleChip({required this.role});

  final SurfaceVariantRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('tiled_tsx_reference_preview.used_role.${role.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        _referenceRoleLabel(role),
        style: const TextStyle(
          color: Color(0xFF2DD4BF),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReferencePanel extends StatelessWidget {
  const _ReferencePanel({
    required this.title,
    required this.child,
    this.badge,
  });

  final String title;
  final String? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 11.5,
          height: 1.3,
        ),
      ),
    );
  }
}

class _ReferencePreviewFallback extends StatelessWidget {
  const _ReferencePreviewFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: const Center(
        child: Text(
          'Preview',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  const _MiniControl({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF062826),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FrameTrack extends StatelessWidget {
  const _FrameTrack();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: EditorChrome.editorIslandRim(context),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.35,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _StatusChecklistRow extends StatelessWidget {
  const _StatusChecklistRow({
    required this.label,
    required this.value,
    required this.good,
  });

  final String label;
  final String value;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            good
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.info,
            color: good
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemOrange,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: good
                  ? CupertinoColors.systemGreen.resolveFrom(context)
                  : EditorChrome.subtleLabel(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum TiledTsxDetectedAnimationGroupKind {
  heuristic,
  selection,
}

final class TiledTsxDetectedAnimationGroup {
  const TiledTsxDetectedAnimationGroup({
    required this.id,
    required this.label,
    required this.animationIds,
    required this.kind,
    required this.confidence,
  });

  final String id;
  final String label;
  final List<String> animationIds;
  final TiledTsxDetectedAnimationGroupKind kind;
  final double confidence;
}

List<TiledTsxDetectedAnimationGroup> buildTiledTsxDetectedAnimationGroups({
  required List<ProjectSurfaceAnimation> animations,
}) {
  if (animations.isEmpty) {
    return const <TiledTsxDetectedAnimationGroup>[];
  }
  final items = buildTiledTsxAnimationBrowserItems(animations: animations);
  final sorted = [...items]
    ..sort((a, b) => a.baseTileId.compareTo(b.baseTileId));
  final groupSize = sorted.length <= 40 ? sorted.length : 40;
  final groups = <TiledTsxDetectedAnimationGroup>[];
  for (var start = 0; start < sorted.length; start += groupSize) {
    final slice = sorted.skip(start).take(groupSize).toList(growable: false);
    final number = groups.length + 1;
    groups.add(
      TiledTsxDetectedAnimationGroup(
        id: 'group-$number',
        label: 'Groupe détecté $number',
        animationIds:
            List<String>.unmodifiable(slice.map((item) => item.animationId)),
        kind: TiledTsxDetectedAnimationGroupKind.heuristic,
        confidence: 0.5,
      ),
    );
  }
  return List<TiledTsxDetectedAnimationGroup>.unmodifiable(groups);
}

final class _ReferenceGroupedMistralWarnings {
  const _ReferenceGroupedMistralWarnings({
    required this.duplicateRoleCounts,
    required this.otherWarnings,
  });

  final Map<String, int> duplicateRoleCounts;
  final List<String> otherWarnings;

  bool get hasWarnings =>
      duplicateRoleCounts.isNotEmpty || otherWarnings.isNotEmpty;
}

_ReferenceGroupedMistralWarnings _groupReferenceMistralWarnings(
  List<String> warnings,
) {
  final duplicateRoleCounts = <String, int>{};
  final otherWarnings = <String>[];
  final duplicateRoleRegex =
      RegExp(r'^Rôle Mistral dupliqué rejeté : ([A-Za-z0-9_]+)\.$');
  for (final warning in warnings) {
    final match = duplicateRoleRegex.firstMatch(warning);
    if (match == null) {
      otherWarnings.add(warning);
      continue;
    }
    final roleName = match.group(1)!;
    duplicateRoleCounts[roleName] = (duplicateRoleCounts[roleName] ?? 0) + 1;
  }
  return _ReferenceGroupedMistralWarnings(
    duplicateRoleCounts: Map<String, int>.unmodifiable(duplicateRoleCounts),
    otherWarnings: List<String>.unmodifiable(otherWarnings),
  );
}

String _referenceRoleLabel(SurfaceVariantRole role) {
  if (role == SurfaceVariantRole.isolated) {
    return 'Plein(center)';
  }
  return SurfaceStudioRoleLabels.labelForRole(role);
}

String _mistralWarningRoleLabel(String roleName) {
  for (final role in standardSurfaceVariantRoleOrder) {
    if (role.name == roleName) {
      return _referenceRoleLabel(role);
    }
  }
  return roleName;
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.$1,
                      style: TextStyle(color: subtle, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(color: label, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

ProjectSurfaceAtlas? _atlasForBrowser(ProjectSurfaceCatalog catalog) {
  for (final animation in catalog.animations) {
    final frames = animation.timeline.frames;
    if (frames.isEmpty) {
      continue;
    }
    final atlas = catalog.atlasById(frames.first.tileRef.atlasId);
    if (atlas != null) {
      return atlas;
    }
  }
  return catalog.atlases.isEmpty ? null : catalog.atlases.first;
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final slug = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'tsx-import' : slug;
}

String _nextSurfacePresetId(ProjectSurfaceCatalog catalog) {
  var index = catalog.presetCount;
  while (true) {
    final id = 'tsx-surface-$index';
    if (!catalog.containsPreset(id)) {
      return id;
    }
    index++;
  }
}
