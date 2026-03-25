/// Migration douce du format JSON : ancienne clé `source` (un seul [TilesetSourceRect])
/// vers `frames` (liste ordonnée d’au moins une entrée).
///
/// Utilisé au chargement pour [ProjectElementEntry], [TilesetPaletteEntry],
/// [TerrainPresetVariant] et [PathPresetVariantMapping].
Map<String, dynamic> jsonCoerceLegacySourceToFrames(Map<String, dynamic> json) {
  final m = Map<String, dynamic>.from(json);
  final frames = m['frames'];
  if (frames is! List || frames.isEmpty) {
    final src = m['source'];
    if (src is Map<String, dynamic>) {
      m['frames'] = <Object>[
        <String, dynamic>{'source': src},
      ];
    }
  }
  m.remove('source');
  return m;
}
