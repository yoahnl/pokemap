/// Taxonomie des défaillances runtime, par domaine — BETA-SYS-006.
///
/// Le ticket demandait « une taxonomie commune des erreurs projet, session,
/// save, gameplay et UI ». Mesuré le 2026-08-20 : chaque domaine AVAIT déjà son
/// type porteur avec la bonne séparation — un canal joueur sûr, un canal debug
/// brut, une forme de récupérabilité. Ce qui manquait n'était pas un nouveau
/// type commun : c'était que cette discipline soit DÉCLARÉE et TENUE. Deux
/// fuites réelles l'ont prouvé (un identifiant d'authoring et des messages
/// techniques anglais versés dans les notifications joueur), et 63 messages
/// joueur codés en anglais alors que le canal joueur du produit est français.
///
/// Ce fichier déclare le contrat par domaine. Un test le confronte à la source
/// (les types existent, leurs champs aussi), et un garde lexical interdit les
/// deux classes de fuite observées : interpolation dans un canal joueur, et
/// message joueur rédigé en anglais.
///
/// Remplacer ces cinq types par une hiérarchie commune serait une migration à
/// dizaines de fichiers pour un gain nul : la valeur est dans le contrat tenu,
/// pas dans l'unification des formes.
library;

/// Comment un domaine exprime « que peut faire le joueur maintenant ».
enum RuntimeFailureRecoverabilityForm {
  /// Un enum dédié nomme la voie de sortie (retry, hub, réparation…).
  dedicatedEnum,

  /// Le statut du résultat EST la récupérabilité (stale, unavailable…) :
  /// la commande peut être resoumise ou pas, rien d'autre à dire.
  resultStatus,

  /// L'état d'origine est conservé dans la défaillance : l'appelant peut
  /// reprendre exactement où il était.
  originalStateCarried,

  /// Le diagnostic porte une action de récupération en texte.
  actionHint,
}

/// Contrat d'un domaine de défaillance.
class RuntimeFailureDomainContract {
  const RuntimeFailureDomainContract({
    required this.domain,
    required this.carrierTypeName,
    required this.playerChannelField,
    required this.debugChannelField,
    required this.recoverabilityForm,
    required this.notes,
  });

  /// Nom stable du domaine.
  final String domain;

  /// Type Dart qui porte la défaillance.
  final String carrierTypeName;

  /// Champ dont le contenu peut atteindre l'écran du joueur.
  ///
  /// Règles du canal joueur, tenues par le garde de non-fuite :
  /// texte français, littéral, sans interpolation — donc sans identifiant
  /// technique, sans chemin, sans exception.
  final String playerChannelField;

  /// Champ ou canal qui porte le détail développeur, jamais montré au joueur.
  final String debugChannelField;

  final RuntimeFailureRecoverabilityForm recoverabilityForm;

  /// Ce qu'il faut savoir pour ne pas casser le contrat en modifiant le domaine.
  final String notes;
}

/// La taxonomie, triée par domaine.
const List<RuntimeFailureDomainContract> runtimeFailureTaxonomy =
    <RuntimeFailureDomainContract>[
  RuntimeFailureDomainContract(
    domain: 'playerCommand',
    carrierTypeName: 'RuntimePlayerCommandResult',
    playerChannelField: 'safeMessage',
    debugChannelField: 'debugPrint au point d’émission',
    recoverabilityForm: RuntimeFailureRecoverabilityForm.resultStatus,
    notes: 'Le statut (accepted, stale, unavailable, cancelled, failed) dit si '
        'la commande peut être resoumise. Les surfaces UI affichent safeMessage '
        'avec repli l10n quand il est nul.',
  ),
  RuntimeFailureDomainContract(
    domain: 'postBattle',
    carrierTypeName: 'RuntimePostBattleCoordinatorFailure',
    playerChannelField: 'message',
    debugChannelField: 'cause + debugDetails de l’exception d’origine',
    recoverabilityForm:
        RuntimeFailureRecoverabilityForm.originalStateCarried,
    notes: 'originalState permet de re-présenter la décision post-combat sans '
        'perdre la transaction. message est français et stable ; le détail '
        'technique vit dans cause.',
  ),
  RuntimeFailureDomainContract(
    domain: 'projectValidation',
    carrierTypeName: 'BetaPlayabilityDiagnostic',
    playerChannelField: 'message',
    debugChannelField: 'path + identifiants dédiés (mapId, speciesId…)',
    recoverabilityForm: RuntimeFailureRecoverabilityForm.actionHint,
    notes: 'Surface AUTEUR, pas joueur : les identifiants techniques y sont la '
        'matière du diagnostic, actionHint dit comment réparer. Composée sous '
        'BETA-SYS-005 dans map_core.',
  ),
  RuntimeFailureDomainContract(
    domain: 'session',
    carrierTypeName: 'GameSessionFailure',
    playerChannelField: 'safeMessage',
    debugChannelField: 'GameSessionDiagnosticData.safeDetails + logs',
    recoverabilityForm: RuntimeFailureRecoverabilityForm.dedicatedEnum,
    notes: 'GameSessionFailureRecoverability nomme la voie de sortie : retry, '
        'titleOrHub, hubOnly, repair. Les surfaces UI replient sur l10n quand '
        'safeMessage est nul.',
  ),
  RuntimeFailureDomainContract(
    domain: 'worldNotification',
    carrierTypeName: '_showNotification (PlayableMapGame)',
    playerChannelField: 'message (argument)',
    debugChannelField: 'debugPrint au point d’émission',
    recoverabilityForm: RuntimeFailureRecoverabilityForm.resultStatus,
    notes: 'Canal le plus exposé : du texte posé directement sur l’écran de '
        'jeu. Deux fuites y ont été trouvées et corrigées (identifiant de '
        'dialogue, messages techniques anglais du Scene V1) — le garde de '
        'non-fuite interdit toute interpolation dans un littéral passé à ce '
        'canal.',
  ),
];
