import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show BoxDecoration, CustomPaint, InkWell;
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../surface_studio_mapping_suggestion_models.dart';
import '../surface_studio_vertical_atlas_role_mapping.dart';
import 'tiled_tsx_animation_browser_models.dart';

const Color _tsxRoleAccent = Color(0xFF2DD4BF);

enum TiledTsxRoleAssignmentSource {
  manual,
  mistral,
}

final class TiledTsxRoleAssignmentMeta {
  const TiledTsxRoleAssignmentMeta({
    required this.source,
    this.confidence,
  });

  final TiledTsxRoleAssignmentSource source;
  final SurfaceStudioMappingSuggestionConfidence? confidence;
}

class TiledTsxRoleMappingBuilder extends StatefulWidget {
  const TiledTsxRoleMappingBuilder({
    super.key,
    required this.atlas,
    required this.animations,
    required this.selectedAnimationIds,
    required this.roleAnimationIds,
    required this.roleSources,
    required this.onChanged,
    this.atlasImageBytes,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Set<String> selectedAnimationIds;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
  final Uint8List? atlasImageBytes;
  final ValueChanged<Map<SurfaceVariantRole, String>> onChanged;

  @override
  State<TiledTsxRoleMappingBuilder> createState() =>
      _TiledTsxRoleMappingBuilderState();
}

class _TiledTsxRoleMappingBuilderState
    extends State<TiledTsxRoleMappingBuilder> {
  final TextEditingController _query = TextEditingController();
  SurfaceVariantRole? _pickerRole;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final selectedAnimations = _selectedAnimations();
    final usedIds = widget.roleAnimationIds.values
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final remainingCount =
        widget.selectedAnimationIds.where((id) => !usedIds.contains(id)).length;
    return Container(
      key: const ValueKey('tiled_tsx_role_mapping_builder.root'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mapping visuel rôle → animation',
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choisissez une animation visuellement pour chaque rôle. Aucun ID n’a besoin d’être saisi à la main.',
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SummaryPill(
                  'Animations sélectionnées : ${widget.selectedAnimationIds.length}',
                ),
                _SummaryPill('Utilisées : ${usedIds.length}'),
                _SummaryPill('Restantes : $remainingCount'),
              ],
            ),
            const SizedBox(height: 10),
            _SurfacePreviewSummary(
              roleAnimationIds: widget.roleAnimationIds,
            ),
            if (_pickerRole != null) ...[
              const SizedBox(height: 8),
              _AnimationPicker(
                role: _pickerRole!,
                animations: selectedAnimations,
                query: _query,
                atlas: widget.atlas,
                atlasImageBytes: widget.atlasImageBytes,
                onQueryChanged: () => setState(() {}),
                onCancel: () => setState(() => _pickerRole = null),
                onSelected: (animationId) =>
                    _assignRole(_pickerRole!, animationId),
              ),
            ],
            const SizedBox(height: 12),
            for (final group in _roleGroups) ...[
              _RoleGroupHeader(title: group.title),
              const SizedBox(height: 6),
              for (final role in group.roles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RoleMappingSlot(
                    role: role,
                    animation: _animationForRole(role),
                    animationItem: _itemForRole(role),
                    source: widget.roleSources[role],
                    atlas: widget.atlas,
                    atlasImageBytes: widget.atlasImageBytes,
                    onPick: () {
                      setState(() {
                        _pickerRole = role;
                        _query.clear();
                      });
                    },
                    onClear: widget.roleAnimationIds.containsKey(role)
                        ? () => _clearRole(role)
                        : null,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<ProjectSurfaceAnimation> _selectedAnimations() {
    return widget.animations
        .where(
            (animation) => widget.selectedAnimationIds.contains(animation.id))
        .toList(growable: false);
  }

  ProjectSurfaceAnimation? _animationForRole(SurfaceVariantRole role) {
    final id = widget.roleAnimationIds[role];
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

  TiledTsxAnimationBrowserItem? _itemForRole(SurfaceVariantRole role) {
    final animation = _animationForRole(role);
    if (animation == null) {
      return null;
    }
    return buildTiledTsxAnimationBrowserItems(animations: [animation]).single;
  }

  void _assignRole(SurfaceVariantRole role, String animationId) {
    final next = Map<SurfaceVariantRole, String>.of(widget.roleAnimationIds);
    next[role] = animationId;
    widget.onChanged(Map<SurfaceVariantRole, String>.unmodifiable(next));
    setState(() => _pickerRole = null);
  }

  void _clearRole(SurfaceVariantRole role) {
    final next = Map<SurfaceVariantRole, String>.of(widget.roleAnimationIds)
      ..remove(role);
    widget.onChanged(Map<SurfaceVariantRole, String>.unmodifiable(next));
  }
}

class _SurfacePreviewSummary extends StatelessWidget {
  const _SurfacePreviewSummary({required this.roleAnimationIds});

  final Map<SurfaceVariantRole, String> roleAnimationIds;

  @override
  Widget build(BuildContext context) {
    final hasCenter = roleAnimationIds.containsKey(SurfaceVariantRole.isolated);
    final mappedCount = roleAnimationIds.length;
    final missingCount = standardSurfaceVariantRoleOrder.length - mappedCount;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasCenter
            ? _tsxRoleAccent.withValues(alpha: 0.10)
            : const Color(0xFFFACC15).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasCenter
              ? _tsxRoleAccent.withValues(alpha: 0.30)
              : const Color(0xFFFACC15).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        hasCenter
            ? 'Aperçu de la surface : preview partielle active. $mappedCount rôles utilisés, $missingCount rôles encore vides.'
            : 'Aperçu de la surface : Plein(center) obligatoire.',
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AnimationPicker extends StatelessWidget {
  const _AnimationPicker({
    required this.role,
    required this.animations,
    required this.query,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onQueryChanged,
    required this.onCancel,
    required this.onSelected,
  });

  final SurfaceVariantRole role;
  final List<ProjectSurfaceAnimation> animations;
  final TextEditingController query;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onQueryChanged;
  final VoidCallback onCancel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final roleLabel = _labelForRole(role);
    final q = query.text.trim().toLowerCase();
    final visible = animations.where((animation) {
      if (q.isEmpty) {
        return true;
      }
      return animation.id.toLowerCase().contains(q) ||
          animation.name.toLowerCase().contains(q);
    }).toList(growable: false);
    return Container(
      key: ValueKey('tiled_tsx_role_mapping_builder.picker.${role.name}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tsxRoleAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choisir une animation pour $roleLabel',
                  style: TextStyle(
                    color: label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                onPressed: onCancel,
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    color: _tsxRoleAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            key: ValueKey('tiled_tsx_role_mapping_builder.search.${role.name}'),
            controller: query,
            placeholder: 'Rechercher une animation…',
            onChanged: (_) => onQueryChanged(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EditorChrome.editorIslandRim(context)
                    .withValues(alpha: 0.7),
              ),
            ),
            style: TextStyle(color: label, fontSize: 12),
            placeholderStyle: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Text(
              'Aucune animation sélectionnée ne correspond.',
              style: TextStyle(color: subtle, fontSize: 11.5),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final animation in visible)
                      _AnimationPickerOption(
                        role: role,
                        animation: animation,
                        atlas: atlas,
                        atlasImageBytes: atlasImageBytes,
                        onSelected: () => onSelected(animation.id),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimationPickerOption extends StatelessWidget {
  const _AnimationPickerOption({
    required this.role,
    required this.animation,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onSelected,
  });

  final SurfaceVariantRole role;
  final ProjectSurfaceAnimation animation;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final item =
        buildTiledTsxAnimationBrowserItems(animations: [animation]).single;
    final subtle = EditorChrome.subtleLabel(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        key: ValueKey(
          'tiled_tsx_role_mapping_builder.option.${role.name}.${animation.id}',
        ),
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: TiledTsxAnimationTilePreview(
                  atlas: atlas,
                  animation: animation,
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
                      animation.id,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_frameCountLabel(animation)} · base tile ${item.baseTileId}',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleMappingSlot extends StatelessWidget {
  const _RoleMappingSlot({
    required this.role,
    required this.animation,
    required this.animationItem,
    required this.source,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onPick,
    required this.onClear,
  });

  final SurfaceVariantRole role;
  final ProjectSurfaceAnimation? animation;
  final TiledTsxAnimationBrowserItem? animationItem;
  final TiledTsxRoleAssignmentMeta? source;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final assigned = animation != null;
    return Container(
      key: ValueKey('tiled_tsx_role_mapping_builder.slot.${role.name}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: assigned
              ? _tsxRoleAccent.withValues(alpha: 0.34)
              : EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForRole(role),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtle, fontSize: 10.5),
                ),
                const SizedBox(height: 4),
                Text(
                  _descriptionForRole(role),
                  style: TextStyle(color: subtle, fontSize: 10.8, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            height: 66,
            child: animation == null
                ? const _EmptyPreviewBox()
                : TiledTsxAnimationTilePreview(
                    atlas: atlas,
                    animation: animation!,
                    atlasImageBytes: atlasImageBytes,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animation?.id ?? 'Non assigné',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: assigned ? label : subtle,
                    fontSize: 12,
                    fontWeight: assigned ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                if (animation != null)
                  Text(
                    '${_frameCountLabel(animation!)} · ${animation!.totalDurationMs} ms',
                    style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
                  ),
                if (animation != null)
                  Text(
                    'base tile ${animationItem?.baseTileId ?? '—'}',
                    style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
                  ),
                if (source != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    source!.source == TiledTsxRoleAssignmentSource.mistral
                        ? 'Source : Mistral'
                        : 'Source : Manuel',
                    style: const TextStyle(
                      color: _tsxRoleAccent,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (source!.confidence != null)
                    Text(
                      'Confiance : ${source!.confidence!.name}',
                      style: const TextStyle(
                        color: _tsxRoleAccent,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    CupertinoButton(
                      key: ValueKey(
                        'tiled_tsx_role_mapping_builder.pick.${role.name}',
                      ),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      onPressed: onPick,
                      child: Text(
                        assigned ? 'Changer' : 'Choisir une animation',
                        style: const TextStyle(
                          color: _tsxRoleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (assigned)
                      CupertinoButton(
                        key: ValueKey(
                          'tiled_tsx_role_mapping_builder.clear.${role.name}',
                        ),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        onPressed: onClear,
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: _tsxRoleAccent,
                            fontSize: 11,
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

class TiledTsxAnimationTilePreview extends StatefulWidget {
  const TiledTsxAnimationTilePreview({
    super.key,
    required this.atlas,
    required this.animation,
    this.atlasImageBytes,
    this.compact = false,
  });

  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation animation;
  final Uint8List? atlasImageBytes;
  final bool compact;

  @override
  State<TiledTsxAnimationTilePreview> createState() =>
      _TiledTsxAnimationTilePreviewState();
}

class _TiledTsxAnimationTilePreviewState
    extends State<TiledTsxAnimationTilePreview> {
  ui.Image? _decoded;
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant TiledTsxAnimationTilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.atlasImageBytes != oldWidget.atlasImageBytes) {
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _decoded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atlas = widget.atlas;
    final decoded = _decoded;
    final frames = widget.animation.timeline.frames;
    if (atlas == null ||
        decoded == null ||
        widget.atlasImageBytes == null ||
        frames.isEmpty) {
      return const _FallbackPreviewBox(text: 'Aperçu indisponible');
    }
    final frame = frames.first;
    final tileWidth = atlas.geometry.tileSize.width;
    final tileHeight = atlas.geometry.tileSize.height;
    final source = Rect.fromLTWH(
      (frame.tileRef.column * tileWidth).toDouble(),
      (frame.tileRef.row * tileHeight).toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: _TilePreviewPainter(image: decoded, source: source),
        child: const SizedBox.expand(),
      ),
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
}

class _TilePreviewPainter extends CustomPainter {
  const _TilePreviewPainter({
    required this.image,
    required this.source,
  });

  final ui.Image image;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    final destination = Offset.zero & size;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    canvas.drawImageRect(image, source, destination, paint);
  }

  @override
  bool shouldRepaint(covariant _TilePreviewPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.source != source;
  }
}

class _EmptyPreviewBox extends StatelessWidget {
  const _EmptyPreviewBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: const Center(
        child: Text(
          'Vide',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FallbackPreviewBox extends StatelessWidget {
  const _FallbackPreviewBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.8,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleGroupHeader extends StatelessWidget {
  const _RoleGroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tsxRoleAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _tsxRoleAccent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: _tsxRoleAccent,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

final class _RoleGroup {
  const _RoleGroup({
    required this.title,
    required this.roles,
  });

  final String title;
  final List<SurfaceVariantRole> roles;
}

const _roleGroups = <_RoleGroup>[
  _RoleGroup(
    title: 'Surface principale',
    roles: [
      SurfaceVariantRole.isolated,
      SurfaceVariantRole.horizontal,
      SurfaceVariantRole.vertical,
    ],
  ),
  _RoleGroup(
    title: 'Bords',
    roles: [
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
    ],
  ),
  _RoleGroup(
    title: 'Coins externes',
    roles: [
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ],
  ),
  _RoleGroup(
    title: 'Coins internes',
    roles: [
      SurfaceVariantRole.innerCornerNW,
      SurfaceVariantRole.innerCornerNE,
      SurfaceVariantRole.innerCornerSW,
      SurfaceVariantRole.innerCornerSE,
    ],
  ),
  _RoleGroup(
    title: 'Jonctions',
    roles: [
      SurfaceVariantRole.teeNorth,
      SurfaceVariantRole.teeEast,
      SurfaceVariantRole.teeSouth,
      SurfaceVariantRole.teeWest,
      SurfaceVariantRole.cross,
    ],
  ),
];

String _labelForRole(SurfaceVariantRole role) {
  if (role == SurfaceVariantRole.isolated) {
    return 'Plein(center)';
  }
  return SurfaceStudioRoleLabels.labelForRole(role);
}

String _descriptionForRole(SurfaceVariantRole role) {
  return switch (role) {
    SurfaceVariantRole.isolated => 'Surface intérieure répétable.',
    SurfaceVariantRole.horizontal => 'Transition horizontale.',
    SurfaceVariantRole.vertical => 'Transition verticale.',
    SurfaceVariantRole.endNorth => 'Bord supérieur d’une surface.',
    SurfaceVariantRole.endEast => 'Bord droit d’une surface.',
    SurfaceVariantRole.endSouth => 'Bord inférieur d’une surface.',
    SurfaceVariantRole.endWest => 'Bord gauche d’une surface.',
    SurfaceVariantRole.cornerNW => 'Coin externe haut gauche.',
    SurfaceVariantRole.cornerNE => 'Coin externe haut droit.',
    SurfaceVariantRole.cornerSW => 'Coin externe bas gauche.',
    SurfaceVariantRole.cornerSE => 'Coin externe bas droit.',
    SurfaceVariantRole.innerCornerNW => 'Coin intérieur haut gauche.',
    SurfaceVariantRole.innerCornerNE => 'Coin intérieur haut droit.',
    SurfaceVariantRole.innerCornerSW => 'Coin intérieur bas gauche.',
    SurfaceVariantRole.innerCornerSE => 'Coin intérieur bas droit.',
    SurfaceVariantRole.teeNorth => 'Jonction en T vers le haut.',
    SurfaceVariantRole.teeEast => 'Jonction en T vers la droite.',
    SurfaceVariantRole.teeSouth => 'Jonction en T vers le bas.',
    SurfaceVariantRole.teeWest => 'Jonction en T vers la gauche.',
    SurfaceVariantRole.cross => 'Jonction en croix.',
  };
}

String _frameCountLabel(ProjectSurfaceAnimation animation) {
  final count = animation.frameCount;
  return count == 1 ? '1 frame' : '$count frames';
}
