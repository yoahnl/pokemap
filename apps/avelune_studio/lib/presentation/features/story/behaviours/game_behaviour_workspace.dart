import 'package:flutter/material.dart';

class GameBehaviourWorkspace extends StatelessWidget {
  const GameBehaviourWorkspace({
    super.key,
    required this.list,
    required this.editor,
  });

  final Widget list;
  final Widget editor;

  @override
  Widget build(BuildContext context) {
    final listWidth = switch (MediaQuery.sizeOf(context).width) {
      <= 1100 => 185.0,
      <= 1150 => 214.0,
      _ => 228.0,
    };
    return LayoutBuilder(
      key: const ValueKey('story-trigger-workspace'),
      builder: (context, area) => area.maxWidth >= 720
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: listWidth, child: list),
                Expanded(child: editor),
              ],
            )
          : Column(
              children: [
                SizedBox(height: area.maxHeight * .4, child: list),
                Expanded(child: editor),
              ],
            ),
    );
  }
}
