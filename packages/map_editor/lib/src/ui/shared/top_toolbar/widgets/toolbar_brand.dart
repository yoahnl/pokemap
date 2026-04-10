import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../cupertino_editor_widgets.dart';

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
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const honey = EditorChrome.inspectorJoyHoney;
    const cyan = EditorChrome.inspectorJoyCyan;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, honey, 0.75)!,
                  Color.lerp(cyan, const Color(0xFF102828), 0.4)!,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: honey.withValues(alpha: 0.9),
                width: 1.25,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.square_stack_3d_up_fill,
              color: CupertinoColors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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
