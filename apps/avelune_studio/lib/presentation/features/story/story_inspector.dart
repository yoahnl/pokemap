import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryInspector extends StatelessWidget {
  const StoryInspector({
    super.key,
    required this.child,
    required this.showTitle,
    this.width = 320,
  });

  final Widget child;
  final bool showTitle;
  final double width;

  @override
  Widget build(BuildContext context) => StudioSidebar(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle)
          StudioPageHeader.section(title: context.l10n.inspectorTitle),
        Expanded(child: child),
      ],
    ),
  );
}
