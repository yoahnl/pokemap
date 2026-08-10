import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import 'personalization_scene_inspector.dart';
import 'personalization_scene_navigation.dart';

class PersonalizationStudioShellV2 extends StatelessWidget {
  const PersonalizationStudioShellV2({
    super.key,
    required this.selectedScene,
    required this.onSceneSelected,
    required this.preview,
    required this.inspectorTitle,
    required this.inspectorDescription,
    required this.inspector,
  });

  final PersonalizationStudioScene selectedScene;
  final ValueChanged<PersonalizationStudioScene> onSceneSelected;
  final Widget preview;
  final String inspectorTitle;
  final String inspectorDescription;
  final Widget inspector;

  @override
  Widget build(BuildContext context) => PokeMapPageSurface(
    key: const ValueKey<String>('personalization-studio-shell-v2'),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _header(context),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _layout(context, constraints.maxWidth),
          ),
        ),
      ],
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: <Widget>[
      const PokeMapIconTile(
        icon: Icons.palette_outlined,
        tone: PokeMapTone.warning,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Personalization Studio',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            const Text(
              'Personnalisez l’apparence et le contenu de vos scènes en jeu.',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _layout(BuildContext context, double width) {
    if (width >= 1100) {
      final navigationWidth = width >= 1440 ? 260.0 : 220.0;
      final inspectorWidth = width >= 1440 ? 360.0 : 320.0;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            key: const ValueKey<String>(
              'personalization-studio-navigation-pane',
            ),
            width: navigationWidth,
            child: PersonalizationSceneNavigation(
              selectedScene: selectedScene,
              onSceneSelected: onSceneSelected,
              layout: PersonalizationSceneNavigationLayout.list,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _previewPane(context, showInspectorAction: false)),
          const SizedBox(width: 12),
          SizedBox(
            key: const ValueKey<String>(
              'personalization-studio-inspector-pane',
            ),
            width: inspectorWidth,
            child: _inspectorPane(),
          ),
        ],
      );
    }
    if (width >= 760) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            key: const ValueKey<String>(
              'personalization-studio-navigation-pane',
            ),
            width: 72,
            child: PersonalizationSceneNavigation(
              selectedScene: selectedScene,
              onSceneSelected: onSceneSelected,
              layout: PersonalizationSceneNavigationLayout.rail,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _previewPane(context, showInspectorAction: true)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 80,
          child: PersonalizationSceneNavigation(
            selectedScene: selectedScene,
            onSceneSelected: onSceneSelected,
            layout: PersonalizationSceneNavigationLayout.horizontal,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _previewPane(context, showInspectorAction: true)),
      ],
    );
  }

  Widget _previewPane(
    BuildContext context, {
    required bool showInspectorAction,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (showInspectorAction) ...<Widget>[
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PokeMapButton(
            key: const ValueKey<String>(
              'personalization-studio-open-inspector',
            ),
            size: PokeMapButtonSize.compact,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(Icons.tune_rounded),
            onPressed: () => _openInspector(context),
            child: const Text('Réglages'),
          ),
        ),
        const SizedBox(height: 8),
      ],
      Expanded(
        child: KeyedSubtree(
          key: const ValueKey<String>('personalization-studio-preview-pane'),
          child: preview,
        ),
      ),
    ],
  );

  Widget _inspectorPane() => PersonalizationSceneInspector(
    title: inspectorTitle,
    description: inspectorDescription,
    child: inspector,
  );

  void _openInspector(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Réglages',
      semanticLabel: 'Réglages de $inspectorTitle',
      width: compact ? MediaQuery.sizeOf(context).width : 420,
      builder: (_) =>
          Padding(padding: const EdgeInsets.all(12), child: _inspectorPane()),
    );
  }
}
