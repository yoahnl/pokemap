import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const Color _accent = Color(0xFF2DD4BF);
const Color _warning = Color(0xFFF59E0B);

String surfaceStudioRoleMappingLabel(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'Isolé';
    case SurfaceVariantRole.endNorth:
      return 'Bord haut';
    case SurfaceVariantRole.endEast:
      return 'Bord droite';
    case SurfaceVariantRole.endSouth:
      return 'Bord bas';
    case SurfaceVariantRole.endWest:
      return 'Bord gauche';
    case SurfaceVariantRole.horizontal:
      return 'Horizontal';
    case SurfaceVariantRole.vertical:
      return 'Vertical';
    case SurfaceVariantRole.cornerNE:
      return 'Coin haut droit';
    case SurfaceVariantRole.cornerSE:
      return 'Coin bas droit';
    case SurfaceVariantRole.cornerSW:
      return 'Coin bas gauche';
    case SurfaceVariantRole.cornerNW:
      return 'Coin haut gauche';
    case SurfaceVariantRole.innerCornerNE:
      return 'Coin intérieur haut droit';
    case SurfaceVariantRole.innerCornerSE:
      return 'Coin intérieur bas droit';
    case SurfaceVariantRole.innerCornerSW:
      return 'Coin intérieur bas gauche';
    case SurfaceVariantRole.innerCornerNW:
      return 'Coin intérieur haut gauche';
    case SurfaceVariantRole.teeNorth:
      return 'Jonction T haut';
    case SurfaceVariantRole.teeEast:
      return 'Jonction T droite';
    case SurfaceVariantRole.teeSouth:
      return 'Jonction T bas';
    case SurfaceVariantRole.teeWest:
      return 'Jonction T gauche';
    case SurfaceVariantRole.cross:
      return 'Centre / plein';
  }
}

class SurfaceStudioRoleMappingPreview extends StatelessWidget {
  const SurfaceStudioRoleMappingPreview({
    super.key,
    required this.preset,
    this.selectedRole,
    this.onRoleSelected,
  });

  final ProjectSurfacePreset preset;
  final SurfaceVariantRole? selectedRole;
  final ValueChanged<SurfaceVariantRole>? onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('surface_role_mapping_preview'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mapping visuel',
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cette grille aide à relier chaque rôle à l’animation qui dessine la bonne partie de l’atlas.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(
                children: [
                  _PreviewCell(
                    role: SurfaceVariantRole.cornerNW,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.cornerNW,
                    onTap: onRoleSelected,
                  ),
                  const SizedBox(width: 6),
                  _PreviewCell(
                    role: SurfaceVariantRole.endNorth,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.endNorth,
                    onTap: onRoleSelected,
                  ),
                  const SizedBox(width: 6),
                  _PreviewCell(
                    role: SurfaceVariantRole.cornerNE,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.cornerNE,
                    onTap: onRoleSelected,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _PreviewCell(
                    role: SurfaceVariantRole.endWest,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.endWest,
                    onTap: onRoleSelected,
                  ),
                  const SizedBox(width: 6),
                  _PreviewCell(
                    role: SurfaceVariantRole.cross,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.cross,
                    onTap: onRoleSelected,
                  ),
                  const SizedBox(width: 6),
                  _PreviewCell(
                    role: SurfaceVariantRole.endEast,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.endEast,
                    onTap: onRoleSelected,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _PreviewCell(
                    role: SurfaceVariantRole.cornerSW,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.cornerSW,
                    onTap: onRoleSelected,
                  ),
                  const SizedBox(width: 6),
                  _PreviewCell(
                    role: SurfaceVariantRole.endSouth,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.endSouth,
                    onTap: onRoleSelected,
                  ),
                  const SizedBox(width: 6),
                  _PreviewCell(
                    role: SurfaceVariantRole.cornerSE,
                    preset: preset,
                    selected: selectedRole == SurfaceVariantRole.cornerSE,
                    onTap: onRoleSelected,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rôles avancés : horizontal, vertical, jonctions T, coins intérieurs et isolé restent modifiables dans la liste.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PreviewCell extends StatelessWidget {
  const _PreviewCell({
    required this.role,
    required this.preset,
    required this.selected,
    this.onTap,
  });

  final SurfaceVariantRole role;
  final ProjectSurfacePreset preset;
  final bool selected;
  final ValueChanged<SurfaceVariantRole>? onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final linked = preset.containsRole(role);
    final box = Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(role),
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.18)
                : EditorChrome.elevatedPanelBackground(context)
                    .withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _accent.withValues(alpha: 0.85)
                  : EditorChrome.editorIslandRim(context),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                surfaceStudioRoleMappingLabel(role),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                linked ? 'Animation liée' : 'Animation manquante',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: linked ? _accent : _warning,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              if (linked)
                Text(
                  preset.animationIdForRole(role)!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 8.5,
                    height: 1.15,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return box;
  }
}
