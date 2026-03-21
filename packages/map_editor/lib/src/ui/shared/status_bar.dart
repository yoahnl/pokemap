import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final activeMap = state.activeMap;

    return Container(
      height: 24,
      color: state.errorMessage != null
          ? Colors.red.shade900
          : Colors.blue.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            state.errorMessage != null
                ? Icons.error_outline
                : Icons.info_outline,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage ?? state.statusMessage ?? 'Ready',
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (activeMap != null) ...[
            const VerticalDivider(
                width: 16, color: Colors.white24, indent: 4, endIndent: 4),
            Text(
              'Map: ${activeMap.id} (${activeMap.size.width}x${activeMap.size.height})',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
          const VerticalDivider(
              width: 16, color: Colors.white24, indent: 4, endIndent: 4),
          Text(
            'Zoom: ${(state.zoom * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
