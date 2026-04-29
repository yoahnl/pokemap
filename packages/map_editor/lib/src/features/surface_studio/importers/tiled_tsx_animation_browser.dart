import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../surface_studio_vertical_atlas_preset_generator.dart';
import '../surface_studio_vertical_atlas_role_mapping.dart';
import 'tiled_tsx_animation_browser_models.dart';
import 'tiled_tsx_surface_preset_draft.dart';

const Color _tsxAccent = Color(0xFF2DD4BF);

class TiledTsxAnimationBrowser extends StatefulWidget {
  const TiledTsxAnimationBrowser({
    super.key,
    required this.atlas,
    required this.animations,
    this.atlasImageBytes,
    this.sourceLabel = 'TSX',
    this.onSelectionChanged,
    this.catalog,
    this.onSurfaceCatalogChanged,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final String sourceLabel;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ProjectSurfaceCatalog? catalog;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;

  @override
  State<TiledTsxAnimationBrowser> createState() =>
      _TiledTsxAnimationBrowserState();
}

class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
  final TextEditingController _query = TextEditingController();
  final TextEditingController _presetId = TextEditingController();
  final TextEditingController _presetName = TextEditingController();
  final TextEditingController _presetCategory = TextEditingController();
  final TextEditingController _presetSortOrder = TextEditingController();
  final Map<SurfaceVariantRole, TextEditingController> _roleControllers = {
    for (final role in standardSurfaceVariantRoleOrder)
      role: TextEditingController(),
  };
  Set<String> _selectedIds = const <String>{};
  String? _activeAnimationId;
  bool _onlySelected = false;
  bool _presetBuilderOpen = false;
  List<String> _presetBuilderErrors = const <String>[];
  List<String> _presetBuilderWarnings = const <String>[];
  String? _presetBuilderNote;

  @override
  void initState() {
    super.initState();
    _activeAnimationId =
        widget.animations.isEmpty ? null : widget.animations.first.id;
    _resetPresetDefaults();
  }

  @override
  void didUpdateWidget(covariant TiledTsxAnimationBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animations != oldWidget.animations) {
      final validIds =
          widget.animations.map((animation) => animation.id).toSet();
      final nextSelection =
          _selectedIds.where((id) => validIds.contains(id)).toSet();
      final activeStillValid =
          _activeAnimationId != null && validIds.contains(_activeAnimationId);
      setState(() {
        _selectedIds = nextSelection;
        _activeAnimationId = activeStillValid
            ? _activeAnimationId
            : widget.animations.isEmpty
                ? null
                : widget.animations.first.id;
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _presetId.dispose();
    _presetName.dispose();
    _presetCategory.dispose();
    _presetSortOrder.dispose();
    for (final controller in _roleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final items = buildTiledTsxAnimationBrowserItems(
      animations: widget.animations,
    );
    final visible = filterTiledTsxAnimationBrowserItems(
      items: items,
      filter: TiledTsxAnimationBrowserFilter(
        query: _query.text,
        onlySelected: _onlySelected,
      ),
      selectedAnimationIds: _selectedIds,
    );
    final active = _activeAnimation();
    final atlas = widget.atlas;
    final canCreateSurfaceFromSelection =
        _selectedIds.isNotEmpty && widget.onSurfaceCatalogChanged != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? (constraints.maxHeight - 210).clamp(220.0, 520.0).toDouble()
                : 440.0;
        final animationBody = LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 760;
            final list = _AnimationList(
              items: visible,
              selectedIds: _selectedIds,
              activeAnimationId: _activeAnimationId,
              onToggleSelection: _toggleSelection,
              onActivate: _activateAnimation,
            );
            final preview = active == null
                ? _EmptyPreview(subtle: subtle)
                : TiledTsxSurfaceAnimationPreview(
                    atlas: atlas,
                    animation: active,
                    atlasImageBytes: widget.atlasImageBytes,
                  );
            if (!twoColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: list),
                  const SizedBox(height: 12),
                  SizedBox(height: 260, child: preview),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: list),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: preview),
              ],
            );
          },
        );
        return Container(
          key: const ValueKey('tiled_tsx_animation_browser.root'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EditorChrome.elevatedPanelBackground(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EditorChrome.editorIslandRim(context)),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Animations TSX importées',
                  style: TextStyle(
                    color: label,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Animations lues depuis le fichier TSX. Les frames et durées viennent du fichier Tiled.',
                  style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill('${items.length} animations'),
                    _MetricPill(atlas == null ? '0 atlas' : '1 atlas'),
                    if (atlas != null)
                      _MetricPill(
                        '${atlas.geometry.tileSize.width}×${atlas.geometry.tileSize.height}',
                      ),
                    _MetricPill(widget.sourceLabel),
                  ],
                ),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, toolbarConstraints) {
                    final selectionText = Text(
                      _selectionLabel(_selectedIds.length),
                      style: TextStyle(
                        color: label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                    final actions = Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: [
                        CupertinoButton(
                          key: const ValueKey(
                              'tiled_tsx_animation_browser.create_surface'),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          onPressed: canCreateSurfaceFromSelection
                              ? _openPresetBuilder
                              : null,
                          child: Text(
                            'Créer une surface depuis la sélection',
                            style: TextStyle(
                              color: canCreateSurfaceFromSelection
                                  ? _tsxAccent
                                  : subtle,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          key: const ValueKey(
                              'tiled_tsx_animation_browser.only_selected'),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          onPressed: () {
                            setState(() {
                              _onlySelected = !_onlySelected;
                            });
                          },
                          child: Text(
                            _onlySelected
                                ? 'Tout afficher'
                                : 'Sélection seulement',
                            style: const TextStyle(
                              color: _tsxAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          key: const ValueKey(
                              'tiled_tsx_animation_browser.clear_selection'),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          onPressed:
                              _selectedIds.isEmpty ? null : _clearSelection,
                          child: Text(
                            'Vider',
                            style: TextStyle(
                              color: _selectedIds.isEmpty ? subtle : _tsxAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    );
                    if (toolbarConstraints.maxWidth < 700) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          selectionText,
                          const SizedBox(height: 4),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: selectionText),
                        actions,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (_presetBuilderOpen) ...[
                  _TiledTsxSurfacePresetBuilderPanel(
                    selectedAnimationIds: _selectedIds,
                    idController: _presetId,
                    nameController: _presetName,
                    categoryController: _presetCategory,
                    sortOrderController: _presetSortOrder,
                    roleControllers: _roleControllers,
                    errors: _presetBuilderErrors,
                    warnings: _presetBuilderWarnings,
                    note: _presetBuilderNote,
                    onCreate: _createPresetFromBuilder,
                    onClose: () {
                      setState(() {
                        _presetBuilderOpen = false;
                        _presetBuilderErrors = const <String>[];
                        _presetBuilderWarnings = const <String>[];
                        _presetBuilderNote = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                if (!_presetBuilderOpen)
                  SizedBox(height: bodyHeight, child: animationBody),
              ],
            ),
          ),
        );
      },
    );
  }

  ProjectSurfaceAnimation? _activeAnimation() {
    final id = _activeAnimationId;
    if (id == null) {
      return null;
    }
    for (final animation in widget.animations) {
      if (animation.id == id) {
        return animation;
      }
    }
    return null;
  }

  void _activateAnimation(String id) {
    setState(() {
      _activeAnimationId = id;
    });
  }

  void _toggleSelection(String id) {
    final next = Set<String>.of(_selectedIds);
    if (!next.add(id)) {
      next.remove(id);
    }
    setState(() {
      _selectedIds = next;
      _activeAnimationId = id;
    });
    widget.onSelectionChanged?.call(Set<String>.unmodifiable(next));
  }

  void _clearSelection() {
    setState(() {
      _selectedIds = const <String>{};
      _onlySelected = false;
      _presetBuilderOpen = false;
    });
    widget.onSelectionChanged?.call(const <String>{});
  }

  ProjectSurfaceCatalog _effectiveCatalog() {
    final provided = widget.catalog;
    if (provided != null) {
      return provided;
    }
    return ProjectSurfaceCatalog(
      atlases: widget.atlas == null
          ? const <ProjectSurfaceAtlas>[]
          : <ProjectSurfaceAtlas>[widget.atlas!],
      animations: widget.animations,
    );
  }

  void _resetPresetDefaults() {
    final catalog = _effectiveCatalog();
    _presetId.text = 'tsx-surface-${catalog.presetCount}';
    _presetName.text = 'Surface TSX';
    _presetCategory.text = '';
    _presetSortOrder.text = '${catalog.presetCount}';
    for (final controller in _roleControllers.values) {
      controller.text = '';
    }
  }

  void _openPresetBuilder() {
    setState(() {
      _presetBuilderOpen = true;
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = const <String>[];
      _presetBuilderNote = null;
    });
  }

  void _createPresetFromBuilder() {
    final sortOrder = int.tryParse(_presetSortOrder.text.trim());
    if (sortOrder == null) {
      setState(() {
        _presetBuilderErrors = const <String>['Ordre invalide.'];
        _presetBuilderWarnings = const <String>[];
        _presetBuilderNote = null;
      });
      return;
    }

    final roleAnimationIds = <SurfaceVariantRole, String>{
      for (final entry in _roleControllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };
    final nonSelected = <String>[];
    for (final entry in roleAnimationIds.entries) {
      if (!_selectedIds.contains(entry.value)) {
        nonSelected.add(
          'Animation non sélectionnée pour ${SurfaceStudioRoleLabels.labelForRole(entry.key)} : ${entry.value}.',
        );
      }
    }
    if (nonSelected.isNotEmpty) {
      setState(() {
        _presetBuilderErrors = List<String>.unmodifiable(nonSelected);
        _presetBuilderWarnings = const <String>[];
        _presetBuilderNote = null;
      });
      return;
    }

    final catalog = _effectiveCatalog();
    final draft = TiledTsxSurfacePresetDraft(
      id: _presetId.text,
      name: _presetName.text,
      categoryId: _presetCategory.text,
      sortOrder: sortOrder,
      roleAnimationIds: roleAnimationIds,
    );
    final validation = validateTiledTsxSurfacePresetDraft(
      draft: draft,
      catalog: catalog,
    );
    if (!validation.canCreate) {
      setState(() {
        _presetBuilderErrors = validation.errors;
        _presetBuilderWarnings = validation.warnings;
        _presetBuilderNote = null;
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
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = validation.warnings;
      _presetBuilderNote =
          'Preset ${preset.id} ajouté au catalogue de travail.';
    });
  }
}

class _TiledTsxSurfacePresetBuilderPanel extends StatelessWidget {
  const _TiledTsxSurfacePresetBuilderPanel({
    required this.selectedAnimationIds,
    required this.idController,
    required this.nameController,
    required this.categoryController,
    required this.sortOrderController,
    required this.roleControllers,
    required this.errors,
    required this.warnings,
    required this.note,
    required this.onCreate,
    required this.onClose,
  });

  final Set<String> selectedAnimationIds;
  final TextEditingController idController;
  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController sortOrderController;
  final Map<SurfaceVariantRole, TextEditingController> roleControllers;
  final List<String> errors;
  final List<String> warnings;
  final String? note;
  final VoidCallback onCreate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('tiled_tsx_surface_preset_builder.panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 310),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Créer une surface depuis animations TSX',
                      style: TextStyle(
                        color: label,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CupertinoButton.filled(
                    key: const ValueKey(
                      'tiled_tsx_surface_preset_builder.create',
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed: onCreate,
                    child: const Text(
                      'Créer le preset',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    onPressed: onClose,
                    child: const Text(
                      'Masquer',
                      style: TextStyle(
                        color: _tsxAccent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Aucun rôle n’est deviné : associez explicitement chaque rôle à une animation sélectionnée.',
                style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
              ),
              const SizedBox(height: 8),
              Text(
                '${selectedAnimationIds.length} animations sélectionnées',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final id in selectedAnimationIds)
                    _SelectedAnimationPill(id: id),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.id',
                    label: 'Identifiant surface',
                    controller: idController,
                    width: 210,
                  ),
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.name',
                    label: 'Nom surface',
                    controller: nameController,
                    width: 210,
                  ),
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.category',
                    label: 'Catégorie',
                    controller: categoryController,
                    width: 170,
                  ),
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.sort_order',
                    label: 'Ordre',
                    controller: sortOrderController,
                    width: 96,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mapping rôles → animations',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              for (final role in standardSurfaceVariantRoleOrder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RoleAnimationField(
                    role: role,
                    controller: roleControllers[role]!,
                  ),
                ),
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final error in errors)
                  _StatusLine(text: error, color: const Color(0xFFF87171)),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final warning in warnings)
                  _StatusLine(text: warning, color: const Color(0xFFFACC15)),
              ],
              if (note != null) ...[
                const SizedBox(height: 4),
                _StatusLine(text: note!, color: _tsxAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedAnimationPill extends StatelessWidget {
  const _SelectedAnimationPill({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tsxAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _tsxAccent.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          id,
          style: const TextStyle(
            color: _tsxAccent,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BuilderTextField extends StatelessWidget {
  const _BuilderTextField({
    required this.keyName,
    required this.label,
    required this.controller,
    required this.width,
  });

  final String keyName;
  final String label;
  final TextEditingController controller;
  final double width;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: ValueKey(keyName),
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RoleAnimationField extends StatelessWidget {
  const _RoleAnimationField({
    required this.role,
    required this.controller,
  });

  final SurfaceVariantRole role;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final roleLabel = role == SurfaceVariantRole.isolated
        ? 'Plein(center)'
        : SurfaceStudioRoleLabels.labelForRole(role);
    return Row(
      children: [
        SizedBox(
          width: 170,
          child: Text(
            roleLabel,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoTextField(
            key: ValueKey(
              'tiled_tsx_surface_preset_builder.role.${role.name}',
            ),
            controller: controller,
            placeholder: 'animation id sélectionnée',
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            style: const TextStyle(fontSize: 12),
            placeholderStyle: TextStyle(color: subtle, fontSize: 12),
          ),
        ),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          onPressed: () => controller.clear(),
          child: const Text(
            'Clear',
            style: TextStyle(
              color: _tsxAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class TiledTsxSurfaceAnimationPreview extends StatefulWidget {
  const TiledTsxSurfaceAnimationPreview({
    super.key,
    required this.atlas,
    required this.animation,
    this.atlasImageBytes,
  });

  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation animation;
  final Uint8List? atlasImageBytes;

  @override
  State<TiledTsxSurfaceAnimationPreview> createState() =>
      _TiledTsxSurfaceAnimationPreviewState();
}

class _TiledTsxSurfaceAnimationPreviewState
    extends State<TiledTsxSurfaceAnimationPreview> {
  int _frameIndex = 0;
  bool _playing = false;
  Timer? _timer;
  ui.Image? _decoded;
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant TiledTsxSurfaceAnimationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _timer?.cancel();
      _playing = false;
      _frameIndex = 0;
    } else if (_frameIndex >= widget.animation.frameCount) {
      _frameIndex = 0;
    }
    if (widget.atlasImageBytes != oldWidget.atlasImageBytes) {
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _decoded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final frames = widget.animation.timeline.frames;
    final frame = frames[_frameIndex.clamp(0, frames.length - 1).toInt()];
    return Container(
      key: const ValueKey('tiled_tsx_animation_preview.root'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.animation.id,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.animation.frameCount} frames · ${widget.animation.totalDurationMs} ms',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF101820),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: EditorChrome.editorIslandRim(context)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  child: _buildVisualPreview(frame),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Frame ${_frameIndex + 1} / ${frames.length}',
            key: const ValueKey('tiled_tsx_animation_preview.frame_label'),
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'column ${frame.tileRef.column}, row ${frame.tileRef.row}',
            style: TextStyle(color: label, fontSize: 11.5, height: 1.35),
          ),
          Text(
            '${frame.durationMs} ms',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PreviewButton(
                key: const ValueKey('tiled_tsx_animation_preview.previous'),
                label: 'Précédent',
                onPressed: _previousFrame,
              ),
              const SizedBox(width: 8),
              _PreviewButton(
                key: const ValueKey('tiled_tsx_animation_preview.next'),
                label: 'Suivant',
                onPressed: _nextFrame,
              ),
              const SizedBox(width: 8),
              _PreviewButton(
                key: const ValueKey('tiled_tsx_animation_preview.play_pause'),
                label: _playing ? 'Pause' : 'Play',
                onPressed: _togglePlay,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FrameStrip(
            frames: frames,
            selectedIndex: _frameIndex,
            onSelected: (index) => setState(() => _frameIndex = index),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPreview(SurfaceAnimationFrame frame) {
    final atlas = widget.atlas;
    final decoded = _decoded;
    if (widget.atlasImageBytes == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Image atlas indisponible — frames listées sans aperçu visuel.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA6B2),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ),
      );
    }
    if (atlas == null || decoded == null) {
      return const Center(
        child: Text(
          'Décodage de l’atlas…',
          style: TextStyle(color: Color(0xFF9AA6B2), fontSize: 11.5),
        ),
      );
    }
    final tileWidth = atlas.geometry.tileSize.width;
    final tileHeight = atlas.geometry.tileSize.height;
    final source = Rect.fromLTWH(
      (frame.tileRef.column * tileWidth).toDouble(),
      (frame.tileRef.row * tileHeight).toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
    return CustomPaint(
      painter: _TiledTsxFrameCropPainter(image: decoded, source: source),
      child: const SizedBox.expand(),
    );
  }

  void _decodeImage() {
    final bytes = widget.atlasImageBytes;
    if (bytes == null || bytes.isEmpty) {
      _decodedBytes = null;
      _decoded?.dispose();
      _decoded = null;
      return;
    }
    if (identical(bytes, _decodedBytes)) {
      return;
    }
    _decodedBytes = bytes;
    ui.decodeImageFromList(bytes, (image) {
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _decoded?.dispose();
        _decoded = image;
      });
    });
  }

  void _previousFrame() {
    setState(() {
      _playing = false;
      _timer?.cancel();
      _frameIndex = (_frameIndex - 1) % widget.animation.frameCount;
    });
  }

  void _nextFrame() {
    setState(() {
      _playing = false;
      _timer?.cancel();
      _frameIndex = (_frameIndex + 1) % widget.animation.frameCount;
    });
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(
        milliseconds: widget.animation.timeline.frames[_frameIndex].durationMs,
      ),
      (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _frameIndex = (_frameIndex + 1) % widget.animation.frameCount;
        });
      },
    );
  }
}

class _AnimationList extends StatelessWidget {
  const _AnimationList({
    required this.items,
    required this.selectedIds,
    required this.activeAnimationId,
    required this.onToggleSelection,
    required this.onActivate,
  });

  final List<TiledTsxAnimationBrowserItem> items;
  final Set<String> selectedIds;
  final String? activeAnimationId;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onActivate;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Aucune animation TSX ne correspond au filtre.',
          style: TextStyle(color: subtle, fontSize: 12),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _AnimationItemCard(
          item: item,
          selected: selectedIds.contains(item.animationId),
          active: activeAnimationId == item.animationId,
          onToggleSelection: () => onToggleSelection(item.animationId),
          onActivate: () => onActivate(item.animationId),
        );
      },
    );
  }
}

class _AnimationItemCard extends StatelessWidget {
  const _AnimationItemCard({
    required this.item,
    required this.selected,
    required this.active,
    required this.onToggleSelection,
    required this.onActivate,
  });

  final TiledTsxAnimationBrowserItem item;
  final bool selected;
  final bool active;
  final VoidCallback onToggleSelection;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final baseBg = EditorChrome.islandFillElevated(context);
    return GestureDetector(
      key: ValueKey('tiled_tsx_animation_browser.item.${item.animationId}'),
      behavior: HitTestBehavior.opaque,
      onTap: onActivate,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? Color.lerp(baseBg, _tsxAccent, 0.08)! : baseBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? Color.lerp(
                    EditorChrome.editorIslandRim(context),
                    _tsxAccent,
                    0.48,
                  )!
                : EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectionBox(
              key: ValueKey(
                'tiled_tsx_animation_browser.checkbox.${item.animationId}',
              ),
              selected: selected,
              onTap: onToggleSelection,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.animationId,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'base tile: ${item.baseTileId}',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11.2,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    '${item.frameCount} frames · ${item.durationTotalMs} ms',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11.2,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    'first frame: column ${item.firstFrameColumn}, row ${item.firstFrameRow}',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11.2,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      key: const ValueKey('tiled_tsx_animation_browser.search'),
      controller: controller,
      onChanged: onChanged,
      placeholder: 'Rechercher une animation, un id ou un tile id…',
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      style: TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 12.5,
      ),
      placeholderStyle: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 12.5,
      ),
    );
  }
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({
    super.key,
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _tsxAccent : const Color(0x00000000),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                selected ? _tsxAccent : EditorChrome.editorIslandRim(context),
          ),
        ),
        child: selected
            ? const Icon(
                CupertinoIcons.check_mark,
                color: Color(0xFF061A1A),
                size: 14,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _tsxAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _tsxAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      color: _tsxAccent.withValues(alpha: 0.16),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: _tsxAccent,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FrameStrip extends StatelessWidget {
  const _FrameStrip({
    required this.frames,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SurfaceAnimationFrame> frames;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: frames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final frame = frames[index];
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              width: 82,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: selected
                    ? _tsxAccent.withValues(alpha: 0.15)
                    : EditorChrome.islandFillElevated(context)
                        .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? _tsxAccent
                      : EditorChrome.editorIslandRim(context)
                          .withValues(alpha: 0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: selected ? _tsxAccent : subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'column ${frame.tileRef.column}, row ${frame.tileRef.row}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subtle, fontSize: 9.5, height: 1.1),
                  ),
                  Text(
                    '${frame.durationMs} ms',
                    style: TextStyle(color: subtle, fontSize: 9.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.subtle});

  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sélectionnez une animation TSX pour inspecter ses frames.',
        style: TextStyle(color: subtle, fontSize: 12),
      ),
    );
  }
}

class _TiledTsxFrameCropPainter extends CustomPainter {
  const _TiledTsxFrameCropPainter({
    required this.image,
    required this.source,
  });

  final ui.Image image;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _TiledTsxFrameCropPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.source != source;
  }
}

String _selectionLabel(int count) {
  if (count == 0) {
    return '0 animations sélectionnées';
  }
  if (count == 1) {
    return '1 animation sélectionnée';
  }
  return '$count animations sélectionnées';
}
