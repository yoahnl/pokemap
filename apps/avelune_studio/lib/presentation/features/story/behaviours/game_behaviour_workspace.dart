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
  Widget build(BuildContext context) => LayoutBuilder(
    key: const ValueKey('story-trigger-workspace'),
    builder: (context, area) => area.maxWidth >= 720
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 214, child: list),
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
