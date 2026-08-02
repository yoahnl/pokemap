import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/entity_properties_panel.dart';
import '../../../../ui/panels/event_properties_panel.dart';
import '../../../../ui/panels/gameplay_zone_properties_panel.dart';
import '../../../../ui/panels/trigger_properties_panel.dart';
import '../../../../ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import '../../../../ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';
import '../../../../ui/panels/warp_properties_panel.dart';
import '../../application/world_map_subtool_body_projector.dart';
import '../../application/world_map_rejection_message.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import 'world_map_subtool_disabled_guidance.dart';
import 'world_map_workspace_session.dart';

class WorldMapPlaceInspector extends ConsumerWidget {
  const WorldMapPlaceInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtool = ref.watch(
      worldMapWorkspaceSessionProvider.select(
        (session) => session.lastPlacementSubtool,
      ),
    );
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          source: worldMapToolActivationSourceFromState(state),
          selectedEntityKind: state.selectedEntityKind,
          selectedId: switch (subtool) {
            WorldMapPlacementSubtool.object => null,
            WorldMapPlacementSubtool.entity => state.selectedEntityId,
            WorldMapPlacementSubtool.event => state.selectedMapEventId,
            WorldMapPlacementSubtool.trigger => state.selectedTriggerId,
            WorldMapPlacementSubtool.warp => state.selectedWarpId,
            WorldMapPlacementSubtool.gameplayZone =>
              state.selectedGameplayZoneId,
          },
        ),
      ),
    );
    final projection = const WorldMapSubtoolBodyProjector().project(
      source: snapshot.source,
      request: ActivateWorldMapPlacement(subtool),
    );
    final session = ref.read(worldMapWorkspaceSessionProvider.notifier);
    final editor = ref.read(editorNotifierProvider.notifier);

    void activatePlacement(WorldMapPlacementSubtool nextSubtool) {
      final result = session.activateTool(
        editor,
        ActivateWorldMapPlacement(nextSubtool),
      );
      if (result.accepted) {
        ref.read(worldMapAccessibilityErrorProvider.notifier).clear();
        session.setInspectorVisible(true);
        return;
      }
      final message = projectWorldMapRejectionMessageFr(
        result.rejectionReason,
      );
      if (message != null) {
        ref.read(worldMapAccessibilityErrorProvider.notifier).announce(message);
      }
    }

    final body = !projection.isAvailable
        ? WorldMapSubtoolDisabledGuidance(
            title: 'Placer · ${_placementSubtoolLabel(subtool)}',
            reason: projection.disabledReason!,
            icon: const Icon(Icons.add_location_alt_outlined),
          )
        : KeyedSubtree(
            key: ValueKey<String>(
              'world-map-place-body-${projection.bodyKind.name}',
            ),
            child: switch (projection.bodyKind) {
              WorldMapSubtoolBodyKind.elementsPalette => Semantics(
                  container: true,
                  label: 'Catalogue d’objets du calque actif',
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MapPaletteAssetBrowserLauncher(
                            label: 'Changer de source'),
                        SizedBox(height: 10),
                        Expanded(
                          child: MapLayerAssetPalette(),
                        ),
                      ],
                    ),
                  ),
                ),
              WorldMapSubtoolBodyKind.entityPlacement => _placementBody(
                  subtool: subtool,
                  bodyKind: projection.bodyKind,
                  selectedId: snapshot.selectedId,
                  items: snapshot.source.activeMap?.entities,
                  readId: (item) => item.id,
                  panel: const EntityPropertiesPanel(embedded: true),
                ),
              WorldMapSubtoolBodyKind.eventPlacement => _placementBody(
                  subtool: subtool,
                  bodyKind: projection.bodyKind,
                  selectedId: snapshot.selectedId,
                  items: snapshot.source.activeMap?.events,
                  readId: (item) => item.id,
                  panel: const EventPropertiesPanel(embedded: true),
                ),
              WorldMapSubtoolBodyKind.triggerPlacement => _placementBody(
                  subtool: subtool,
                  bodyKind: projection.bodyKind,
                  selectedId: snapshot.selectedId,
                  items: snapshot.source.activeMap?.triggers,
                  readId: (item) => item.id,
                  panel: const TriggerPropertiesPanel(embedded: true),
                ),
              WorldMapSubtoolBodyKind.warpPlacement => _placementBody(
                  subtool: subtool,
                  bodyKind: projection.bodyKind,
                  selectedId: snapshot.selectedId,
                  items: snapshot.source.activeMap?.warps,
                  readId: (item) => item.id,
                  panel: const WarpPropertiesPanel(embedded: true),
                ),
              WorldMapSubtoolBodyKind.gameplayZonePlacement => _placementBody(
                  subtool: subtool,
                  bodyKind: projection.bodyKind,
                  selectedId: snapshot.selectedId,
                  items: snapshot.source.activeMap?.gameplayZones,
                  readId: (item) => item.id,
                  panel: const GameplayZonePropertiesPanel(embedded: true),
                ),
              WorldMapSubtoolBodyKind.tilesPalette ||
              WorldMapSubtoolBodyKind.terrainPainter ||
              WorldMapSubtoolBodyKind.pathPainter ||
              WorldMapSubtoolBodyKind.surfacePainter ||
              WorldMapSubtoolBodyKind.borderInspector ||
              WorldMapSubtoolBodyKind.collisionInspector =>
                throw StateError(
                  'A paint body cannot be projected for Place.',
                ),
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WorldMapPlacementHub(
          selectedSubtool: subtool,
          source: snapshot.source,
          selectedEntityKind: snapshot.selectedEntityKind,
          onSubtoolSelected: activatePlacement,
          onEntityKindSelected: editor.selectEntityKind,
        ),
        Divider(
          height: 1,
          color: context.pokeMapColors.divider,
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _WorldMapPlacementHub extends StatelessWidget {
  const _WorldMapPlacementHub({
    required this.selectedSubtool,
    required this.source,
    required this.selectedEntityKind,
    required this.onSubtoolSelected,
    required this.onEntityKindSelected,
  });

  final WorldMapPlacementSubtool selectedSubtool;
  final WorldMapToolActivationSource source;
  final MapEntityKind selectedEntityKind;
  final ValueChanged<WorldMapPlacementSubtool> onSubtoolSelected;
  final ValueChanged<MapEntityKind> onEntityKindSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Que voulez-vous placer ?',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final subtool in WorldMapPlacementSubtool.values)
                    SizedBox(
                      width: tileWidth,
                      child: _placementFamilyTile(subtool),
                    ),
                ],
              );
            },
          ),
          if (selectedSubtool == WorldMapPlacementSubtool.entity) ...[
            const SizedBox(height: 10),
            Text(
              'Entité  ›  ${_entityKindLabel(selectedEntityKind)}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final kind in MapEntityKind.values)
                  PokeMapButton(
                    key: ValueKey<String>(
                      'world-map-entity-kind-${kind.name}',
                    ),
                    onPressed: () => onEntityKindSelected(kind),
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.secondary,
                    isSelected: kind == selectedEntityKind,
                    leading: Icon(_entityKindIcon(kind)),
                    semanticLabel: 'Type d’entité : ${_entityKindLabel(kind)}',
                    child: Text(_entityKindLabel(kind)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _placementFamilyTile(WorldMapPlacementSubtool subtool) {
    final projection = const WorldMapSubtoolBodyProjector().project(
      source: source,
      request: ActivateWorldMapPlacement(subtool),
    );
    return PokeMapActionTile(
      key: ValueKey<String>('world-map-placement-family-${subtool.name}'),
      icon: _placementSubtoolIcon(subtool),
      label: _placementSubtoolLabel(subtool),
      semanticLabel: 'Placer · ${_placementSubtoolLabel(subtool)}',
      isSelected: subtool == selectedSubtool,
      disabledReason: projection.disabledReason,
      onPressed:
          projection.isAvailable ? () => onSubtoolSelected(subtool) : null,
    );
  }
}

Widget _placementBody<T>({
  required WorldMapPlacementSubtool subtool,
  required WorldMapSubtoolBodyKind bodyKind,
  required String? selectedId,
  required Iterable<T>? items,
  required String Function(T item) readId,
  required Widget panel,
  Widget? guidanceAction,
}) {
  final resolved = selectedId != null &&
      items?.any((item) => readId(item) == selectedId) == true;
  if (resolved) {
    return KeyedSubtree(
      key: ValueKey<String>(
        'world-map-place-selection-${subtool.name}-$selectedId',
      ),
      child: panel,
    );
  }
  return _WorldMapPlacementGuidance(
    key: ValueKey<String>(
      'world-map-placement-guidance-${bodyKind.name}',
    ),
    subtool: subtool,
    action: guidanceAction,
  );
}

class _WorldMapPlacementGuidance extends StatelessWidget {
  const _WorldMapPlacementGuidance({
    super.key,
    required this.subtool,
    this.action,
  });

  final WorldMapPlacementSubtool subtool;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final label = _placementSubtoolLabel(subtool);
    return Semantics(
      container: true,
      label: 'Placement $label',
      child: PokeMapEmptyState(
        icon: const Icon(Icons.add_location_alt_outlined),
        title: 'Placer · $label',
        description:
            'Cliquez sur la carte pour placer un élément de ce type. Ses '
            'propriétés apparaîtront ici dès qu’il sera sélectionné.',
        action: action,
      ),
    );
  }
}

String _placementSubtoolLabel(WorldMapPlacementSubtool subtool) {
  return switch (subtool) {
    WorldMapPlacementSubtool.object => 'Objet',
    WorldMapPlacementSubtool.entity => 'Entité',
    WorldMapPlacementSubtool.event => 'Événement',
    WorldMapPlacementSubtool.trigger => 'Déclencheur',
    WorldMapPlacementSubtool.warp => 'Téléporteur',
    WorldMapPlacementSubtool.gameplayZone => 'Zone de gameplay',
  };
}

IconData _placementSubtoolIcon(WorldMapPlacementSubtool subtool) {
  return switch (subtool) {
    WorldMapPlacementSubtool.object => Icons.view_in_ar_outlined,
    WorldMapPlacementSubtool.entity => Icons.person_outline_rounded,
    WorldMapPlacementSubtool.event => Icons.event_note_outlined,
    WorldMapPlacementSubtool.trigger => Icons.bolt_outlined,
    WorldMapPlacementSubtool.warp => Icons.cyclone_outlined,
    WorldMapPlacementSubtool.gameplayZone => Icons.crop_free_rounded,
  };
}

String _entityKindLabel(MapEntityKind kind) {
  return switch (kind) {
    MapEntityKind.npc => 'PNJ',
    MapEntityKind.sign => 'Panneau',
    MapEntityKind.item => 'Objet ramassable',
    MapEntityKind.spawn => 'Point d’apparition',
    MapEntityKind.custom => 'Personnalisée',
  };
}

IconData _entityKindIcon(MapEntityKind kind) {
  return switch (kind) {
    MapEntityKind.npc => Icons.person_outline_rounded,
    MapEntityKind.sign => Icons.signpost_outlined,
    MapEntityKind.item => Icons.inventory_2_outlined,
    MapEntityKind.spawn => Icons.flag_outlined,
    MapEntityKind.custom => Icons.extension_outlined,
  };
}
