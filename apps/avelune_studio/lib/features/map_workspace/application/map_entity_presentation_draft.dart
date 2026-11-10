import 'package:map_core/map_core_domain.dart';

class MapEntityPresentationDraft {
  const MapEntityPresentationDraft(this.map, this.entity);
  final MapData map;
  final MapEntity entity;
  List<MapEntityPresentationVariant> get variants =>
      entity.presentation?.variants ?? const [];
  bool get canEdit =>
      const [MapEntityKind.custom, MapEntityKind.npc].contains(entity.kind) &&
      entity.fieldObstacle == null &&
      entity.healingDisplay == null &&
      entity.interactiveEncounter == null;

  MapEntityPresentation replace(int index, Map<String, dynamic> changes) {
    try {
      if (changes.containsKey('characterId') &&
          changes['characterId'] == null) {
        changes = {
          ...changes,
          'movement': const MapEntityNpcMovementConfig().toJson(),
          'startsOnNpcContact': false,
        };
      }
      if (changes['blocksMovement'] == false) {
        changes = {...changes, 'startsOnNpcContact': false};
      }
      final next = [...variants];
      next[index] = MapEntityPresentationVariant.fromJson({
        ...next[index].toJson(),
        ...changes,
      });
      return MapEntityPresentation(variants: next);
    } on Object {
      throw const FormatException(
        'Cette variante contient une condition ou une valeur non valide.',
      );
    }
  }

  MapEntityPresentation resize(int index, String text, {required bool width}) {
    final size = variants[index].size;
    final number = int.tryParse(text);
    if (number == null ||
        number < 1 ||
        number > 64 ||
        (width
            ? entity.pos.x + number > map.size.width
            : entity.pos.y + number > map.size.height)) {
      throw const FormatException(
        'Choisissez une taille de 1 à 64 cases qui reste dans la carte.',
      );
    }
    return replace(index, {
      'size': {
        'width': width ? number : size.width,
        'height': width ? size.height : number,
      },
    });
  }

  MapEntityPresentation promote(int index) {
    final next = [...variants];
    final value = next.removeAt(index);
    next.insert(index - 1, value);
    return MapEntityPresentation(variants: next);
  }

  MapEntityPresentation? remove(int index) {
    final next = [...variants]..removeAt(index);
    return next.isEmpty ? null : MapEntityPresentation(variants: next);
  }

  MapEntityPresentation add() {
    var suffix = variants.length + 1;
    while (variants.any((variant) => variant.id == 'variant_$suffix')) {
      suffix++;
    }
    return MapEntityPresentation(
      variants: [
        ...variants,
        MapEntityPresentationVariant(
          id: 'variant_$suffix',
          condition: NarrativeEventConditionExpression.all(const []),
          characterId: entity.npc?.characterId,
          facing: entity.npc?.facing ?? EntityFacing.south,
          movement: entity.npc?.movement.mode == MapEntityNpcMovementMode.patrol
              ? const MapEntityNpcMovementConfig()
              : entity.npc?.movement ?? const MapEntityNpcMovementConfig(),
          blocksMovement: entity.blocksMovement,
          size: entity.size,
          interactionMode: entity.interactionMode,
          counterInteractionSides: entity.counterInteractionSides.isNotEmpty
              ? entity.counterInteractionSides
              : entity.npc?.counterInteractionSides ?? const [],
        ),
      ],
    );
  }
}
