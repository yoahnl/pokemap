import 'package:flutter/material.dart';

class GameBehaviourWorkspace extends StatelessWidget {
  const GameBehaviourWorkspace({
    super.key,
    required this.list,
    required this.editor,
  });

  final Widget list;
  final Widget Function(bool contextAlongside) editor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: const ValueKey('story-trigger-workspace'),
    builder: (context, area) {
      final contextAlongside = area.maxWidth > 1150;
      final largeText = MediaQuery.textScalerOf(context).scale(12) >= 18;
      final listWidth = switch ((largeText, MediaQuery.sizeOf(context).width)) {
        (true, _) => 228.0,
        (false, <= 1100) => 185.0,
        _ => contextAlongside ? 228.0 : 214.0,
      };
      final content = editor(contextAlongside);
      return area.maxWidth >= 720
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: listWidth, child: list),
                Expanded(child: content),
              ],
            )
          : Column(
              children: [
                SizedBox(height: area.maxHeight * .4, child: list),
                Expanded(child: content),
              ],
            );
    },
  );
}
