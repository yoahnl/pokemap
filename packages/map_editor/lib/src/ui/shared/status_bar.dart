import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final activeMap = state.activeMap;
    final labelColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final bg = state.errorMessage != null
        ? CupertinoColors.destructiveRed.resolveFrom(context)
        : CupertinoColors.activeBlue.resolveFrom(context);

    return Container(
      height: 24,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          MacosIcon(
            state.errorMessage != null
                ? CupertinoIcons.exclamationmark_circle
                : CupertinoIcons.info,
            size: 14,
            color: CupertinoColors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage ?? state.statusMessage ?? 'Ready',
              style: const TextStyle(
                fontSize: 10,
                color: CupertinoColors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (activeMap != null) ...[
            _miniDivider(),
            Text(
              'Map: ${activeMap.id} (${activeMap.size.width}x${activeMap.size.height})',
              style: TextStyle(fontSize: 10, color: labelColor),
            ),
          ],
          _miniDivider(),
          Text(
            'Zoom: ${(state.zoom * 100).toInt()}%',
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  static Widget _miniDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 12,
        width: 1,
        child: ColoredBox(color: Color(0x44FFFFFF)),
      ),
    );
  }
}
