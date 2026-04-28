import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_role_mapping_preview.dart';

const Color _accent = Color(0xFF2DD4BF);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);

typedef SurfaceStudioAtlasUiImageLoader = Future<ui.Image?> Function(
  String absolutePath,
);

/// Charge une image atlas Surface pour le mapping visuel.
///
/// Ce helper reste volontairement local au Surface Studio : le Lot 88-quinquies
/// a besoin d'un aperçu editor depuis le disque, pas d'un nouveau service
/// d'assets partagé ni d'un contrat runtime.
Future<ui.Image?> loadSurfaceStudioRoleMappingAtlasImage(
  String absolutePath,
) async {
  try {
    final bytes = await File(absolutePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

/// Une animation Surface présentée comme une colonne d'atlas modifiable.
///
/// Dans les catalogues générés depuis un atlas vertical, chaque animation
/// correspond en pratique à une colonne. Le modèle persistant reste
/// rôle -> animationId ; cette vue reconstruit juste une lecture visuelle
/// colonne -> rôles pour que l'utilisateur n'édite plus une liste abstraite.
class SurfaceStudioRoleMappingColumnOption {
  const SurfaceStudioRoleMappingColumnOption({
    required this.animation,
    required this.atlasId,
    required this.columnIndex,
    required this.rowIndex,
    required this.assignedRoles,
  });

  final ProjectSurfaceAnimation animation;
  final String atlasId;
  final int columnIndex;
  final int rowIndex;
  final List<SurfaceVariantRole> assignedRoles;

  String get animationId => animation.id;

  int get frameCount => animation.frameCount;

  bool get isAssigned => assignedRoles.isNotEmpty;

  bool get hasDuplicateAssignment => assignedRoles.length > 1;
}

/// Analyse locale du preset courant pour alimenter la UI visuelle.
///
/// Elle ne valide pas le catalogue au sens métier global : elle résume seulement
/// ce que l'utilisateur doit voir pour corriger un mapping dans le catalogue de
/// travail Surface Studio.
class SurfaceStudioRoleMappingAnalysis {
  SurfaceStudioRoleMappingAnalysis._({
    required this.columns,
    required this.assignedColumnCount,
    required this.unassignedColumnCount,
    required this.duplicateAnimationCount,
    required this.missingRoleCount,
  });

  final List<SurfaceStudioRoleMappingColumnOption> columns;
  final int assignedColumnCount;
  final int unassignedColumnCount;
  final int duplicateAnimationCount;
  final int missingRoleCount;

  factory SurfaceStudioRoleMappingAnalysis.fromCatalog({
    required ProjectSurfaceCatalog catalog,
    required ProjectSurfacePreset preset,
  }) {
    final rolesByAnimation = <String, List<SurfaceVariantRole>>{};
    for (final ref in preset.variantAnimations.refs) {
      rolesByAnimation
          .putIfAbsent(ref.animationId, () => <SurfaceVariantRole>[])
          .add(ref.role);
    }

    final columns = <SurfaceStudioRoleMappingColumnOption>[];
    for (final animation in catalog.animations) {
      final firstFrame = animation.timeline.frames.first;
      columns.add(
        SurfaceStudioRoleMappingColumnOption(
          animation: animation,
          atlasId: firstFrame.tileRef.atlasId,
          columnIndex: firstFrame.tileRef.column,
          rowIndex: firstFrame.tileRef.row,
          assignedRoles: List<SurfaceVariantRole>.unmodifiable(
            rolesByAnimation[animation.id] ?? const <SurfaceVariantRole>[],
          ),
        ),
      );
    }

    columns.sort((a, b) {
      final atlas = a.atlasId.compareTo(b.atlasId);
      if (atlas != 0) {
        return atlas;
      }
      final col = a.columnIndex.compareTo(b.columnIndex);
      if (col != 0) {
        return col;
      }
      return a.animation.id.compareTo(b.animation.id);
    });

    final assigned = columns.where((column) => column.isAssigned).length;
    final duplicates =
        columns.where((column) => column.hasDuplicateAssignment).length;
    final missingRoles = standardSurfaceVariantRoleOrder
        .where((role) => !preset.containsRole(role))
        .length;

    return SurfaceStudioRoleMappingAnalysis._(
      columns: List<SurfaceStudioRoleMappingColumnOption>.unmodifiable(columns),
      assignedColumnCount: assigned,
      unassignedColumnCount: columns.length - assigned,
      duplicateAnimationCount: duplicates,
      missingRoleCount: missingRoles,
    );
  }

  SurfaceStudioRoleMappingColumnOption? columnByAnimationId(String? id) {
    if (id == null) {
      return null;
    }
    for (final column in columns) {
      if (column.animation.id == id) {
        return column;
      }
    }
    return null;
  }
}

class SurfaceStudioRoleMappingEditor extends StatefulWidget {
  const SurfaceStudioRoleMappingEditor({
    super.key,
    required this.catalog,
    required this.preset,
    this.projectRootPath,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.imageLoader,
    this.onRoleAnimationChanged,
  });

  final ProjectSurfaceCatalog catalog;
  final ProjectSurfacePreset preset;
  final String? projectRootPath;
  final List<ProjectTilesetEntry> projectTilesets;
  final SurfaceStudioAtlasUiImageLoader? imageLoader;
  final void Function(SurfaceVariantRole role, String animationId)?
      onRoleAnimationChanged;

  @override
  State<SurfaceStudioRoleMappingEditor> createState() =>
      _SurfaceStudioRoleMappingEditorState();
}

class _SurfaceStudioRoleMappingEditorState
    extends State<SurfaceStudioRoleMappingEditor> {
  SurfaceVariantRole _selectedRole = SurfaceVariantRole.cross;
  String? _selectedAnimationId;
  final Map<SurfaceVariantRole, String> _optimisticRoleAnimationIds =
      <SurfaceVariantRole, String>{};

  @override
  void didUpdateWidget(covariant SurfaceStudioRoleMappingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog ||
        widget.preset != oldWidget.preset) {
      _optimisticRoleAnimationIds.clear();
      final analysis = SurfaceStudioRoleMappingAnalysis.fromCatalog(
        catalog: widget.catalog,
        preset: widget.preset,
      );
      if (analysis.columnByAnimationId(_selectedAnimationId) == null) {
        _selectedAnimationId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final analysis = SurfaceStudioRoleMappingAnalysis.fromCatalog(
      catalog: widget.catalog,
      preset: widget.preset,
    );
    final selectedColumn = _resolveSelectedColumn(analysis);

    return Container(
      key: const ValueKey('surface_role_mapping_editor'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Édition du mapping de surface',
            style: TextStyle(
              color: label,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Surface sélectionnée : ${widget.preset.name}',
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Un atlas fournit des colonnes, une animation lit les frames d’une colonne, et un rôle indique où cette animation sera utilisée dans la surface.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (analysis.columns.isEmpty)
            _NoAnimationsState(subtle: subtle, label: label)
          else ...[
            _MappingSummary(analysis: analysis),
            const SizedBox(height: 10),
            _MappingWorkspace(
              analysis: analysis,
              catalog: widget.catalog,
              preset: widget.preset,
              projectRootPath: widget.projectRootPath,
              projectTilesets: widget.projectTilesets,
              imageLoader:
                  widget.imageLoader ?? loadSurfaceStudioRoleMappingAtlasImage,
              selectedRole: _selectedRole,
              selectedColumn: selectedColumn,
              selectedRoleAnimationId:
                  _effectiveAnimationIdForRole(_selectedRole),
              onRoleSelected: _selectRole,
              onColumnSelected: _selectColumn,
              onColumnAssigned: widget.onRoleAnimationChanged == null
                  ? null
                  : _assignColumnToSelectedRole,
            ),
          ],
        ],
      ),
    );
  }

  SurfaceStudioRoleMappingColumnOption? _resolveSelectedColumn(
    SurfaceStudioRoleMappingAnalysis analysis,
  ) {
    final explicit = analysis.columnByAnimationId(_selectedAnimationId);
    if (explicit != null) {
      return explicit;
    }
    final roleAnimationId = widget.preset.animationIdForRole(_selectedRole);
    final currentForRole = analysis.columnByAnimationId(roleAnimationId);
    if (currentForRole != null) {
      return currentForRole;
    }
    if (analysis.columns.isNotEmpty) {
      return analysis.columns.first;
    }
    return null;
  }

  String? _effectiveAnimationIdForRole(SurfaceVariantRole role) {
    return _optimisticRoleAnimationIds[role] ??
        widget.preset.animationIdForRole(role);
  }

  void _selectRole(SurfaceVariantRole role) {
    setState(() {
      _selectedRole = role;
      _selectedAnimationId =
          _effectiveAnimationIdForRole(role) ?? _selectedAnimationId;
    });
  }

  void _selectColumn(SurfaceStudioRoleMappingColumnOption column) {
    setState(() {
      _selectedAnimationId = column.animationId;
    });
  }

  void _assignColumnToSelectedRole(
    SurfaceStudioRoleMappingColumnOption column,
  ) {
    setState(() {
      _selectedAnimationId = column.animationId;
      // Le parent reconstruit normalement le catalogue de travail après le
      // callback. Cette écriture optimiste rend le retour visuel immédiat dans
      // les tests isolés et dans le cas d'un frame avant propagation Riverpod.
      _optimisticRoleAnimationIds[_selectedRole] = column.animationId;
    });
    widget.onRoleAnimationChanged?.call(_selectedRole, column.animationId);
  }
}

class _MappingWorkspace extends StatefulWidget {
  const _MappingWorkspace({
    required this.analysis,
    required this.catalog,
    required this.preset,
    required this.projectRootPath,
    required this.projectTilesets,
    required this.imageLoader,
    required this.selectedRole,
    required this.selectedColumn,
    required this.selectedRoleAnimationId,
    required this.onRoleSelected,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfaceCatalog catalog;
  final ProjectSurfacePreset preset;
  final String? projectRootPath;
  final List<ProjectTilesetEntry> projectTilesets;
  final SurfaceStudioAtlasUiImageLoader imageLoader;
  final SurfaceVariantRole selectedRole;
  final SurfaceStudioRoleMappingColumnOption? selectedColumn;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  State<_MappingWorkspace> createState() => _MappingWorkspaceState();
}

class _MappingWorkspaceState extends State<_MappingWorkspace> {
  _SurfaceAtlasPickerSource? _source;
  String? _imagePath;
  Future<ui.Image?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _refreshImageSource();
  }

  @override
  void didUpdateWidget(covariant _MappingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalog != widget.catalog ||
        oldWidget.preset != widget.preset ||
        oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.projectTilesets != widget.projectTilesets ||
        oldWidget.imageLoader != widget.imageLoader) {
      _refreshImageSource();
    }
  }

  void _refreshImageSource() {
    final source = _resolveSurfaceAtlasPickerSource(
      catalog: widget.catalog,
      preset: widget.preset,
      projectRootPath: widget.projectRootPath,
      projectTilesets: widget.projectTilesets,
    );
    _source = source;
    final path = source.absolutePath;
    if (path == null || path.isEmpty) {
      _imagePath = null;
      _imageFuture = null;
      return;
    }
    if (_imagePath == path && _imageFuture != null) {
      return;
    }
    _imagePath = path;
    _imageFuture = widget.imageLoader(path);
  }

  @override
  Widget build(BuildContext context) {
    final source = _source ??
        _resolveSurfaceAtlasPickerSource(
          catalog: widget.catalog,
          preset: widget.preset,
          projectRootPath: widget.projectRootPath,
          projectTilesets: widget.projectTilesets,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageFuture = _imageFuture;
        if (imageFuture == null) {
          return _buildLayout(
            constraints: constraints,
            source: source,
            atlasImage: null,
            imageLoading: false,
          );
        }
        return FutureBuilder<ui.Image?>(
          future: imageFuture,
          builder: (context, snapshot) => _buildLayout(
            constraints: constraints,
            source: source,
            atlasImage: snapshot.data,
            imageLoading: snapshot.connectionState != ConnectionState.done,
          ),
        );
      },
    );
  }

  Widget _buildLayout({
    required BoxConstraints constraints,
    required _SurfaceAtlasPickerSource source,
    required ui.Image? atlasImage,
    required bool imageLoading,
  }) {
    final slotPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SurfaceSlotSchema(
          analysis: widget.analysis,
          preset: widget.preset,
          selectedRole: widget.selectedRole,
          selectedRoleAnimationId: widget.selectedRoleAnimationId,
          atlasImage: atlasImage,
          atlas: source.atlas,
          onRoleSelected: widget.onRoleSelected,
        ),
        const SizedBox(height: 10),
        _RoleDetail(
          preset: widget.preset,
          selectedRole: widget.selectedRole,
          selectedColumn: widget.selectedColumn,
          currentColumn: widget.analysis
              .columnByAnimationId(widget.selectedRoleAnimationId),
          atlasImage: atlasImage,
          atlas: source.atlas,
          canAssign:
              widget.onColumnAssigned != null && widget.selectedColumn != null,
          onAssign:
              widget.selectedColumn == null || widget.onColumnAssigned == null
                  ? null
                  : () => widget.onColumnAssigned!(widget.selectedColumn!),
        ),
      ],
    );

    final atlasPane = _RealAtlasPicker(
      analysis: widget.analysis,
      source: source,
      atlasImage: atlasImage,
      imageLoading: imageLoading,
      selectedRole: widget.selectedRole,
      selectedAnimationId: widget.selectedColumn?.animationId,
      selectedRoleAnimationId: widget.selectedRoleAnimationId,
      onColumnSelected: widget.onColumnSelected,
      onColumnAssigned: widget.onColumnAssigned,
    );

    if (constraints.maxWidth >= 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 350, child: slotPane),
          const SizedBox(width: 12),
          Expanded(child: atlasPane),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        slotPane,
        const SizedBox(height: 10),
        atlasPane,
      ],
    );
  }
}

class _SurfaceAtlasPickerSource {
  const _SurfaceAtlasPickerSource({
    required this.atlasIds,
    this.atlas,
    this.tileset,
    this.absolutePath,
    this.message,
  });

  final Set<String> atlasIds;
  final ProjectSurfaceAtlas? atlas;
  final ProjectTilesetEntry? tileset;
  final String? absolutePath;
  final String? message;

  bool get hasMultipleAtlases => atlasIds.length > 1;
}

_SurfaceAtlasPickerSource _resolveSurfaceAtlasPickerSource({
  required ProjectSurfaceCatalog catalog,
  required ProjectSurfacePreset preset,
  required String? projectRootPath,
  required List<ProjectTilesetEntry> projectTilesets,
}) {
  final animationIds = preset.variantAnimations.refs
      .map((ref) => ref.animationId)
      .where((id) => id.trim().isNotEmpty)
      .toSet();
  final atlasIds = <String>{};
  for (final animation in catalog.animations) {
    if (!animationIds.contains(animation.id)) {
      continue;
    }
    final firstFrame = animation.timeline.frames.first;
    atlasIds.add(firstFrame.tileRef.atlasId);
  }
  if (atlasIds.isEmpty) {
    return const _SurfaceAtlasPickerSource(
      atlasIds: <String>{},
      message:
          'Aucune animation liée ne permet de retrouver un atlas réel pour cette surface.',
    );
  }

  final atlasId = atlasIds.first;
  ProjectSurfaceAtlas? atlas;
  for (final candidate in catalog.atlases) {
    if (candidate.id == atlasId) {
      atlas = candidate;
      break;
    }
  }
  if (atlas == null) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      message: 'Atlas Surface introuvable : $atlasId.',
    );
  }

  ProjectTilesetEntry? tileset;
  for (final entry in projectTilesets) {
    if (entry.id == atlas.tilesetId) {
      tileset = entry;
      break;
    }
  }
  if (tileset == null) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      atlas: atlas,
      message:
          'Jeu d’images introuvable pour l’atlas ${atlas.name} (${atlas.tilesetId}).',
    );
  }

  final root = projectRootPath?.trim();
  final rel = tileset.relativePath.trim();
  if (root == null || root.isEmpty) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      atlas: atlas,
      tileset: tileset,
      message:
          'Projet sans dossier ouvert sur disque. Chemin attendu dans le manifeste : $rel.',
    );
  }
  if (rel.isEmpty) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      atlas: atlas,
      tileset: tileset,
      message:
          'Le jeu d’images ${tileset.name} n’a pas de chemin relatif dans le manifeste.',
    );
  }

  return _SurfaceAtlasPickerSource(
    atlasIds: atlasIds,
    atlas: atlas,
    tileset: tileset,
    absolutePath: p.normalize(p.join(root, rel)),
  );
}

class _NoAnimationsState extends StatelessWidget {
  const _NoAnimationsState({
    required this.subtle,
    required this.label,
  });

  final Color subtle;
  final Color label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context)
            .withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucune animation disponible.',
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Générez d’abord les animations depuis l’atlas.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MappingSummary extends StatelessWidget {
  const _MappingSummary({required this.analysis});

  final SurfaceStudioRoleMappingAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_mapping_summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé du mapping',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetricChip('Colonnes : ${analysis.columns.length}'),
              _MetricChip('Assignées : ${analysis.assignedColumnCount}'),
              _MetricChip('Non assignées : ${analysis.unassignedColumnCount}'),
              _MetricChip(
                'Doublons : ${analysis.duplicateAnimationCount}',
                color: analysis.duplicateAnimationCount > 0 ? _danger : _accent,
              ),
              _MetricChip(
                'Rôles manquants : ${analysis.missingRoleCount}',
                color: analysis.missingRoleCount > 0 ? _warning : _accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            analysis.duplicateAnimationCount > 0
                ? 'Un même extrait de colonne est utilisé par plusieurs rôles. Vérifiez que c’est volontaire.'
                : 'Chaque colonne assignée pointe vers un rôle unique.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SurfaceSlotSchema extends StatelessWidget {
  const _SurfaceSlotSchema({
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.atlasImage,
    required this.atlas,
    required this.onRoleSelected,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  static const List<SurfaceVariantRole> _mainSurfaceShape =
      <SurfaceVariantRole>[
    SurfaceVariantRole.cornerNW,
    SurfaceVariantRole.endNorth,
    SurfaceVariantRole.cornerNE,
    SurfaceVariantRole.endWest,
    SurfaceVariantRole.cross,
    SurfaceVariantRole.endEast,
    SurfaceVariantRole.cornerSW,
    SurfaceVariantRole.endSouth,
    SurfaceVariantRole.cornerSE,
  ];

  static const List<SurfaceVariantRole> _centerVariants = <SurfaceVariantRole>[
    SurfaceVariantRole.isolated,
    SurfaceVariantRole.horizontal,
    SurfaceVariantRole.vertical,
  ];

  static const List<SurfaceVariantRole> _junctionVariants =
      <SurfaceVariantRole>[
    SurfaceVariantRole.teeNorth,
    SurfaceVariantRole.teeEast,
    SurfaceVariantRole.teeSouth,
    SurfaceVariantRole.teeWest,
  ];

  static const List<SurfaceVariantRole> _innerCornerVariants =
      <SurfaceVariantRole>[
    SurfaceVariantRole.innerCornerNE,
    SurfaceVariantRole.innerCornerSE,
    SurfaceVariantRole.innerCornerSW,
    SurfaceVariantRole.innerCornerNW,
  ];

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_slot_schema'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Schéma des slots Surface',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cliquez un slot, puis une colonne',
            style: TextStyle(
              color: _accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Le slot représente la position logique de la tile dans une surface continue.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}',
            key: const ValueKey('surface_role_active_slot_label'),
            style: const TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _SurfaceSlotGrid(
            roles: _mainSurfaceShape,
            columns: 3,
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            atlasImage: atlasImage,
            atlas: atlas,
            onRoleSelected: onRoleSelected,
          ),
          const SizedBox(height: 10),
          Text(
            'Centre et continuités',
            style: TextStyle(
              color: label,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _SurfaceSlotWrap(
            roles: _centerVariants,
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            atlasImage: atlasImage,
            atlas: atlas,
            onRoleSelected: onRoleSelected,
          ),
          const SizedBox(height: 10),
          Text(
            'Jonctions et coins intérieurs',
            style: TextStyle(
              color: label,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _SurfaceSlotWrap(
            roles: const <SurfaceVariantRole>[
              ..._junctionVariants,
              ..._innerCornerVariants,
            ],
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            atlasImage: atlasImage,
            atlas: atlas,
            onRoleSelected: onRoleSelected,
          ),
        ],
      ),
    );
  }
}

class _SurfaceSlotGrid extends StatelessWidget {
  const _SurfaceSlotGrid({
    required this.roles,
    required this.columns,
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.atlasImage,
    required this.atlas,
    required this.onRoleSelected,
  });

  final List<SurfaceVariantRole> roles;
  final int columns;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final available = constraints.maxWidth - (gap * (columns - 1));
        final cellWidth = available / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final role in roles)
              SizedBox(
                width: cellWidth,
                child: _SurfaceRoleSlot(
                  role: role,
                  column: _columnForRole(role),
                  atlasImage: atlasImage,
                  atlas: atlas,
                  selected: role == selectedRole,
                  isSelectedRoleAssignment:
                      selectedRole == role && selectedRoleAnimationId != null,
                  onTap: () => onRoleSelected(role),
                ),
              ),
          ],
        );
      },
    );
  }

  SurfaceStudioRoleMappingColumnOption? _columnForRole(
    SurfaceVariantRole role,
  ) {
    final animationId = role == selectedRole
        ? selectedRoleAnimationId
        : preset.animationIdForRole(role);
    return analysis.columnByAnimationId(animationId);
  }
}

class _SurfaceSlotWrap extends StatelessWidget {
  const _SurfaceSlotWrap({
    required this.roles,
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.atlasImage,
    required this.atlas,
    required this.onRoleSelected,
  });

  final List<SurfaceVariantRole> roles;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final role in roles)
          SizedBox(
            width: 112,
            child: _SurfaceRoleSlot(
              role: role,
              column: _columnForRole(role),
              atlasImage: atlasImage,
              atlas: atlas,
              selected: role == selectedRole,
              isSelectedRoleAssignment:
                  selectedRole == role && selectedRoleAnimationId != null,
              onTap: () => onRoleSelected(role),
            ),
          ),
      ],
    );
  }

  SurfaceStudioRoleMappingColumnOption? _columnForRole(
    SurfaceVariantRole role,
  ) {
    final animationId = role == selectedRole
        ? selectedRoleAnimationId
        : preset.animationIdForRole(role);
    return analysis.columnByAnimationId(animationId);
  }
}

class _SurfaceRoleSlot extends StatelessWidget {
  const _SurfaceRoleSlot({
    required this.role,
    required this.column,
    required this.atlasImage,
    required this.atlas,
    required this.selected,
    required this.isSelectedRoleAssignment,
    required this.onTap,
  });

  final SurfaceVariantRole role;
  final SurfaceStudioRoleMappingColumnOption? column;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final bool selected;
  final bool isSelectedRoleAssignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final linked = column != null || isSelectedRoleAssignment;
    final color = linked ? _accent : _warning;
    return GestureDetector(
      key: ValueKey('surface_role_slot_${role.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.20)
              : EditorChrome.elevatedPanelBackground(context)
                  .withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.90)
                : color.withValues(alpha: 0.34),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (column != null && atlasImage != null && atlas != null)
              _SurfaceColumnCropPreview(
                key: ValueKey('surface_role_real_crop_${role.name}'),
                image: atlasImage!,
                atlas: atlas!,
                column: column!,
                size: 34,
              )
            else
              _SurfaceRoleGlyph(role: role, selected: selected, linked: linked),
            const SizedBox(height: 5),
            Text(
              surfaceStudioRoleMappingLabel(role),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 9.6,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              column == null ? 'À lier' : 'Col ${column!.columnIndex}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: column == null ? subtle : _accent,
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceRoleGlyph extends StatelessWidget {
  const _SurfaceRoleGlyph({
    required this.role,
    required this.selected,
    required this.linked,
  });

  final SurfaceVariantRole role;
  final bool selected;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 26,
      child: CustomPaint(
        painter: _SurfaceRoleGlyphPainter(
          role: role,
          selected: selected,
          linked: linked,
        ),
      ),
    );
  }
}

class _SurfaceRoleGlyphPainter extends CustomPainter {
  const _SurfaceRoleGlyphPainter({
    required this.role,
    required this.selected,
    required this.linked,
  });

  final SurfaceVariantRole role;
  final bool selected;
  final bool linked;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.24;
    final active = selected ? _accent : _accent.withValues(alpha: 0.82);
    final inactive = linked
        ? _accent.withValues(alpha: 0.24)
        : _warning.withValues(alpha: 0.22);
    final activePaint = Paint()
      ..color = active
      ..strokeWidth = selected ? 3 : 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final inactivePaint = Paint()
      ..color = inactive
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = (linked ? _accent : _warning).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, inactivePaint);

    final connections = _surfaceRoleConnections(role);
    final north = Offset(center.dx, 1.5);
    final east = Offset(size.width - 1.5, center.dy);
    final south = Offset(center.dx, size.height - 1.5);
    final west = Offset(1.5, center.dy);

    void drawArm(bool enabled, Offset target) {
      canvas.drawLine(center, target, enabled ? activePaint : inactivePaint);
    }

    drawArm(connections.north, north);
    drawArm(connections.east, east);
    drawArm(connections.south, south);
    drawArm(connections.west, west);

    final notch = _surfaceInnerCornerAlignment(role);
    if (notch != null) {
      final notchCenter = Offset(
        center.dx + notch.dx * radius * 1.35,
        center.dy + notch.dy * radius * 1.35,
      );
      canvas.drawCircle(
        notchCenter,
        4,
        Paint()
          ..color = _danger.withValues(alpha: 0.60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceRoleGlyphPainter oldDelegate) {
    return oldDelegate.role != role ||
        oldDelegate.selected != selected ||
        oldDelegate.linked != linked;
  }
}

class _ColumnGallery extends StatelessWidget {
  const _ColumnGallery({
    required this.analysis,
    required this.selectedRole,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final SurfaceVariantRole selectedRole;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_column_gallery'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galerie des colonnes',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez une colonne pour l’assigner au slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width >= 248 ? (width - 8) / 2 : width;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final column in analysis.columns)
                    SizedBox(
                      width: cardWidth,
                      child: _ColumnCard(
                        column: column,
                        selected: column.animationId == selectedAnimationId,
                        assignedToSelectedRole:
                            column.animationId == selectedRoleAnimationId,
                        onTap: () {
                          onColumnSelected(column);
                          onColumnAssigned?.call(column);
                        },
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
}

class _RealAtlasPicker extends StatefulWidget {
  const _RealAtlasPicker({
    required this.analysis,
    required this.source,
    required this.atlasImage,
    required this.imageLoading,
    required this.selectedRole,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final _SurfaceAtlasPickerSource source;
  final ui.Image? atlasImage;
  final bool imageLoading;
  final SurfaceVariantRole selectedRole;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  State<_RealAtlasPicker> createState() => _RealAtlasPickerState();
}

class _RealAtlasPickerState extends State<_RealAtlasPicker> {
  int? _selectedColumnIndex;
  String? _lastClickMessage;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final image = widget.atlasImage;
    final atlas = widget.source.atlas;

    return _Panellet(
      key: const ValueKey('surface_real_atlas_picker'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Atlas réel cliquable',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Étape 2 : cliquez une colonne dans l’image atlas réelle pour l’assigner au slot actif : ${surfaceStudioRoleMappingLabel(widget.selectedRole)}.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          if (widget.source.hasMultipleAtlases) ...[
            const SizedBox(height: 6),
            Text(
              'Plusieurs atlas sont référencés par cette surface. V0 affiche l’atlas ${atlas?.name ?? widget.source.atlasIds.first}.',
              style: const TextStyle(
                color: _warning,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.imageLoading)
            _RealAtlasMessage(
              title: 'Chargement de l’image atlas…',
              body: widget.source.absolutePath ?? '',
            )
          else if (image != null && atlas != null)
            _AtlasImageHitArea(
              image: image,
              atlas: atlas,
              analysis: widget.analysis,
              selectedColumnIndex: _selectedColumnIndex,
              selectedAnimationId: widget.selectedAnimationId,
              selectedRoleAnimationId: widget.selectedRoleAnimationId,
              onColumnTapped: _assignColumn,
            )
          else ...[
            _RealAtlasMessage(
              title: 'Image atlas réelle indisponible',
              body: widget.source.message ??
                  'Le fichier image n’a pas pu être chargé : ${widget.source.absolutePath ?? 'chemin indisponible'}.',
            ),
            const SizedBox(height: 10),
            _ColumnGallery(
              analysis: widget.analysis,
              selectedRole: widget.selectedRole,
              selectedAnimationId: widget.selectedAnimationId,
              selectedRoleAnimationId: widget.selectedRoleAnimationId,
              onColumnSelected: widget.onColumnSelected,
              onColumnAssigned: widget.onColumnAssigned,
            ),
          ],
          if (_lastClickMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _lastClickMessage!,
              key: const ValueKey('surface_real_atlas_click_message'),
              style: TextStyle(
                color: _lastClickMessage!.startsWith('Colonne assignée')
                    ? _accent
                    : _warning,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _assignColumn(int columnIndex) {
    final atlas = widget.source.atlas;
    if (atlas == null) {
      return;
    }
    SurfaceStudioRoleMappingColumnOption? match;
    for (final column in widget.analysis.columns) {
      if (column.atlasId == atlas.id && column.columnIndex == columnIndex) {
        match = column;
        break;
      }
    }
    setState(() {
      _selectedColumnIndex = columnIndex;
      _lastClickMessage = match == null
          ? 'Col $columnIndex ne correspond à aucune animation générée.'
          : 'Colonne assignée : Col $columnIndex → ${surfaceStudioRoleMappingLabel(widget.selectedRole)}.';
    });
    if (match == null) {
      return;
    }
    widget.onColumnSelected(match);
    widget.onColumnAssigned?.call(match);
  }
}

class _RealAtlasMessage extends StatelessWidget {
  const _RealAtlasMessage({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('surface_real_atlas_fallback'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warning.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _AtlasImageHitArea extends StatelessWidget {
  const _AtlasImageHitArea({
    required this.image,
    required this.atlas,
    required this.analysis,
    required this.selectedColumnIndex,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
    required this.onColumnTapped,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final int? selectedColumnIndex;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;
  final ValueChanged<int> onColumnTapped;

  @override
  Widget build(BuildContext context) {
    final columns = atlas.geometry.gridSize.columns;
    final aspect = image.width / image.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        const maxHeight = 440.0;
        var renderWidth = maxWidth;
        var renderHeight = renderWidth / aspect;
        if (renderHeight > maxHeight) {
          renderHeight = maxHeight;
          renderWidth = renderHeight * aspect;
        }
        renderWidth = renderWidth.clamp(1.0, maxWidth).toDouble();
        renderHeight = renderHeight.clamp(1.0, maxHeight).toDouble();

        void tapAt(Offset localPosition) {
          final dx = localPosition.dx.clamp(0.0, renderWidth - 0.0001);
          final column =
              (dx / (renderWidth / columns)).floor().clamp(0, columns - 1);
          onColumnTapped(column);
        }

        return Center(
          child: SizedBox(
            key: const ValueKey('surface_real_atlas_hit_area'),
            width: renderWidth,
            height: renderHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => tapAt(details.localPosition),
              child: CustomPaint(
                key: const ValueKey('surface_real_atlas_grid'),
                painter: _SurfaceAtlasMappingPainter(
                  image: image,
                  atlas: atlas,
                  analysis: analysis,
                  selectedColumnIndex: selectedColumnIndex,
                  selectedAnimationId: selectedAnimationId,
                  selectedRoleAnimationId: selectedRoleAnimationId,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SurfaceAtlasMappingPainter extends CustomPainter {
  const _SurfaceAtlasMappingPainter({
    required this.image,
    required this.atlas,
    required this.analysis,
    required this.selectedColumnIndex,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final int? selectedColumnIndex;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dest = Offset.zero & size;
    canvas.drawImageRect(
      image,
      source,
      dest,
      Paint()..filterQuality = FilterQuality.none,
    );

    final columns = atlas.geometry.gridSize.columns;
    final rows = atlas.geometry.gridSize.rows;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (final column in analysis.columns) {
      if (column.atlasId != atlas.id) {
        continue;
      }
      final left = column.columnIndex * cellWidth;
      final rect = Rect.fromLTWH(left, 0, cellWidth, size.height);
      final assignedToSelectedRole =
          column.animationId == selectedRoleAnimationId;
      final selected = column.animationId == selectedAnimationId ||
          column.columnIndex == selectedColumnIndex;
      final fillColor = assignedToSelectedRole
          ? _accent.withValues(alpha: 0.26)
          : column.hasDuplicateAssignment
              ? _danger.withValues(alpha: 0.18)
              : column.isAssigned
                  ? _accent.withValues(alpha: 0.13)
                  : _warning.withValues(alpha: 0.09);
      canvas.drawRect(rect, Paint()..color = fillColor);
      if (selected) {
        canvas.drawRect(
          rect.deflate(1),
          Paint()
            ..color = _accent
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }

      final tp = TextPainter(
        text: TextSpan(
          text: 'Col ${column.columnIndex}',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Color(0xCC000000), blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(24, cellWidth - 4));
      tp.paint(canvas, Offset(left + 4, 4));
    }

    final gridPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i <= columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var j = 0; j <= rows; j++) {
      final y = j * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceAtlasMappingPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.atlas != atlas ||
        oldDelegate.analysis != analysis ||
        oldDelegate.selectedColumnIndex != selectedColumnIndex ||
        oldDelegate.selectedAnimationId != selectedAnimationId ||
        oldDelegate.selectedRoleAnimationId != selectedRoleAnimationId;
  }
}

class _ColumnCard extends StatelessWidget {
  const _ColumnCard({
    required this.column,
    required this.selected,
    required this.assignedToSelectedRole,
    required this.onTap,
  });

  final SurfaceStudioRoleMappingColumnOption column;
  final bool selected;
  final bool assignedToSelectedRole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final statusColor = assignedToSelectedRole
        ? _accent
        : column.hasDuplicateAssignment
            ? _danger
            : column.isAssigned
                ? _accent
                : _warning;
    return GestureDetector(
      key: ValueKey('surface_role_column_card_${column.animationId}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.15)
              : EditorChrome.elevatedPanelBackground(context)
                  .withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _accent.withValues(alpha: 0.82)
                : statusColor.withValues(alpha: 0.35),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Col ${column.columnIndex}',
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _StatusPill(
                  label: column.hasDuplicateAssignment
                      ? 'Doublon'
                      : assignedToSelectedRole
                          ? 'Assigné au slot actif'
                          : column.isAssigned
                              ? 'Assignée'
                              : 'Non assignée',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 7),
            _ColumnMiniPreview(column: column),
            const SizedBox(height: 7),
            Text(
              column.animation.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${column.frameCount} frame(s) · ${column.atlasId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subtle, fontSize: 9.5, height: 1.2),
            ),
            if (column.assignedRoles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                column.assignedRoles
                    .map(surfaceStudioRoleMappingLabel)
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnMiniPreview extends StatelessWidget {
  const _ColumnMiniPreview({required this.column});

  final SurfaceStudioRoleMappingColumnOption column;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return Center(
      child: Container(
        key: ValueKey('surface_role_column_preview_${column.animationId}'),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accent.withValues(alpha: 0.42)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'C${column.columnIndex}',
              style: const TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                for (var i = 0; i < column.frameCount.clamp(1, 6); i++)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.30 + i * 0.07),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Frame 1',
              style: TextStyle(color: subtle, fontSize: 8.5, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceColumnCropPreview extends StatelessWidget {
  const _SurfaceColumnCropPreview({
    required this.image,
    required this.atlas,
    required this.column,
    required this.size,
    super.key,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingColumnOption column;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _SurfaceColumnCropPainter(
            image: image,
            atlas: atlas,
            column: column,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SurfaceColumnCropPainter extends CustomPainter {
  const _SurfaceColumnCropPainter({
    required this.image,
    required this.atlas,
    required this.column,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingColumnOption column;

  @override
  void paint(Canvas canvas, Size size) {
    final tileWidth = atlas.geometry.tileSize.width.toDouble();
    final tileHeight = atlas.geometry.tileSize.height.toDouble();
    final source = Rect.fromLTWH(
      column.columnIndex * tileWidth,
      column.rowIndex * tileHeight,
      tileWidth,
      tileHeight,
    );
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = _accent.withValues(alpha: 0.85)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SurfaceColumnCropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.atlas != atlas ||
        oldDelegate.column != column;
  }
}

class _RoleDetail extends StatelessWidget {
  const _RoleDetail({
    required this.preset,
    required this.selectedRole,
    required this.selectedColumn,
    required this.currentColumn,
    required this.atlasImage,
    required this.atlas,
    required this.canAssign,
    this.onAssign,
  });

  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final SurfaceStudioRoleMappingColumnOption? selectedColumn;
  final SurfaceStudioRoleMappingColumnOption? currentColumn;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final bool canAssign;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final selected = selectedColumn;
    final current = currentColumn;
    return _Panellet(
      key: const ValueKey('surface_role_detail_panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détail du rôle',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _roleExplanation(selectedRole),
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          SurfaceStudioRoleMappingPreview(
            preset: preset,
            selectedRole: selectedRole,
            onRoleSelected: (_) {},
          ),
          if (current != null && atlasImage != null && atlas != null) ...[
            const SizedBox(height: 10),
            Center(
              child: _SurfaceColumnCropPreview(
                key: const ValueKey('surface_selected_role_real_crop'),
                image: atlasImage!,
                atlas: atlas!,
                column: current,
                size: 72,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _DetailLine(
            label: 'Animation actuelle du rôle',
            value: current == null
                ? 'Aucune colonne liée'
                : 'Col ${current.columnIndex} — ${current.animation.name}',
          ),
          _DetailLine(
            label: 'Colonne sélectionnée',
            value: selected == null
                ? 'Aucune'
                : 'Col ${selected.columnIndex} — ${selected.animation.name}',
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            key: const ValueKey('surface_role_assign_column'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: _accent.withValues(alpha: 0.72),
            disabledColor:
                EditorChrome.islandFillElevated(context).withValues(alpha: 0.6),
            onPressed: canAssign ? onAssign : null,
            child: const Text('Assigner cette colonne au rôle'),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label : $value',
        style: TextStyle(
          color: labelColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.label, {this.color = _accent});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Panellet extends StatelessWidget {
  const _Panellet({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context)
            .withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: child,
    );
  }
}

({bool north, bool east, bool south, bool west}) _surfaceRoleConnections(
  SurfaceVariantRole role,
) {
  return switch (role) {
    SurfaceVariantRole.isolated => (
        north: false,
        east: false,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endNorth => (
        north: true,
        east: false,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endEast => (
        north: false,
        east: true,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endSouth => (
        north: false,
        east: false,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.endWest => (
        north: false,
        east: false,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.horizontal => (
        north: false,
        east: true,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.vertical => (
        north: true,
        east: false,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.cornerNE => (
        north: true,
        east: true,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.cornerSE => (
        north: false,
        east: true,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.cornerSW => (
        north: false,
        east: false,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.cornerNW => (
        north: true,
        east: false,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.innerCornerNE => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerSE => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerSW => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerNW => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.teeNorth => (
        north: true,
        east: true,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.teeEast => (
        north: true,
        east: true,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.teeSouth => (
        north: false,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.teeWest => (
        north: true,
        east: false,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.cross => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
  };
}

Offset? _surfaceInnerCornerAlignment(SurfaceVariantRole role) {
  return switch (role) {
    SurfaceVariantRole.innerCornerNE => const Offset(1, -1),
    SurfaceVariantRole.innerCornerSE => const Offset(1, 1),
    SurfaceVariantRole.innerCornerSW => const Offset(-1, 1),
    SurfaceVariantRole.innerCornerNW => const Offset(-1, -1),
    _ => null,
  };
}

String _roleExplanation(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'Plein : tuile utilisée pour une cellule seule ou un centre simple sans voisin compatible.';
    case SurfaceVariantRole.endNorth:
      return 'Bord haut : limite supérieure d’une zone de surface.';
    case SurfaceVariantRole.endEast:
      return 'Bord droit : limite droite d’une zone de surface.';
    case SurfaceVariantRole.endSouth:
      return 'Bord bas : limite inférieure d’une zone de surface.';
    case SurfaceVariantRole.endWest:
      return 'Bord gauche : limite gauche d’une zone de surface.';
    case SurfaceVariantRole.horizontal:
      return 'Horizontal : segment qui continue vers la gauche et la droite.';
    case SurfaceVariantRole.vertical:
      return 'Vertical : segment qui continue vers le haut et le bas.';
    case SurfaceVariantRole.cornerNE:
      return 'Coin haut droit : angle extérieur supérieur droit.';
    case SurfaceVariantRole.cornerSE:
      return 'Coin bas droit : angle extérieur inférieur droit.';
    case SurfaceVariantRole.cornerSW:
      return 'Coin bas gauche : angle extérieur inférieur gauche.';
    case SurfaceVariantRole.cornerNW:
      return 'Coin haut gauche : angle extérieur supérieur gauche.';
    case SurfaceVariantRole.innerCornerNE:
      return 'Coin intérieur haut droit : creux interne orienté vers le haut droit.';
    case SurfaceVariantRole.innerCornerSE:
      return 'Coin intérieur bas droit : creux interne orienté vers le bas droit.';
    case SurfaceVariantRole.innerCornerSW:
      return 'Coin intérieur bas gauche : creux interne orienté vers le bas gauche.';
    case SurfaceVariantRole.innerCornerNW:
      return 'Coin intérieur haut gauche : creux interne orienté vers le haut gauche.';
    case SurfaceVariantRole.teeNorth:
      return 'Jonction T haut : branche qui rejoint gauche, droite et haut.';
    case SurfaceVariantRole.teeEast:
      return 'Jonction T droite : branche qui rejoint haut, bas et droite.';
    case SurfaceVariantRole.teeSouth:
      return 'Jonction T bas : branche qui rejoint gauche, droite et bas.';
    case SurfaceVariantRole.teeWest:
      return 'Jonction T gauche : branche qui rejoint haut, bas et gauche.';
    case SurfaceVariantRole.cross:
      return 'Croix : jonction centrale multi-branches ou centre d’une grande zone continue.';
  }
}
