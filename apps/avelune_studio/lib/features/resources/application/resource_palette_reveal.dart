import 'resource_catalog.dart';

typedef ResourcePaletteReveal = ({String? tab});

ResourcePaletteReveal? resourcePaletteReveal(ResourceItem item) {
  if (item.terrain != null) return (tab: null);
  if (item.border != null) return (tab: 'Bordures');
  if (item.tileset == null && item.character == null) return (tab: 'Décors');
  return null;
}
