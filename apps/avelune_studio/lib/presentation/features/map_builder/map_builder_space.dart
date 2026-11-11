import 'package:map_core/map_core.dart';

enum MapBuilderSpace {
  construction('Construction'),
  gameplay('Jeu'),
  story('Scénario'),
  ambiance('Ambiance');

  const MapBuilderSpace(this.label);

  final String label;
}

String mapRoleLabel(MapRole role) => switch (role) {
  MapRole.exterior => 'Extérieur',
  MapRole.interior => 'Intérieur',
  MapRole.basement => 'Sous-sol',
  MapRole.upper_floor => 'Étage',
  MapRole.connector => 'Liaison',
  MapRole.gate => 'Poste-frontière',
  MapRole.room => 'Pièce',
  MapRole.section => 'Section',
  MapRole.sub_area => 'Sous-zone',
};
