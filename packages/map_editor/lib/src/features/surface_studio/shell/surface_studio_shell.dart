import 'package:flutter/widgets.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioShell extends StatelessWidget {
  const SurfaceStudioShell({
    super.key,
    required this.header,
    required this.sidebar,
    required this.workspacePanel,
    this.rightDock,
    required this.bottomBar,
  });

  final Widget header;
  final Widget sidebar;
  final Widget workspacePanel;
  final Widget? rightDock;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.shell'),
      color: SurfaceStudioDesignTokens.backgroundDeep,
      child: Column(
        children: [
          SizedBox(
            height: SurfaceStudioDesignTokens.headerHeight,
            child: header,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minimumReadableWidth =
                      rightDock == null ? 900.0 : 1260.0;
                  final contentWidth =
                      constraints.maxWidth < minimumReadableWidth
                          ? minimumReadableWidth
                          : constraints.maxWidth;
                  final content = SizedBox(
                    width: contentWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sidebar,
                        const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
                        Expanded(child: workspacePanel),
                        if (rightDock != null) ...[
                          const SizedBox(
                              width: SurfaceStudioDesignTokens.gapSm),
                          SizedBox(
                            width: SurfaceStudioDesignTokens
                                .rightPanelWidthExpanded,
                            child: rightDock!,
                          ),
                        ],
                      ],
                    ),
                  );
                  if (contentWidth == constraints.maxWidth) {
                    return content;
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: content,
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: SurfaceStudioDesignTokens.bottomBarHeight,
            child: bottomBar,
          ),
        ],
      ),
    );
  }
}
