import 'package:flutter/material.dart';
import 'package:avelune_design_system/avelune_design_system.dart'
    show StudioAccent;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../features/map_workspace/application/map_atmosphere_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/layout/studio_section.dart';
import '../../shared/widgets/feedback/studio_badge.dart';

class MapAtmosphereSettingsPanel extends StatefulWidget {
  const MapAtmosphereSettingsPanel({
    super.key,
    required this.controller,
    required this.map,
    this.project,
    this.preview,
    this.showSaveActions = true,
  });
  final MapAtmosphereController controller;
  final MapData map;
  final ProjectManifest? project;
  final SpatialSceneController? preview;
  final bool showSaveActions;
  @override
  State<MapAtmosphereSettingsPanel> createState() =>
      _MapAtmosphereSettingsPanelState();
}

class _MapAtmosphereSettingsPanelState
    extends State<MapAtmosphereSettingsPanel> {
  MapAtmosphereController get controller => widget.controller;
  late Map<String, (String, SpatialAtmosphereMaterialTarget)> _waterChoices;
  late Map<String, (String, SpatialAtmosphereMaterialTarget)> _windowChoices;
  Widget? _waterPicker, _windowPicker;
  final _haloChoices = <String, (String, Model3dVector3)>{};
  Widget? _haloPicker;
  int _haloIndex = 0;
  bool _choicesPrepared = false;
  void _expandSources(bool expanded) {
    if (expanded && !_choicesPrepared) setState(_prepareMaterials);
  }

  void _prepareMaterials() {
    _choicesPrepared = true;
    _haloChoices.clear();
    final models = {
      for (final model in widget.project?.models3d ?? <ProjectModel3dEntry>[])
        model.id: model,
    };
    for (final instance
        in widget.map.spatialScene?.instances ?? <SpatialModelInstance>[]) {
      final model = models[instance.modelId];
      if (model == null) continue;
      final bounds = model.inspection.bounds;
      _haloChoices[instance.id] = (
        model.name,
        model.light?.localPosition ??
            Model3dVector3(
              x: (bounds.min.x + bounds.max.x) / 2,
              y: (bounds.min.y + bounds.max.y) / 2,
              z: bounds.max.z + .04,
            ),
      );
    }
    _haloPicker = _haloChoices.isEmpty
        ? null
        : StudioSelect(
            key: const ValueKey('atmosphere-halo-target'),
            label: 'Ajouter un halo sur un objet',
            value: null,
            options: {
              for (final choice in _haloChoices.entries)
                choice.key: choice.value.$1,
            },
            onChanged: (id) {
              final settings = controller.current;
              if (settings.halos.length >= 32) {
                controller.reject(
                  'La carte peut contenir 32 halos au maximum.',
                );
                return;
              }
              final source = _haloChoices[id];
              if (source == null) return;
              _haloIndex = settings.halos.length;
              controller.edit(
                settings.copyWith(
                  halos: [
                    ...settings.halos,
                    SpatialAtmosphereHalo(
                      instanceId: id,
                      localPosition: source.$2,
                    ),
                  ],
                ),
              );
            },
          );
    _waterChoices = _materials(ground: true);
    _windowChoices = _materials(ground: false);
    _waterPicker = _waterChoices.isEmpty
        ? null
        : StudioSelect(
            key: const ValueKey('atmosphere-water-target'),
            label: 'Ajouter une surface d’eau',
            value: null,
            options: {
              for (final item in _waterChoices.entries) item.key: item.value.$1,
            },
            onChanged: (id) {
              final settings = controller.current,
                  target = _waterChoices[id]!.$2;
              if (settings.waterTargets.any(
                (item) =>
                    item.instanceId == target.instanceId &&
                    item.materialName == target.materialName,
              )) {
                return;
              }
              controller.edit(
                settings.copyWith(
                  waterTargets: [...settings.waterTargets, target],
                ),
              );
            },
          );
    _windowPicker = _windowChoices.isEmpty
        ? null
        : StudioSelect(
            key: const ValueKey('atmosphere-window-target'),
            label: 'Ajouter un vitrage',
            value: null,
            options: {
              for (final item in _windowChoices.entries)
                item.key: item.value.$1,
            },
            onChanged: (id) {
              final settings = controller.current,
                  target = _windowChoices[id]!.$2;
              if (settings.windows.any(
                (item) =>
                    item.target.instanceId == target.instanceId &&
                    item.target.materialName == target.materialName,
              )) {
                return;
              }
              controller.edit(
                settings.copyWith(
                  windows: [
                    ...settings.windows,
                    SpatialAtmosphereWindow(
                      target: target,
                      uvRects: [
                        SpatialAtmosphereUvRect(
                          left: 0,
                          top: 0,
                          right: 1,
                          bottom: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_preview);
    _preview();
  }

  @override
  void didUpdateWidget(MapAtmosphereSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.map, widget.map) ||
        !identical(oldWidget.project, widget.project)) {
      _choicesPrepared = false;
      _haloChoices.clear();
      _haloPicker = _waterPicker = _windowPicker = null;
    }
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_preview);
      controller.addListener(_preview);
    }
    if (oldWidget.controller != controller ||
        oldWidget.preview != widget.preview) {
      _preview();
    }
  }

  void _preview() =>
      widget.preview?.applyAtmosphereSettings(controller.current);
  @override
  void dispose() {
    controller.removeListener(_preview);
    super.dispose();
  }

  Widget _number(
    String key,
    String label,
    double value,
    double maximum,
    SpatialAtmosphereSettings Function(double) update,
  ) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: StudioCommitField(
      key: ValueKey('atmosphere-$key'),
      label: label,
      value: value.toStringAsFixed(2),
      tryCommit: (text) {
        final number = double.tryParse(text.trim().replaceAll(',', '.'));
        if (number == null ||
            !number.isFinite ||
            number < 0 ||
            number > maximum) {
          controller.reject('Choisissez une valeur entre 0 et $maximum.');
          return false;
        }
        try {
          controller.edit(update(number));
        } on FormatException {
          controller.reject(
            key.startsWith('fog-')
                ? 'La fin de la brume doit être plus éloignée que son début.'
                : 'Cette valeur est hors de la plage autorisée.',
          );
          return false;
        }
        return true;
      },
    ),
  );

  Map<String, (String, SpatialAtmosphereMaterialTarget)> _materials({
    required bool ground,
  }) {
    final choices = <String, (String, SpatialAtmosphereMaterialTarget)>{};
    final project = widget.project;
    if (project == null) return choices;
    if (ground) {
      final ids = {
        for (final layer in widget.map.layers.whereType<TileLayer>())
          for (final entry in layer.palette) entry.tilesetId,
      };
      for (final tile in project.tilesets.where(
        (tile) => ids.contains(tile.id),
      )) {
        choices['ground:${tile.id}'] = (
          'Sol · ${tile.name}',
          SpatialAtmosphereMaterialTarget.groundTileset(tile.id),
        );
      }
    }
    for (final instance
        in widget.map.spatialScene?.instances ?? <SpatialModelInstance>[]) {
      final model = project.models3d
          .where((model) => model.id == instance.modelId)
          .firstOrNull;
      if (model == null) continue;
      for (final material in model.inspection.materials) {
        choices['${instance.id}:${material.name}'] = (
          '${model.name} · ${material.name} · ${instance.id}',
          SpatialAtmosphereMaterialTarget(
            instanceId: instance.id,
            materialName: material.name,
          ),
        );
      }
    }
    return choices;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final settings = controller.current;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Effets visuels',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Réglez chaque effet ici. L’aperçu se met à jour immédiatement.',
          ),
          const SizedBox(height: 12),
          if (widget.showSaveActions) ...[
            StudioBadge(
              controller.saving
                  ? 'Enregistrement…'
                  : controller.dirty
                  ? 'Modifications à enregistrer'
                  : 'Enregistré',
              tone: controller.dirty ? StudioTone.warning : StudioTone.success,
              icon: controller.dirty
                  ? Icons.edit_outlined
                  : Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            if (controller.error case final message?)
              Text(message, key: const ValueKey('atmosphere-error')),
            Text(
              controller.saving
                  ? 'Enregistrement de l’ambiance…'
                  : controller.dirty
                  ? 'Ambiance modifiée'
                  : 'Ambiance enregistrée',
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StudioButton(
                  key: const ValueKey('atmosphere-save'),
                  label: 'Enregistrer l’ambiance',
                  loading: controller.saving,
                  onPressed: controller.dirty && !controller.saving
                      ? controller.save
                      : null,
                ),
                StudioButton(
                  key: const ValueKey('atmosphere-undo'),
                  label: 'Annuler l’ambiance',
                  secondary: true,
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                StudioButton(
                  key: const ValueKey('atmosphere-redo'),
                  label: 'Rétablir l’ambiance',
                  secondary: true,
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          StudioPanel(
            compact: true,
            accent: StudioAccent.halo,
            children: [
              StudioToggleRow(
                key: const ValueKey('atmosphere-halos-enabled'),
                icon: Icons.flare_rounded,
                accent: StudioAccent.halo,
                label: 'Halos lumineux',
                value: settings.halosEnabled,
                description: settings.halos.isEmpty
                    ? 'Ajoutez une source lumineuse ci-dessous.'
                    : 'Une diffusion douce autour des sources, le soir.',
                onChanged: settings.halos.isEmpty
                    ? null
                    : (value) => controller.edit(
                        settings.copyWith(halosEnabled: value),
                      ),
              ),
              _number(
                'halo-strength',
                'Intensité des halos',
                settings.haloStrength,
                2,
                (v) => settings.copyWith(haloStrength: v),
              ),
              _number(
                'halo-spread',
                'Diffusion des halos',
                settings.haloSpread,
                3,
                (v) => settings.copyWith(haloSpread: v),
              ),
              StudioSection(
                key: const ValueKey('atmosphere-halos-sources'),
                title: 'Sources lumineuses · ${settings.halos.length}',
                collapsible: true,
                initiallyExpanded: false,
                onExpansionChanged: _expandSources,
                children: [
                  ?_haloPicker,
                  if (settings.halos.isNotEmpty) ..._haloControls(settings),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          StudioPanel(
            compact: true,
            accent: StudioAccent.fog,
            children: [
              StudioToggleRow(
                key: const ValueKey('atmosphere-fog-enabled'),
                icon: Icons.cloud_outlined,
                accent: StudioAccent.fog,
                label: 'Brume en profondeur',
                value: settings.depthFogEnabled,
                description: 'Adoucit le décor éloigné tout en gardant le premier plan net.',
                onChanged: (value) =>
                    controller.edit(settings.copyWith(depthFogEnabled: value)),
              ),
              _number(
                'fog-opacity',
                'Opacité de la brume (%)',
                settings.fogOpacity * 100,
                50,
                (v) => settings.copyWith(fogOpacity: v / 100),
              ),
              _number(
                'fog-start',
                'Distance de début de la brume',
                settings.fogStart,
                100000,
                (v) => settings.copyWith(fogStart: v),
              ),
              _number(
                'fog-end',
                'Distance de fin de la brume',
                settings.fogEnd,
                100000,
                (v) => settings.copyWith(fogEnd: v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StudioPanel(
            compact: true,
            accent: StudioAccent.window,
            children: [
              StudioToggleRow(
                key: const ValueKey('atmosphere-windows-enabled'),
                icon: Icons.window_outlined,
                accent: StudioAccent.window,
                label: 'Fenêtres éclairées',
                value: settings.windowsLit,
                description: settings.windows.isEmpty
                    ? 'Choisissez le matériau des vitrages ci-dessous.'
                    : '${settings.windows.length} vitrage(s), éclairés le soir.',
                onChanged: settings.windows.isEmpty
                    ? null
                    : (enabled) => controller.edit(
                        settings.copyWith(windowsLit: enabled),
                      ),
              ),
              _number(
                'window-strength',
                'Intensité des fenêtres',
                settings.windowStrength,
                2,
                (value) => settings.copyWith(windowStrength: value),
              ),
              StudioSection(
                key: const ValueKey('atmosphere-windows-sources'),
                title: 'Vitrages · ${settings.windows.length}',
                collapsible: true,
                initiallyExpanded: false,
                onExpansionChanged: _expandSources,
                children: [
                  if (_windowPicker case final picker?) ...[
                    const Text(
                      'Choisissez un matériau réservé au vitrage. Les masques déjà configurés restent conservés.',
                    ),
                    picker,
                  ],
                  for (var index = 0; index < settings.windows.length; index++)
                    StudioButton(
                      label:
                          'Retirer le vitrage · ${settings.windows[index].target.materialName}',
                      secondary: true,
                      onPressed: () => controller.edit(
                        settings.copyWith(
                          windows: [...settings.windows]..removeAt(index),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          StudioPanel(
            compact: true,
            accent: StudioAccent.firefly,
            children: [
              StudioToggleRow(
                key: const ValueKey('atmosphere-fireflies-enabled'),
                icon: Icons.auto_awesome_outlined,
                accent: StudioAccent.firefly,
                label: 'Lucioles le soir',
                value: settings.fireflies,
                description: settings.fireflyZones.isEmpty
                    ? 'Ajoutez une zone de lucioles ci-dessous.'
                    : '${settings.fireflyZones.length} zone(s), visibles à la tombée du jour.',
                onChanged: settings.fireflyZones.isEmpty
                    ? null
                    : (enabled) => controller.edit(
                        settings.copyWith(fireflies: enabled),
                      ),
              ),
              _number(
                'firefly-density',
                'Densité des lucioles',
                settings.fireflyDensity,
                2,
                (value) => settings.copyWith(fireflyDensity: value),
              ),
              StudioSection(
                key: const ValueKey('atmosphere-fireflies-sources'),
                title: 'Zones de lucioles · ${settings.fireflyZones.length}',
                collapsible: true,
                initiallyExpanded: false,
                onExpansionChanged: _expandSources,
                children: [
                  if (settings.fireflyZones.isEmpty)
                    StudioButton(
                      key: const ValueKey('atmosphere-add-firefly-zone'),
                      label: 'Ajouter une zone de lucioles',
                      secondary: true,
                      onPressed: () => controller.edit(
                        settings.copyWith(
                          fireflyZones: [
                            SpatialAtmosphereFireflyZone(
                              bounds: Model3dBounds(
                                min: Model3dVector3(x: 0, y: .2, z: 0),
                                max: Model3dVector3(
                                  x: widget.map.size.width.toDouble(),
                                  y: 2.2,
                                  z: widget.map.size.height.toDouble(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (
                    var index = 0;
                    index < settings.fireflyZones.length;
                    index++
                  ) ...[
                    const SizedBox(height: 8),
                    Text('Zone de lucioles ${index + 1}'),
                    for (final (axis, edge, value) in [
                      ('x', 'min', settings.fireflyZones[index].bounds.min.x),
                      ('x', 'max', settings.fireflyZones[index].bounds.max.x),
                      ('z', 'min', settings.fireflyZones[index].bounds.min.z),
                      ('z', 'max', settings.fireflyZones[index].bounds.max.z),
                    ])
                      StudioCommitField(
                        key: ValueKey('atmosphere-zone-$index-$axis-$edge'),
                        label:
                            '${axis == 'x' ? 'Horizontal' : 'Profondeur'} · ${edge == 'min' ? 'début' : 'fin'}',
                        value: '$value',
                        tryCommit: (text) => _zone(index, axis, edge, text),
                      ),
                    StudioButton(
                      label: 'Retirer la zone ${index + 1}',
                      secondary: true,
                      onPressed: () => controller.edit(
                        settings.copyWith(
                          fireflyZones: [...settings.fireflyZones]
                            ..removeAt(index),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          StudioPanel(
            compact: true,
            accent: StudioAccent.water,
            children: [
              StudioToggleRow(
                key: const ValueKey('atmosphere-water-enabled'),
                icon: Icons.waves_rounded,
                accent: StudioAccent.water,
                label: 'Eau animée',
                value: settings.waterAnimated,
                description: settings.waterTargets.isEmpty
                    ? 'Choisissez une surface d’eau ci-dessous.'
                    : '${settings.waterTargets.length} surface(s) d’eau configurée(s).',
                onChanged: settings.waterTargets.isEmpty
                    ? null
                    : (enabled) => controller.edit(
                        settings.copyWith(waterAnimated: enabled),
                      ),
              ),
              _number(
                'water-strength',
                'Intensité des reflets',
                settings.waterStrength,
                2,
                (value) => settings.copyWith(waterStrength: value),
              ),
              _number(
                'water-speed',
                'Vitesse de l’eau',
                settings.waterSpeed,
                3,
                (value) => settings.copyWith(waterSpeed: value),
              ),
              StudioSection(
                key: const ValueKey('atmosphere-water-sources'),
                title: 'Surfaces d’eau · ${settings.waterTargets.length}',
                collapsible: true,
                initiallyExpanded: false,
                onExpansionChanged: _expandSources,
                children: [
                  ?_waterPicker,
                  for (
                    var index = 0;
                    index < settings.waterTargets.length;
                    index++
                  )
                    StudioButton(
                      label:
                          'Retirer l’eau · ${settings.waterTargets[index].materialName}',
                      secondary: true,
                      onPressed: () => controller.edit(
                        settings.copyWith(
                          waterTargets: [...settings.waterTargets]
                            ..removeAt(index),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    },
  );

  bool _zone(int index, String axis, String edge, String text) {
    final number = double.tryParse(text.trim().replaceAll(',', '.'));
    final limit = axis == 'x' ? widget.map.size.width : widget.map.size.height;
    if (number == null || !number.isFinite || number < 0 || number > limit) {
      controller.reject('La zone doit rester dans la carte (0–$limit).');
      return false;
    }
    final settings = controller.current;
    final old = settings.fireflyZones[index];
    final min = old.bounds.min, max = old.bounds.max;
    final nextMin = Model3dVector3(
      x: axis == 'x' && edge == 'min' ? number : min.x,
      y: min.y,
      z: axis == 'z' && edge == 'min' ? number : min.z,
    );
    final nextMax = Model3dVector3(
      x: axis == 'x' && edge == 'max' ? number : max.x,
      y: max.y,
      z: axis == 'z' && edge == 'max' ? number : max.z,
    );
    if (nextMin.x >= nextMax.x || nextMin.z >= nextMax.z) {
      controller.reject('La fin de la zone doit se trouver après son début.');
      return false;
    }
    final zones = [...settings.fireflyZones];
    zones[index] = SpatialAtmosphereFireflyZone(
      bounds: Model3dBounds(min: nextMin, max: nextMax),
      count: old.count,
      seed: old.seed,
    );
    controller.edit(settings.copyWith(fireflyZones: zones));
    return true;
  }

  List<Widget> _haloControls(SpatialAtmosphereSettings settings) {
    final index = _haloIndex.clamp(0, settings.halos.length - 1);
    final source = settings.halos[index];
    void replace(SpatialAtmosphereHalo next) => controller.edit(
      settings.copyWith(halos: [...settings.halos]..[index] = next),
    );
    SpatialAtmosphereHalo update({Model3dVector3? position, bool? window}) =>
        SpatialAtmosphereHalo(
          instanceId: source.instanceId,
          localPosition: position ?? source.localPosition,
          radiusX: source.radiusX,
          radiusY: source.radiusY,
          opacity: source.opacity,
          colorRgb: source.colorRgb,
          window: window ?? source.window,
        );
    return [
      StudioSelect(
        key: const ValueKey('atmosphere-halo-selection'),
        label: 'Halo à ajuster',
        value: '$index',
        options: {
          for (var i = 0; i < settings.halos.length; i++)
            '$i':
                '${i + 1} · ${_haloChoices[settings.halos[i].instanceId]?.$1 ?? 'Objet absent'}',
        },
        onChanged: (i) => setState(() => _haloIndex = int.parse(i)),
      ),
      const Text(
        'Le halo suit cet objet. Ajustez sa position autour de la partie lumineuse.',
      ),
      for (final (axis, label, value) in [
        ('x', 'Horizontal', source.localPosition.x),
        ('y', 'Hauteur', source.localPosition.y),
        ('z', 'Profondeur', source.localPosition.z),
      ])
        StudioCommitField(
          key: ValueKey('atmosphere-halo-$index-$axis'),
          label: label,
          value: '$value',
          tryCommit: (text) {
            final v = double.tryParse(text.trim().replaceAll(',', '.'));
            if (v == null || !v.isFinite || v.abs() > 100000) {
              controller.reject('Choisissez une position valide.');
              return false;
            }
            final p = source.localPosition;
            replace(
              update(
                position: Model3dVector3(
                  x: axis == 'x' ? v : p.x,
                  y: axis == 'y' ? v : p.y,
                  z: axis == 'z' ? v : p.z,
                ),
              ),
            );
            return true;
          },
        ),
      StudioToggleRow(
        label: 'Suivre l’éclairage des fenêtres',
        value: source.window,
        onChanged: (v) => replace(update(window: v)),
      ),
      StudioButton(
        label: 'Retirer ce halo',
        secondary: true,
        onPressed: () => controller.edit(
          settings.copyWith(halos: [...settings.halos]..removeAt(index)),
        ),
      ),
    ];
  }
}
