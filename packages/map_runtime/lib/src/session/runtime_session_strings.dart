final class RuntimeSessionStrings {
  RuntimeSessionStrings.forLocale(String locale)
      : _isFrench = locale == 'fr' ||
            locale.startsWith('fr-') ||
            locale.startsWith('fr_');

  final bool _isFrench;

  String get noWorldService => _isFrench
      ? 'Aucun service contextuel n’est actif.'
      : 'No contextual world service is active.';
  String get bagUnavailable =>
      _isFrench ? 'Le sac n’est pas disponible.' : 'The bag is unavailable.';
}
