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
    final hasError = state.errorMessage != null;
    final labelColor = hasError
        ? const Color(0xFFF3C5CB)
        : EditorChrome.subtleLabel(context);
    final tint = hasError
        ? const Color(0xFF271B1F)
        : const Color(0xFF284255);
    final leadingTint = hasError
        ? const Color(0xFFE2A3AD)
        : const Color(0xFF8FC7BC);
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
                  color: leadingTint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  icon,
                  size: 15,
                  color: leadingTint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.errorMessage ?? state.statusMessage ?? 'Ready',
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
    BuildContext context,
    String label,
    IconData icon,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(999),
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
