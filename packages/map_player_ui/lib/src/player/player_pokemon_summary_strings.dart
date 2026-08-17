import 'package:flutter/widgets.dart';

/// Libellés de la fiche Pokémon partagée.
///
/// L'Équipe et le PC portaient chacun leur propre copie de ces libellés, avec
/// des divergences invisibles en test. Ils vivent ici en un seul exemplaire,
/// suivant le même motif que [PlayerPcStrings] en attendant la migration vers
/// le catalogue généré.
final class PlayerPokemonSummaryStrings {
  const PlayerPokemonSummaryStrings._(this._languageCode);

  factory PlayerPokemonSummaryStrings.of(BuildContext context) =>
      PlayerPokemonSummaryStrings._(
        Localizations.localeOf(context).languageCode,
      );

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String levelValue(int level) => _isFrench ? 'Niv. $level' : 'Lv. $level';
  String hpValue(int current, int max) => '$current/$max';
  String ppValue(int current, int max) =>
      _isFrench ? 'PP $current/$max' : 'PP $current/$max';
  String friendshipValue(int friendship) => '$friendship/255';

  String get hp => _isFrench ? 'PV' : 'HP';
  String get ppUnavailable => '—';
  String get species => _isFrench ? 'Espèce' : 'Species';
  String get form => _isFrench ? 'Forme' : 'Form';
  String get experience => _isFrench ? 'Expérience' : 'Experience';
  String get nature => _isFrench ? 'Nature' : 'Nature';
  String get ability => _isFrench ? 'Talent' : 'Ability';
  String get gender => _isFrench ? 'Sexe' : 'Gender';
  String get shiny => _isFrench ? 'Chromatique' : 'Shiny';
  String get heldItem => _isFrench ? 'Objet tenu' : 'Held item';
  String get friendship => _isFrench ? 'Amitié' : 'Friendship';
  String get stats => _isFrench ? 'Statistiques' : 'Stats';
  String get attack => _isFrench ? 'Attaque' : 'Attack';
  String get defense => _isFrench ? 'Défense' : 'Defense';
  String get specialAttack => _isFrench ? 'Attaque Spé.' : 'Sp. Attack';
  String get specialDefense => _isFrench ? 'Défense Spé.' : 'Sp. Defense';
  String get speed => _isFrench ? 'Vitesse' : 'Speed';
  String get moves => _isFrench ? 'Capacités' : 'Moves';
  String get provenance => _isFrench ? 'Provenance' : 'Origin';
  String get origin => _isFrench ? 'Origine' : 'Origin';
  String get metLocation => _isFrench ? 'Lieu de rencontre' : 'Met location';
  String get metSource => _isFrench ? 'Source' : 'Source';
  String get metLevel => _isFrench ? 'Niveau de rencontre' : 'Met level';
  String get captureBall => _isFrench ? 'Ball de capture' : 'Capture Ball';
  String get none => _isFrench ? 'Aucun' : 'None';
  String get viewSummary => _isFrench ? 'Voir la fiche' : 'View summary';
  String get close => _isFrench ? 'Fermer' : 'Close';
}
