import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../features/editor/state/editor_notifier.dart';
import 'cupertino_editor_widgets.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final activeMap = state.activeMap;
    const pendingProjectSaveMessage =
        'Projet modifié en mémoire — sauvegardez le projet avec la disquette.';
    final hasError = state.errorMessage != null;
    final primaryMessage = hasError
        ? state.errorMessage!
        : state.isProjectDirty
            ? pendingProjectSaveMessage
            : state.statusMessage ?? 'Ready';
    final labelColor =
        hasError ? const Color(0xFFF3C5CB) : EditorChrome.subtleLabel(context);
    final tint = hasError
        ? EditorChrome.errorTint(context)
        : EditorChrome.islandCoolTint;
    final leadingTint = hasError
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.inspectorJoyCyan;
    final icon = hasError
        ? CupertinoIcons.exclamationmark_triangle_fill
        : CupertinoIcons.sparkles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 2, 22, 18),
      child: EditorPaneSurface(
        radius: 22,
        tint: tint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(CupertinoColors.white, leadingTint, 0.82)!,
                      Color.lerp(leadingTint, const Color(0xFF1A0A08), 0.42)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: leadingTint.withValues(alpha: 0.88),
                    width: 1.1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  icon,
                  size: 15,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  primaryMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasError ? leadingTint : const Color(0xFFF2F2F4),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (activeMap != null) ...[
                _statusChip(
                  context,
                  'Map ${activeMap.id}',
                  CupertinoIcons.map,
                  labelColor,
                ),
                const SizedBox(width: 8),
                _statusChip(
                  context,
                  '${activeMap.size.width} x ${activeMap.size.height}',
                  CupertinoIcons.rectangle_grid_2x2,
                  labelColor,
                ),
                const SizedBox(width: 8),
              ],
              if (state.isProjectDirty) ...[
                _statusChip(
                  context,
                  'Projet non sauvegardé',
                  CupertinoIcons.floppy_disk,
                  labelColor,
                  key: const Key('status-bar-project-dirty-chip'),
                ),
                const SizedBox(width: 8),
              ],
              _statusChip(
                context,
                'Zoom ${(state.zoom * 100).toInt()}%',
                CupertinoIcons.search,
                labelColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _statusChip(
      BuildContext context, String label, IconData icon, Color textColor,
      {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Color.lerp(
          EditorChrome.chipFill(context),
          EditorChrome.inspectorJoyHoney,
          0.18,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.inspectorJoyApricot.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
