import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart' hide SpatialMapOperations;

import 'editable_map_document.dart';

class SpatialLedgeEditingCommands {
  SpatialLedgeEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;

  bool configure(List<SpatialLedge> ledges) {
    if (document.saving) return false;
    try {
      final map = document.current;
      document.commit(
        const SpatialMapOperations().configureNavigation(
          map,
          map.spatialScene!.navigation.copyWith(ledges: ledges),
          models: project.models3d,
        ),
      );
      document.error = null;
      return true;
    } on FormatException {
      document.error = 'Le départ et l’arrivée doivent rester dans la carte. Un talus ne permet pas de monter. Vérifiez aussi la durée et la hauteur du saut.';
      return false;
    }
  }

  bool editText(
    SpatialLedge selected,
    List<SpatialLedge> ledges,
    String key,
    String text,
  ) {
    if (document.saving) return false;
    final value = key == 'height'
        ? double.tryParse(text.replaceAll(',', '.'))
        : int.tryParse(text);
    return value != null && edit(selected, ledges, key, value);
  }

  bool edit(
    SpatialLedge selected,
    List<SpatialLedge> ledges,
    String key,
    Object value,
  ) {
    try {
      final next = SpatialLedge.fromJson({...selected.toJson(), key: value});
      return configure([
        for (final ledge in ledges)
          if (ledge.id == next.id) next else ledge,
      ]);
    } on Object {
      document.error = 'Choisissez des coordonnées entières, une distance de 2 à 4 cases, une durée de 100 à 2000 ms et une hauteur de 0 à 4 cases.';
      return false;
    }
  }

  SpatialLedge next() {
    final scene = document.current.spatialScene!;
    final ledges = scene.navigation.ledges;
    var number = 1;
    while (ledges.any((ledge) => ledge.id == 'ledge-$number')) {
      number++;
    }
    final x = scene.navigation.spawn.x.floor();
    final z = scene.navigation.spawn.z.floor();
    final direction = z + 2 < scene.depth
        ? SpatialRampDirection.south
        : SpatialRampDirection.north;
    return SpatialLedge(id: 'ledge-$number', x: x, z: z, direction: direction);
  }
}
