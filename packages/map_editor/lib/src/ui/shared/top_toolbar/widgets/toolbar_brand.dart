import 'package:flutter/cupertino.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import '../../../../theme/theme.dart';

/// Bloc visuel de marque utilisé dans la toolbar native.
///
/// On le sort du fichier principal pour que `top_toolbar.dart` reste un
/// assembleur. Le comportement reste identique : aucun état, aucune logique
/// métier, seulement la composition visuelle du titre.
class TopToolbarBrand extends StatelessWidget {
  const TopToolbarBrand({
    super.key,
    required this.projectName,
    required this.workspaceLabel,
  });

  final String? projectName;
  final String workspaceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final subtle = colors.textSecondary;
    final label = colors.textPrimary;

    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(colors.textInverse, colors.brandPrimary, 0.75)!,
                  Color.lerp(colors.brandCyan, const Color(0xFF10202F), 0.4)!,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.brandPrimaryBorder,
                width: 1.25,
              ),
            ),
            alignment: Alignment.center,
            child: MacosIcon(
              CupertinoIcons.square_stack_3d_up_fill,
              color: colors.textInverse,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'PokeMap',
            style: TextStyle(
              color: label,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              decoration: TextDecoration.none,
            ),
          ),
          Container(
            height: 14,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: colors.divider.withValues(alpha: 0.5),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RPG Map Editor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  projectName == null
                      ? workspaceLabel
                      : '$projectName  •  $workspaceLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
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
