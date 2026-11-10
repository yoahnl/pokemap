import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';

class MapDecorAnimationCommands {
  const MapDecorAnimationCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;

  ProjectElementEntry? get definition => project.elements
      .where((entry) => entry.id == document.selected?.elementId)
      .firstOrNull;

  List<int> get durations => normalizeElementFrameDurationsMs(
    definition?.frames.map((frame) => frame.durationMs).toList() ?? const [],
  );

  int get idleFrame {
    final selected = document.selected;
    if (selected == null) return 0;
    return resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: durations,
      elapsedMs: 0,
      animation: (selected.animation ?? const MapPlacedElementAnimation())
          .copyWith(autoplay: false),
      deterministicSeed: stableHash32(selected.id),
    );
  }

  Iterable<(int, MapPlacedElementBehavior)> get behaviors =>
      (document.selected?.behaviors ?? const <MapPlacedElementBehavior>[])
          .indexed
          .where(
            (entry) =>
                entry.$2.effect.type ==
                    MapPlacedElementEffectType.setAnimationEnabled ||
                entry.$2.effect.type ==
                    MapPlacedElementEffectType.playAnimationOnce,
          );

  bool animation(MapPlacedElementAnimation value) {
    final selected = document.selected;
    if (selected == null) return false;
    document.commit(
      setMapPlacedElementAnimation(
        document.current,
        instanceId: selected.id,
        animation: value,
      ),
    );
    return true;
  }

  bool idleImage(int index) {
    if (document.selected == null ||
        index < 0 ||
        index >= (definition?.frames.length ?? 0)) {
      return false;
    }
    final current =
        document.selected!.animation ?? const MapPlacedElementAnimation();
    final offset = durations
        .take(index)
        .fold<int>(0, (sum, duration) => sum + duration);
    return animation(
      current.copyWith(
        enabled: true,
        mode: current.mode == MapPlacedElementAnimationMode.none
            ? MapPlacedElementAnimationMode.loop
            : current.mode,
        autoplay: false,
        randomStart: false,
        startOffsetMs: offset.toDouble(),
      ),
    );
  }

  bool speed(String text) {
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0) return false;
    return animation(
      (document.selected?.animation ?? const MapPlacedElementAnimation())
          .copyWith(speed: value),
    );
  }

  bool setBehaviorEnabled(int index, bool enabled) => _behavior(
    (map, id) => setMapPlacedElementBehaviorEnabledAt(
      map,
      instanceId: id,
      behaviorIndex: index,
      enabled: enabled,
    ),
  );

  bool removeBehavior(int index) => _behavior(
    (map, id) => removeMapPlacedElementBehaviorAt(
      map,
      instanceId: id,
      behaviorIndex: index,
    ),
  );

  bool addBehavior(MapPlacedElementTriggerType trigger, String effect) =>
      _behavior(
        (map, id) => addMapPlacedElementBehavior(
          map,
          instanceId: id,
          behavior: MapPlacedElementBehavior(
            trigger: trigger,
            effect: MapPlacedElementEffect(
              type: effect == 'once'
                  ? MapPlacedElementEffectType.playAnimationOnce
                  : MapPlacedElementEffectType.setAnimationEnabled,
              animationEnabled: effect == 'once' ? null : effect == 'start',
            ),
          ),
        ),
      );

  bool _behavior(MapData Function(MapData, String) update) {
    final selected = document.selected;
    if (selected == null) return false;
    document.commit(update(document.current, selected.id));
    return true;
  }
}

String mapDecorTriggerLabel(MapPlacedElementTriggerType trigger) =>
    switch (trigger) {
      MapPlacedElementTriggerType.onAction => 'À l’interaction',
      MapPlacedElementTriggerType.onEnter => 'À l’entrée',
      MapPlacedElementTriggerType.onBump => 'Au contact',
      MapPlacedElementTriggerType.onExit => 'À la sortie',
      MapPlacedElementTriggerType.onNear => 'À proximité',
    };

String mapDecorEffectLabel(MapPlacedElementEffect effect) =>
    switch (effect.type) {
      MapPlacedElementEffectType.playAnimationOnce => 'Jouer une fois',
      MapPlacedElementEffectType.setAnimationEnabled =>
        effect.animationEnabled == true ? 'Activer' : 'Arrêter',
      _ => 'Autre effet',
    };
