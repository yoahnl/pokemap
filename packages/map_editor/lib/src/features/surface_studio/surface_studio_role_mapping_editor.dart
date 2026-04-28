import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show DropdownButton, DropdownMenuItem, Material, MaterialType;
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_role_mapping_preview.dart';

const Color _accent = Color(0xFF2DD4BF);
const Color _warning = Color(0xFFF59E0B);

class SurfaceStudioRoleMappingEditor extends StatefulWidget {
  const SurfaceStudioRoleMappingEditor({
    super.key,
    required this.catalog,
    required this.preset,
    this.onRoleAnimationChanged,
  });

  final ProjectSurfaceCatalog catalog;
  final ProjectSurfacePreset preset;
  final void Function(SurfaceVariantRole role, String animationId)?
      onRoleAnimationChanged;

  @override
  State<SurfaceStudioRoleMappingEditor> createState() =>
      _SurfaceStudioRoleMappingEditorState();
}

class _SurfaceStudioRoleMappingEditorState
    extends State<SurfaceStudioRoleMappingEditor> {
  SurfaceVariantRole _selectedRole = SurfaceVariantRole.cross;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final animations = widget.catalog.animations;

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
            'Si le rendu utilise les mauvaises parties de l’atlas, corrigez quelle animation correspond à chaque rôle de surface.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          SurfaceStudioRoleMappingPreview(
            preset: widget.preset,
            selectedRole: _selectedRole,
            onRoleSelected: (role) => setState(() => _selectedRole = role),
          ),
          const SizedBox(height: 10),
          if (animations.isEmpty)
            _NoAnimationsState(subtle: subtle, label: label)
          else
            ...standardSurfaceVariantRoleOrder.map(
              (role) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RoleMappingRow(
                  role: role,
                  selected: role == _selectedRole,
                  preset: widget.preset,
                  animations: animations,
                  onSelected: () => setState(() => _selectedRole = role),
                  onAnimationChanged: widget.onRoleAnimationChanged == null
                      ? null
                      : (animationId) {
                          setState(() => _selectedRole = role);
                          widget.onRoleAnimationChanged!(role, animationId);
                        },
                ),
              ),
            ),
        ],
      ),
    );
  }
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

class _RoleMappingRow extends StatelessWidget {
  const _RoleMappingRow({
    required this.role,
    required this.selected,
    required this.preset,
    required this.animations,
    required this.onSelected,
    this.onAnimationChanged,
  });

  final SurfaceVariantRole role;
  final bool selected;
  final ProjectSurfacePreset preset;
  final List<ProjectSurfaceAnimation> animations;
  final VoidCallback onSelected;
  final ValueChanged<String>? onAnimationChanged;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final currentAnimationId = preset.animationIdForRole(role);
    final currentAnimation = currentAnimationId == null
        ? null
        : animations.where((animation) => animation.id == currentAnimationId);
    final hasCurrentAnimation =
        currentAnimation != null && currentAnimation.isNotEmpty;
    final dropdownValue = hasCurrentAnimation ? currentAnimationId : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.12)
              : EditorChrome.elevatedPanelBackground(context)
                  .withValues(alpha: 0.54),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _accent.withValues(alpha: 0.72)
                : EditorChrome.editorIslandRim(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    surfaceStudioRoleMappingLabel(role),
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  currentAnimationId == null
                      ? 'Animation manquante'
                      : 'Animation liée',
                  style: TextStyle(
                    color: currentAnimationId == null ? _warning : _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (currentAnimationId != null) ...[
              const SizedBox(height: 3),
              Text(
                currentAnimationId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: EditorChrome.islandFillElevated(context)
                    .withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  type: MaterialType.transparency,
                  child: DropdownButton<String>(
                    key: ValueKey('surface_role_mapping_dropdown_${role.name}'),
                    value: dropdownValue,
                    hint: const Text('Choisir une animation'),
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final animation in animations)
                        DropdownMenuItem(
                          value: animation.id,
                          child: Text(
                            _animationOptionLabel(animation),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: onAnimationChanged == null
                        ? null
                        : (value) {
                            if (value != null) {
                              onAnimationChanged!(value);
                            }
                          },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _animationOptionLabel(ProjectSurfaceAnimation animation) {
  final atlasIds = <String>{};
  for (final frame in animation.timeline.frames) {
    atlasIds.add(frame.tileRef.atlasId);
  }
  final atlasLabel =
      atlasIds.isEmpty ? 'atlas non renseigné' : 'atlas ${atlasIds.join(', ')}';
  return '${animation.name} — ${animation.frameCount} frame(s) · $atlasLabel';
}
