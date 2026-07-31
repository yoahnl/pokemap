const String _fallbackWorldMapRejectionMessage =
    'Cette action est indisponible dans le contexte actuel.';

const Map<String, String> _translatedWorldMapRejectionMessages =
    <String, String>{
  'Select an active map before choosing an editing tool.':
      'Sélectionnez une carte active avant de choisir un outil.',
  'Place/object requires an active editable tile layer.':
      'Sélectionnez un calque de tuiles modifiable pour placer cet objet.',
  'The active layer cannot be erased.':
      'Le calque actif ne peut pas être effacé.',
  'Paint/tile requires an active editable tile layer.':
      'Sélectionnez un calque de tuiles modifiable pour peindre des éléments.',
  'Paint/terrain requires an active terrain layer.':
      'Sélectionnez un calque de terrain pour peindre le terrain.',
  'Paint/path requires an active path layer.':
      'Sélectionnez un calque de chemins pour peindre un chemin.',
  'Paint/surface requires an active surface layer.':
      'Sélectionnez un calque de surfaces pour peindre une surface.',
  'Paint/collision requires an active collision layer.':
      'Sélectionnez un calque de collisions pour peindre les collisions.',
  'Select an available surface before painting.':
      'Sélectionnez une surface disponible avant de peindre.',
  'No active map selected.': 'Sélectionnez une carte active.',
};

const Set<String> _approvedFrenchWorldMapRejectionMessages = <String>{
  'L’outil Bordures nécessite un calque de bordures actif.',
  'Sélectionnez un calque Bordures.',
  'Le calque actif doit être un calque Bordures.',
  'Sélectionnez ou créez une bordure dans ce calque.',
  'La bordure sélectionnée n’existe plus.',
  'Le blueprint utilisé par cette bordure est obsolète.',
  'Publiez le blueprint utilisé par cette bordure.',
  'La géométrie de la bordure ne correspond pas à son blueprint.',
  'Ce type de bordure ne peut pas encore être dessiné.',
  'Le projet est en mode Event Builder V2 uniquement. '
      'Les anciens MapEvents doivent être modifiés depuis la migration '
      'ou l’Event Builder V2.',
  'La cible n’existe plus sur la carte active.',
  'Suppression annulée : la carte ou la cible a changé.',
  'Déplacement indisponible.',
  'Impossible d’exécuter cette action. Réessayez.',
  'L’Event Builder n’est pas encore disponible. '
      'Réessayez après son chargement.',
  'Aucune entrée de compatibilité ne correspond à ce MapEvent. '
      'Vérifiez la migration dans l’Event Builder.',
  'Plusieurs entrées de compatibilité correspondent à ce '
      'MapEvent. Vérifiez la migration avant de continuer.',
  'L’entrée de compatibilité de ce MapEvent est invalide. '
      'Vérifiez la migration dans l’Event Builder.',
  'La création de projet est indisponible.',
  'L’ouverture de projet est indisponible.',
  'Ouvrez un projet.',
  'Ouvrez un projet enregistré.',
  'Ouvrez une carte.',
};

/// Converts internal World Map rejection diagnostics into approved French UI
/// copy. Unknown diagnostics deliberately collapse to a generic message so
/// identifiers and implementation details never leak into user-facing UI.
String? projectWorldMapRejectionMessageFr(String? technicalReason) {
  if (technicalReason == null) return null;
  final normalized = technicalReason.trim();
  if (normalized.isEmpty) return _fallbackWorldMapRejectionMessage;
  final translated = _translatedWorldMapRejectionMessages[normalized];
  if (translated != null) return translated;
  if (normalized.startsWith('Layer not found:')) {
    return 'Le calque demandé est introuvable.';
  }
  if (_approvedFrenchWorldMapRejectionMessages.contains(normalized)) {
    return normalized;
  }
  return _fallbackWorldMapRejectionMessage;
}
