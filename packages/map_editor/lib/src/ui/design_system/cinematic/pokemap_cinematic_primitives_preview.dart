import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../theme/theme.dart';
import 'pokemap_cinematic_canvas_primitives.dart';
import 'pokemap_cinematic_layer_primitives.dart';
import 'pokemap_cinematic_library_primitives.dart';
import 'pokemap_cinematic_media_primitives.dart';
import 'pokemap_cinematic_timeline_primitives.dart';
import 'pokemap_cinematic_workspace_primitives.dart';

Widget pokeMapCinematicLightPreviewWrapper(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: PokeMapTheme.light(),
    home: Scaffold(body: child),
  );
}

Widget pokeMapCinematicDarkPreviewWrapper(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: PokeMapTheme.dark(),
    home: Scaffold(body: child),
  );
}

void pokeMapCinematicPreviewAction() {}

@Preview(
  name: 'Library · Light',
  group: 'Cinematic Studio',
  size: Size(1000, 520),
  wrapper: pokeMapCinematicLightPreviewWrapper,
)
@Preview(
  name: 'Library · Dark',
  group: 'Cinematic Studio',
  size: Size(1000, 520),
  wrapper: pokeMapCinematicDarkPreviewWrapper,
)
Widget pokeMapCinematicLibraryPrimitivesPreview() {
  return const _PokeMapCinematicLibraryPrimitivesPreview();
}

@Preview(
  name: 'Canvas & Layers · Light',
  group: 'Cinematic Studio',
  size: Size(1200, 680),
  wrapper: pokeMapCinematicLightPreviewWrapper,
)
@Preview(
  name: 'Canvas & Layers · Dark',
  group: 'Cinematic Studio',
  size: Size(1200, 680),
  wrapper: pokeMapCinematicDarkPreviewWrapper,
)
Widget pokeMapCinematicCanvasLayerPrimitivesPreview() {
  return const _PokeMapCinematicCanvasLayerPrimitivesPreview();
}

@Preview(
  name: 'Timeline & Media · Light',
  group: 'Cinematic Studio',
  size: Size(1200, 700),
  wrapper: pokeMapCinematicLightPreviewWrapper,
)
@Preview(
  name: 'Timeline & Media · Dark',
  group: 'Cinematic Studio',
  size: Size(1200, 700),
  wrapper: pokeMapCinematicDarkPreviewWrapper,
)
Widget pokeMapCinematicTimelineMediaPrimitivesPreview() {
  return const _PokeMapCinematicTimelineMediaPrimitivesPreview();
}

class _PokeMapCinematicLibraryPrimitivesPreview extends StatelessWidget {
  const _PokeMapCinematicLibraryPrimitivesPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return ColoredBox(
      color: colors.backgroundApp,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapCinematicFamilyTabs(
              selected: PokeMapCinematicLibraryMode.presentation,
              inGameLabel: 'Cinématiques in-game',
              presentationLabel: 'Cinématiques de présentation',
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            PokeMapCinematicBreadcrumb(
              semanticLabel: 'Chemin du dossier',
              items: [
                PokeMapCinematicBreadcrumbItem(
                  label: 'Toutes les cinématiques',
                  onPressed: pokeMapCinematicPreviewAction,
                ),
                PokeMapCinematicBreadcrumbItem(
                  label: 'Introductions',
                  onPressed: pokeMapCinematicPreviewAction,
                ),
                const PokeMapCinematicBreadcrumbItem(label: 'Chapitre 1'),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: PokeMapCinematicLibraryStateSurface(
                      state: PokeMapCinematicLibraryState.loading,
                      title: 'Chargement',
                      description: 'Chargement des cinématiques…',
                    ),
                  ),
                  VerticalDivider(width: 24),
                  Expanded(
                    child: PokeMapCinematicLibraryStateSurface(
                      state: PokeMapCinematicLibraryState.error,
                      title: 'Impossible de charger',
                      description: 'Le catalogue reste intact.',
                      actionLabel: 'Réessayer',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokeMapCinematicCanvasLayerPrimitivesPreview extends StatelessWidget {
  const _PokeMapCinematicCanvasLayerPrimitivesPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return ColoredBox(
      color: colors.backgroundApp,
      child: Column(
        children: [
          PokeMapCinematicWorkspaceToolbar(
            backLabel: 'Retour à la bibliothèque',
            title: 'Ouverture',
            contextLabel: 'Cinématique de présentation',
            onBack: pokeMapCinematicPreviewAction,
            status: const PokeMapCinematicDocumentStatus(
              state: PokeMapCinematicDocumentState.dirty,
              label: 'Non enregistrée',
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: PokeMapCinematicViewport(
                      composition: PokeMapCinematicComposition.landscape16x9,
                      semanticLabel: 'Aperçu paysage',
                      showSafeArea: true,
                      selected: true,
                      child: ColoredBox(color: colors.surfaceSubtle),
                    ),
                  ),
                ),
                SizedBox(
                  width: 340,
                  child: Column(
                    children: [
                      PokeMapCinematicPanelTabs(
                        selected: PokeMapCinematicPanelTab.layers,
                        layersLabel: 'Calques',
                        propertiesLabel: 'Propriétés',
                        onChanged: (_) {},
                      ),
                      const PokeMapCinematicLayerGroupHeader(
                        label: 'Visuels',
                        expanded: true,
                        hidden: false,
                        locked: false,
                        toggleLabel: 'Replier Visuels',
                        stateLabel: 'Visuels disponibles',
                        onToggleExpanded: pokeMapCinematicPreviewAction,
                      ),
                      PokeMapCinematicLayerRow(
                        kind: PokeMapCinematicLayerKind.visual,
                        label: 'Titre principal',
                        visible: true,
                        locked: false,
                        selected: true,
                        indent: 1,
                        visibilityLabel: 'Masquer Titre principal',
                        lockLabel: 'Verrouiller Titre principal',
                        dragLabel: 'Réordonner Titre principal',
                        onSelect: pokeMapCinematicPreviewAction,
                      ),
                      PokeMapCinematicLayerRow(
                        kind: PokeMapCinematicLayerKind.visual,
                        label: 'Image de fond',
                        visible: true,
                        locked: true,
                        indent: 1,
                        diagnosticLabel: 'Version portrait manquante',
                        visibilityLabel: 'Masquer Image de fond',
                        lockLabel: 'Déverrouiller Image de fond',
                        dragLabel: 'Réordonner Image de fond',
                        onSelect: pokeMapCinematicPreviewAction,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokeMapCinematicTimelineMediaPrimitivesPreview extends StatelessWidget {
  const _PokeMapCinematicTimelineMediaPrimitivesPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return ColoredBox(
      color: colors.backgroundApp,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 32,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: const PokeMapCinematicTimelineRuler(
                  duration: Duration(seconds: 12),
                  playhead: Duration(seconds: 4),
                  pixelsPerSecond: 80,
                  semanticLabel: 'Règle temporelle',
                ),
              ),
            ),
            const SizedBox(height: 8),
            PokeMapCinematicTrackRow(
              label: 'Titre principal',
              icon: Icons.title_rounded,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PokeMapCinematicTimelineClip(
                  label: 'Ouverture',
                  duration: const Duration(seconds: 5),
                  pixelsPerSecond: 80,
                  selected: true,
                  startTrimLabel: 'Rogner le début',
                  endTrimLabel: 'Rogner la fin',
                  onPressed: pokeMapCinematicPreviewAction,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PokeMapCinematicMediaSlot(
                      orientation: PokeMapCinematicMediaOrientation.landscape,
                      title: 'Version paysage',
                      state: PokeMapCinematicMediaSlotState.ready,
                      sourceLabel: 'ouverture-16x9.png',
                      actionLabel: 'Remplacer',
                      onAction: pokeMapCinematicPreviewAction,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PokeMapCinematicMediaSlot(
                      orientation: PokeMapCinematicMediaOrientation.portrait,
                      title: 'Version portrait',
                      state: PokeMapCinematicMediaSlotState.ready,
                      sourceLabel: 'ouverture-16x9.png',
                      fallbackLabel: 'Fallback paysage',
                      actionLabel: 'Choisir',
                      onAction: pokeMapCinematicPreviewAction,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PokeMapCinematicMediaSlot(
              orientation: PokeMapCinematicMediaOrientation.shared,
              title: 'Musique partagée',
              state: PokeMapCinematicMediaSlotState.importing,
              sourceLabel: 'theme-ouverture.ogg',
              statusLabel: 'Import 42 %',
              progress: 0.42,
              cancelLabel: 'Annuler l’import',
              onCancel: pokeMapCinematicPreviewAction,
            ),
          ],
        ),
      ),
    );
  }
}
