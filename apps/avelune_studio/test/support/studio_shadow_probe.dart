import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart'
    show SpatialSceneGame;
import 'package:map_render_3d/src/spatial_render_context.dart';

void registerStudioShadowProbe({required bool Function() isCopyActive}) {
  final lightingSnapshots = <SpatialSceneGame, SpatialLightingProfile?>{};
  developer.registerExtension('ext.flutter.avelune.shadowProbe', (
    method,
    params,
  ) async {
    if (!isCopyActive()) throw StateError('Copy-only inspection required.');
    final games = <SpatialSceneGame>[];
    void visit(Element element) {
      if (element.widget case GameWidget(game: final SpatialSceneGame game)) {
        games.add(game);
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    final action = params['action'] ?? 'inspect';
    if (!{
      'inspect',
      'restore',
      'noSolar',
      'noLighting',
      'hideWind',
      'freezeLighting',
      'antialiasing',
      'multisampling',
    }.contains(action)) {
      throw ArgumentError.value(action, 'action');
    }
    final active = games.where((game) => !game.isPaused).toList();
    for (final game in active) {
      if (action == 'inspect') continue;
      if (action == 'antialiasing') {
        (game.context as SpatialRenderContext).shadowAntialiasingEnabled =
            params['enabled'] != 'false';
        continue;
      }
      if (action == 'multisampling') {
        (game.context as SpatialRenderContext).preferMultisampledShadows =
            params['enabled'] != 'false';
        continue;
      }
      if (action == 'restore') {
        (game.context as SpatialRenderContext)
          ..shadowAntialiasingEnabled = true
          ..preferMultisampledShadows = true;
        game.previewLighting = lightingSnapshots.remove(game);
      } else {
        lightingSnapshots.putIfAbsent(game, () => game.previewLighting);
        final source = (game.context as SpatialRenderContext).lighting;
        game.previewLighting = action == 'noLighting'
            ? SpatialLightingProfile.disabled
            : SpatialLightingProfile.stylized(
                ambientColor: source.ambientColor,
                sunColor: source.sunColor,
                ambientStrength: source.ambientStrength,
                sunStrength: source.sunStrength,
                sunDirection: source.sunDirection,
                actorStrength: source.actorStrength,
                groundStrength: source.groundStrength,
                surfaceStrength: source.surfaceStrength,
                unlitMaterialNames: source.unlitMaterialNames,
                hiddenMaterialsByInstance: {
                  ...source.hiddenMaterialsByInstance,
                  if (action == 'hideWind')
                    for (final instance in game.configuration.scene.instances)
                      if (instance.modelId == 'hgss-wind-particles-028')
                        instance.id: {'wind_lm3', 'wind_lm4', 'wind_lm5'},
                },
                shadow: action == 'noSolar' ? null : source.shadow,
                sceneTint: source.sceneTint,
                pointLights: source.pointLights,
                pointShadowCasterInstanceIds:
                    source.pointShadowCasterInstanceIds,
              );
      }
      game.syncLighting();
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'action': action,
        'persistentMutation': false,
        'games': [
          for (final game in games)
            {
              'identity': identityHashCode(game),
              'paused': game.isPaused,
              'ready': game.sceneReady,
              'refreshing': game.refreshing,
              'cameraView': game.configuration.controller.view.name,
              'cameraZoom': game.configuration.controller.zoom,
              'cameraMagnification': game.configuration.cameraMagnification
                  ?.call(),
              'dayNightMinute':
                  game.configuration.controller.dayNightMinuteOfDay,
              'mapId': game.configuration.groundMap?.id,
              'neighbors': [
                for (final neighbor in game.configuration.neighbors)
                  neighbor.map.id,
              ],
              'minute': game.configuration.controller.previewMinuteOfDay,
              'lighting': {
                'antialiasing': (game.context as SpatialRenderContext)
                    .shadowAntialiasingEnabled,
                'solarSamples':
                    (game.context as SpatialRenderContext).shadowFrame?.samples,
                'supersampledSolar': (game.context as SpatialRenderContext)
                    .shadowFrame
                    ?.supersampled,
                'supersampledPoint': (game.context as SpatialRenderContext)
                    .pointShadowFrame
                    ?.supersampled,
                'pointSamples': (game.context as SpatialRenderContext)
                    .pointShadowFrame
                    ?.samples,
                'sun': (game.context as SpatialRenderContext)
                    .lighting
                    .sunDirection
                    .toString(),
                'casterCount': (game.context as SpatialRenderContext)
                    .lighting
                    .shadow
                    ?.casterInstanceIds
                    .length,
                'extent': (game.context as SpatialRenderContext)
                    .lighting
                    .shadow
                    ?.extent,
                'depth': (game.context as SpatialRenderContext)
                    .lighting
                    .shadow
                    ?.depth,
                'resolution': (game.context as SpatialRenderContext)
                    .lighting
                    .shadow
                    ?.resolution,
                'receiverMinY': (game.context as SpatialRenderContext)
                    .lighting
                    .shadow
                    ?.receiverMinY,
                'receiverMaxY': (game.context as SpatialRenderContext)
                    .lighting
                    .shadow
                    ?.receiverMaxY,
              },
            },
        ],
      }),
    );
  });
}
