import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        DropdownButton,
        DropdownMenuItem,
        ElevatedButton,
        Material,
        MaterialType;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../ui/shared/cupertino_editor_widgets.dart';
import 'tiled_tsx_animated_tileset_parser.dart';
import 'tiled_tsx_animation_browser.dart';
import 'tiled_tsx_catalog_append.dart';
import 'tiled_tsx_mistral_grouping_suggester.dart';
import 'tiled_tsx_surface_animation_importer.dart';

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
    final xml = await File(path).readAsString();
    return TiledTsxLoadedFile(
      path: path,
      fileName: p.basename(path),
      xml: xml,
    );
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
    return SingleChildScrollView(
      key: const ValueKey('surface_studio.tsx_workspace'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Workspace TSX',
            style: TextStyle(
              color: label,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Importez un fichier .tsx Tiled, choisissez l’image tileset PokeMap correspondante, puis parcourez les animations Surface produites.',
            style: TextStyle(color: subtle, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _ImportSection(
            loadedFile: _loadedFile,
            audit: _audit,
            projectTilesets: widget.projectTilesets,
            selectedTileset: _selectedTileset,
            loading: _loading,
            statusMessage: _statusMessage,
            errors: _errors,
            onPickTsx: _pickTsx,
            onTilesetChanged: (tileset) {
              setState(() => _selectedTileset = tileset);
            },
            onConfirmImport: _canConfirmImport ? _confirmImport : null,
          ),
          const SizedBox(height: 14),
          if (animations.isEmpty)
            _TsxEmptyState(onImportPressed: _pickTsx)
          else
            TiledTsxAnimationBrowser(
              atlas: atlas,
              animations: animations,
              atlasImageBytes: widget.atlasImageBytes,
              sourceLabel: _loadedFile?.fileName ?? 'Catalogue de travail',
              catalog: effectiveCatalog,
              onSurfaceCatalogChanged: widget.onSurfaceCatalogChanged,
              projectSettings: widget.projectSettings,
              groupingSuggester: widget.groupingSuggester,
            ),
        ],
      ),
    );
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
      _statusMessage =
          'Import TSX prêt : ${imported.animations.length} animations ajoutées.';
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
        if (p.basename(tileset.relativePath).toLowerCase() == expectedBasename) {
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
                child: Text(loading ? 'Chargement…' : 'Importer un fichier TSX'),
              ),
            ],
          ),
          if (audit != null) ...[
            const SizedBox(height: 12),
            _TsxSummary(audit: audit!, loadedFile: loadedFile),
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
  });

  final TiledTsxTilesetAudit audit;
  final TiledTsxLoadedFile? loadedFile;

  @override
  Widget build(BuildContext context) {
    final s = audit.summary;
    return _InfoBlock(
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
        ('transparentColor', s.transparentColor ?? 'aucune'),
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
