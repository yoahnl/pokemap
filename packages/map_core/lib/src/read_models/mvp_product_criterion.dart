import 'project_gameplay_readiness.dart';

/// The product-level MVP contract shared by Selbrume verification and FG-180.
enum MvpProductCriterion {
  mvp01NewGame,
  mvp02Starter,
  mvp03ConnectedExploration,
  mvp04NpcDialogue,
  mvp05ConditionalDialogue,
  mvp06Cutscene,
  mvp07WildEncounter,
  mvp08Capture,
  mvp09PcOverflow,
  mvp10TrainerBattle,
  mvp11ExperienceAndMoney,
  mvp12LevelUp,
  mvp13MoveLearning,
  mvp14BadgeOrFlag,
  mvp15FieldAbility,
  mvp16Shop,
  mvp17HealCenter,
  mvp18SaveLoad,
  mvp19StoryEnd,
}

extension MvpProductCriterionContract on MvpProductCriterion {
  String get id => 'MVP-${(index + 1).toString().padLeft(2, '0')}';

  String get label => switch (this) {
        MvpProductCriterion.mvp01NewGame => 'Créer une nouvelle partie',
        MvpProductCriterion.mvp02Starter => 'Choisir un starter',
        MvpProductCriterion.mvp03ConnectedExploration =>
          'Explorer des maps connectées',
        MvpProductCriterion.mvp04NpcDialogue => 'Parler à des PNJ',
        MvpProductCriterion.mvp05ConditionalDialogue =>
          'Jouer des dialogues conditionnels',
        MvpProductCriterion.mvp06Cutscene => 'Déclencher une cutscene simple',
        MvpProductCriterion.mvp07WildEncounter =>
          'Déclencher une rencontre sauvage',
        MvpProductCriterion.mvp08Capture => 'Capturer un Pokémon',
        MvpProductCriterion.mvp09PcOverflow =>
          'Envoyer une capture au PC si la party est pleine',
        MvpProductCriterion.mvp10TrainerBattle => 'Combattre un dresseur',
        MvpProductCriterion.mvp11ExperienceAndMoney =>
          'Gagner expérience et argent',
        MvpProductCriterion.mvp12LevelUp => 'Gagner un niveau',
        MvpProductCriterion.mvp13MoveLearning => 'Apprendre une attaque',
        MvpProductCriterion.mvp14BadgeOrFlag => 'Obtenir un badge ou un flag',
        MvpProductCriterion.mvp15FieldAbility =>
          'Débloquer une capacité de terrain',
        MvpProductCriterion.mvp16Shop => 'Utiliser une boutique',
        MvpProductCriterion.mvp17HealCenter => 'Soigner son équipe',
        MvpProductCriterion.mvp18SaveLoad => 'Sauvegarder et charger',
        MvpProductCriterion.mvp19StoryEnd => 'Finir une mini-histoire',
      };

  /// Explicit many-to-one bridge from the 19 product outcomes to FG-180.
  ProjectGameplayReadinessCheck get readinessCheck => switch (this) {
        MvpProductCriterion.mvp01NewGame ||
        MvpProductCriterion.mvp18SaveLoad =>
          ProjectGameplayReadinessCheck.startState,
        MvpProductCriterion.mvp02Starter =>
          ProjectGameplayReadinessCheck.starterConfiguration,
        MvpProductCriterion.mvp03ConnectedExploration ||
        MvpProductCriterion.mvp09PcOverflow ||
        MvpProductCriterion.mvp17HealCenter =>
          ProjectGameplayReadinessCheck.playablePartyPath,
        MvpProductCriterion.mvp07WildEncounter =>
          ProjectGameplayReadinessCheck.encounterTables,
        MvpProductCriterion.mvp10TrainerBattle =>
          ProjectGameplayReadinessCheck.trainerReferences,
        MvpProductCriterion.mvp16Shop =>
          ProjectGameplayReadinessCheck.shopItems,
        MvpProductCriterion.mvp04NpcDialogue ||
        MvpProductCriterion.mvp06Cutscene =>
          ProjectGameplayReadinessCheck.eventCommands,
        MvpProductCriterion.mvp05ConditionalDialogue ||
        MvpProductCriterion.mvp14BadgeOrFlag =>
          ProjectGameplayReadinessCheck.requiredFlagsReachable,
        MvpProductCriterion.mvp15FieldAbility =>
          ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable,
        MvpProductCriterion.mvp19StoryEnd =>
          ProjectGameplayReadinessCheck.storyEndReachable,
        MvpProductCriterion.mvp08Capture ||
        MvpProductCriterion.mvp11ExperienceAndMoney ||
        MvpProductCriterion.mvp12LevelUp ||
        MvpProductCriterion.mvp13MoveLearning =>
          ProjectGameplayReadinessCheck.battleBridgeCoverage,
      };

  static MvpProductCriterion fromId(String id) {
    for (final criterion in MvpProductCriterion.values) {
      if (criterion.id == id) return criterion;
    }
    throw FormatException('Unknown MVP product criterion: $id');
  }
}

enum MvpProductCriterionStatus { passed, failed, unverified }

/// One explicit observation produced by an executed product journey.
final class MvpProductCriterionEvidence {
  const MvpProductCriterionEvidence({
    required this.criterion,
    required this.status,
    required this.summary,
    required this.source,
  });

  final MvpProductCriterion criterion;
  final MvpProductCriterionStatus status;
  final String summary;
  final String source;

  Map<String, Object?> toJson() => <String, Object?>{
        'criterion': criterion.id,
        'status': status.name,
        'summary': summary,
        'source': source,
      };

  factory MvpProductCriterionEvidence.fromJson(Map<String, dynamic> json) {
    final criterionId = json['criterion'];
    final statusName = json['status'];
    final summary = json['summary'];
    final source = json['source'];
    if (criterionId is! String ||
        statusName is! String ||
        summary is! String ||
        source is! String) {
      throw const FormatException(
        'MVP criterion evidence requires string criterion/status/summary/source.',
      );
    }
    final status = MvpProductCriterionStatus.values
        .where((candidate) => candidate.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw FormatException('Unknown MVP criterion status: $statusName');
    }
    return MvpProductCriterionEvidence(
      criterion: MvpProductCriterionContract.fromId(criterionId),
      status: status,
      summary: summary,
      source: source,
    );
  }
}
