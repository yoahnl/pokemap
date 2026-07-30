import 'package:map_core/map_core.dart';

String elementPresetLabel(ElementPresetKind kind) {
  return switch (kind) {
    ElementPresetKind.generic => 'Générique',
    ElementPresetKind.tree => 'Arbre',
    ElementPresetKind.building => 'Bâtiment',
    ElementPresetKind.rock => 'Roche',
    ElementPresetKind.cliff => 'Falaise',
    ElementPresetKind.tallDecoration => 'Grande déco',
  };
}
