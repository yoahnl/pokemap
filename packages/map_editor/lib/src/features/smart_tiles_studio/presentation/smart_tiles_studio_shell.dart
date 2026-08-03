import 'package:flutter/cupertino.dart';

import '../../../ui/design_system/design_system.dart';

/// Responsive three-surface shell approved for Smart Tiles Studio.
///
/// Desktop keeps all surfaces visible, intermediate widths move the inspector
/// to a side sheet, and narrow widths expose both secondary surfaces through
/// labelled modal controls while preserving the workbench width.
class SmartTilesStudioShell extends StatelessWidget {
  const SmartTilesStudioShell({
    super.key,
    required this.library,
    required this.workbench,
    required this.inspector,
  });

  final Widget library;
  final Widget workbench;
  final Widget inspector;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          final inspectorWidth = constraints.maxWidth >= 1220 ? 300.0 : 260.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                key: const Key('smart-tiles-library-column'),
                width: 280,
                child: library,
              ),
              const SizedBox(width: 12),
              Expanded(
                key: const Key('smart-tiles-workbench-column'),
                child: workbench,
              ),
              const SizedBox(width: 12),
              SizedBox(
                key: const Key('smart-tiles-inspector-column'),
                width: inspectorWidth,
                child: inspector,
              ),
            ],
          );
        }
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                key: const Key('smart-tiles-library-column'),
                width: 240,
                child: library,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SecondarySurfaceBar(
                      inspectorOnly: true,
                      onOpenLibrary: null,
                      onOpenInspector: () => _showInspector(context),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      key: const Key('smart-tiles-workbench-column'),
                      child: workbench,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SecondarySurfaceBar(
              inspectorOnly: false,
              onOpenLibrary: () => _showLibrary(context),
              onOpenInspector: () => _showInspector(context),
            ),
            const SizedBox(height: 8),
            Expanded(
              key: const Key('smart-tiles-workbench-column'),
              child: workbench,
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLibrary(BuildContext context) =>
      showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Bibliothèque Smart Tiles',
        semanticLabel: 'Bibliothèque Smart Tiles',
        width: 440,
        builder: (_) => SizedBox(
          key: const Key('smart-tiles-library-modal'),
          height: double.infinity,
          child: library,
        ),
      );

  Future<void> _showInspector(BuildContext context) =>
      showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Inspecteur Smart Tiles',
        semanticLabel: 'Inspecteur Smart Tiles',
        width: 420,
        builder: (_) => SizedBox(
          key: const Key('smart-tiles-inspector-drawer'),
          height: double.infinity,
          child: inspector,
        ),
      );
}

class _SecondarySurfaceBar extends StatelessWidget {
  const _SecondarySurfaceBar({
    required this.inspectorOnly,
    required this.onOpenLibrary,
    required this.onOpenInspector,
  });

  final bool inspectorOnly;
  final VoidCallback? onOpenLibrary;
  final VoidCallback onOpenInspector;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          if (!inspectorOnly)
            PokeMapButton(
              key: const Key('smart-tiles-open-library'),
              onPressed: onOpenLibrary,
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              leading: const Icon(CupertinoIcons.square_grid_2x2, size: 14),
              child: const Text('Bibliothèque'),
            ),
          PokeMapButton(
            key: const Key('smart-tiles-open-inspector'),
            onPressed: onOpenInspector,
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.sidebar_right, size: 14),
            child: const Text('Inspecteur'),
          ),
        ],
      ),
    );
  }
}
