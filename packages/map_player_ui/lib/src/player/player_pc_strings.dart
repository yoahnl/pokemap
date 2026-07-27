import 'package:flutter/widgets.dart';

/// Small, PC-scoped localization surface.
///
/// The PC overlay predates the generated player localization catalogue. New
/// PC copy stays localized here until the overlay is migrated as a whole.
final class PlayerPcStrings {
  const PlayerPcStrings._(this._languageCode);

  factory PlayerPcStrings.of(BuildContext context) =>
      PlayerPcStrings._(Localizations.localeOf(context).languageCode);

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String summaryTitle(String pokemon) =>
      _isFrench ? 'Résumé de $pokemon' : '$pokemon summary';

  String get summaryTooltip => _isFrench ? 'Voir le résumé' : 'View summary';
  String get swapTooltip => _isFrench ? 'Échanger' : 'Swap';
  String get close => _isFrench ? 'Fermer' : 'Close';
  String get species => _isFrench ? 'Espèce' : 'Species';
  String get level => _isFrench ? 'Niveau' : 'Level';
  String get currentHp => _isFrench ? 'PV actuels' : 'Current HP';
  String get nature => 'Nature';
  String get ability => _isFrench ? 'Talent' : 'Ability';
  String get gender => _isFrench ? 'Genre' : 'Gender';
  String get status => _isFrench ? 'Statut' : 'Status';
  String get shiny => _isFrench ? 'Chromatique' : 'Shiny';
  String get heldItem => _isFrench ? 'Objet tenu' : 'Held item';
  String get moves => _isFrench ? 'Capacités' : 'Moves';
  String get nickname => _isFrench ? 'Surnom' : 'Nickname';
  String get friendship => _isFrench ? 'Amitié' : 'Friendship';
  String get origin => _isFrench ? 'Origine' : 'Origin';
  String get metLocation => _isFrench ? 'Lieu de rencontre' : 'Met location';
  String get metSource => _isFrench ? 'Source' : 'Source';
  String get metLevel => _isFrench ? 'Niveau rencontré' : 'Met level';
  String get captureBall => _isFrench ? 'Ball de capture' : 'Capture Ball';
  String get none => _isFrench ? 'Aucun' : 'None';
  String get yes => _isFrench ? 'Oui' : 'Yes';
  String get no => _isFrench ? 'Non' : 'No';

  String originLabel(String origin) => switch (origin) {
        'captured' => _isFrench ? 'Capturé' : 'Captured',
        'gift' => _isFrench ? 'Cadeau' : 'Gift',
        'starter' => _isFrench ? 'Starter' : 'Starter',
        'trade' => _isFrench ? 'Échange' : 'Trade',
        'scripted' => _isFrench ? 'Événement' : 'Event',
        _ => _isFrench ? 'Inconnue' : 'Unknown',
      };

  String swapWith(String pokemon) =>
      _isFrench ? 'Échanger avec $pokemon' : 'Swap with $pokemon';
}
