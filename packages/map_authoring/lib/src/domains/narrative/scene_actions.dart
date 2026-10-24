import 'dart:convert';

import 'package:map_core/map_core.dart';
import '../assets/project_media_store.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../workspace/project_snapshot.dart';
import 'dialogue_authoring_service.dart';
import 'dialogue_source_store.dart';
import 'dialogue_source_guards.dart';
import 'scene_party_move_catalog.dart';
import 'narrative_action_support.dart';
import 'presentation_publication_guards.dart';
import 'narrative_authoring_exception.dart';
import 'presentation_cinematic_template_actions.dart';
import 'presentation_publication_snapshot.dart';

final class ScenePreSessionInteractionCueBindingDraft {
  const ScenePreSessionInteractionCueBindingDraft({
    required this.presentationNodeId,
    required this.markerId,
  });

  final String presentationNodeId;
  final String markerId;
}

final class SceneActions {
  const SceneActions();

  static const _finishGameContract = {
    'consequenceKind': 'finishGame',
    'contractVersion': 1,
    'recordParty': {
      'type': 'boolean',
      'default': false,
      'requiredCapability': 'game.completion-party-journal@1',
      'persistentField': 'completionPartyJournal',
      'snapshot': 'immutableCurrentPartyInOrder',
      'deduplication': 'saveIdAndEndingId',
      'commit': 'sameVerifiedFinalCheckpointBeforePresentation',
    },
  };

  static const _integerOperandContract = {
    'kinds': ['literal', 'integerFact', 'gameRead', 'random'],
    'gameReads': ['money', 'partyCount', 'itemCount'],
    'integerRange': [-9007199254740991, 9007199254740991],
    'random': {'allowedOnlyIn': 'calculateIntegerFacts', 'maximumRangeWidth': 4294967296,
      'state': 'sceneRandomState', 'seed': 'saveIdOnFirstDraw', 'sampling': 'uniformRejectionLcg32',
      'draw': 'onceBeforeTargetRange', 'replay': 'sameBaseSameDraw', 'saveReload': 'continuesPersistedStream'},
    'expressions': 'none',
  };
  static const _calculateIntegerFactsContract = {
    'consequenceKind': 'calculateIntegerFacts',
    'parameters': ['factIds', 'operation', 'operand', 'minimum', 'maximum', 'zeroDivisorPolicy', 'boundaryPolicy'],
    'factReference': 'oneTo1024KnownUniqueIntegerFacts',
    'operations': ['assign', 'add', 'subtract', 'multiply', 'floorDivide', 'modulo'],
    'operand': _integerOperandContract, 'operandSnapshot': 'onceBeforeTargetRange',
    'zeroDivisorPolicies': ['reject', 'keepValue', 'keepValueForZeroOrOne'],
    'boundaryPolicies': ['clamp', 'preserveSaturated'], 'intermediates': 'BigInt',
    'persistentField': 'narrativeFactRuntimeState', 'atomicity': 'sceneTransaction',
    'projectDimensions': ['twoD', 'threeD'], 'outputPorts': ['completed'],
  };
  static const _adjustMoneyContract = {
    'consequenceKind': 'adjustMoney', 'parameters': ['operation', 'amount', 'minimum', 'maximum', 'expectedBalance'],
    'operations': ['add', 'subtract'], 'amount': _integerOperandContract,
    'random': 'forbidden', 'amountValidation': 'signedIntegerVariation', 'bounds': 'nonnegativeExplicitClamped',
    'expectedBalance': 'optionalExactCommitGuard', 'persistentField': 'trainerProfile.money',
    'atomicity': 'sceneTransaction', 'projectDimensions': ['twoD', 'threeD'], 'outputPorts': ['completed'],
  };
  static const _inputIntegerToFactContract = {
    'interactiveCommandKind': 'inputIntegerToFact',
    'parameters': ['factId', 'prompt', 'digits', 'minimum', 'maximum', 'initialValue', 'allowCancel', 'cancellationPolicy'],
    'factReference': 'knownUniqueIntegerFact', 'digits': [1, 9],
    'initialValue': 'explicitOrCurrentFactClampedToBounds', 'response': 'typedInteger',
    'validation': 'integerBoundsDigitsAndRevision', 'cancellationPolicies': ['leaveUnchanged', 'restoreInitialAndComplete'],
    'persistentField': 'narrativeFactRuntimeState', 'atomicity': 'orderedSceneConsequenceBuffer',
    'projectDimensions': ['twoD', 'threeD'], 'outputPorts': ['completed', 'cancelled'],
  };
  static const _tryPayMoneyContract = {
    'interactiveCommandKind': 'tryPayMoney', 'parameters': ['amount', 'confirmationPrompt'],
    'amount': _integerOperandContract, 'random': 'forbidden', 'amountValidation': 'strictlyPositive',
    'confirmation': 'optional', 'commit': 'exactDebitWithCapturedAmountAndBalanceGuard',
    'persistentField': 'trainerProfile.money', 'atomicity': 'orderedSceneConsequenceBuffer',
    'projectDimensions': ['twoD', 'threeD'], 'outputPorts': ['completed', 'insufficientFunds', 'cancelled'],
  };
  static const _integerComparisonContract = {
    'sourceKind': 'integerComparison', 'parameters': ['left', 'comparison', 'right'],
    'operands': _integerOperandContract, 'random': 'forbidden',
    'comparisons': ['equals', 'notEquals', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual'],
    'state': 'orderedProjectedSceneState', 'commit': 'readDependencyCoherence',
    'projectDimensions': ['twoD', 'threeD'], 'outputPorts': ['true', 'false'],
  };

  static const _inputTextToFactContract = {
    'interactiveCommandKind': 'inputTextToFact',
    'parameters': ['factId', 'prompt', 'confirmationPrompt', 'constraints', 'presetValues', 'customChoiceLabel', 'presetChoicePrompt'],
    'factReference': 'knownUniqueStringFact',
    'persistentField': 'narrativeFactRuntimeState',
    'atomicity': 'orderedSceneConsequenceBuffer',
    'validation': 'graphemeBoundsAndRevision',
    'confirmation': 'yesCommitsNoRestartsInitialChoice',
    'cancellation': 'noTextFactWrite',
    'projectDimensions': ['twoD'],
    'outputPorts': ['completed', 'cancelled'],
  };

  static const _adjustIntegerFactContract = {
    'consequenceKind': 'adjustIntegerFact',
    'parameters': ['factId', 'delta', 'minimum', 'maximum'],
    'factReference': 'knownUniqueIntegerFact',
    'integerRange': [-9007199254740991, 9007199254740991],
    'bounds': 'minimumMustNotExceedMaximum',
    'operation': 'clamp(current + delta, minimum, maximum)',
    'persistentField': 'narrativeFactRuntimeState',
    'atomicity': 'sceneTransaction',
    'projectDimensions': ['twoD', 'threeD'],
    'outputPorts': ['completed'],
  };

  static const _partyConditionContract = {
    'sourceKind': 'partyState',
    'sourceId': 'predicateName',
    'predicates': ['canReceivePokemon', 'knowsMove', 'hasUsableMove', 'canUseFieldAbility'],
    'operators': ['isTrue', 'isFalse'],
    'capacity': 'partyThenStorage',
    'moveReference': 'knownUniqueMoveInActiveProjectCatalogue',
    'movePredicates': {'field': 'moveId', 'value': 'canonicalMoveId'},
    'fieldAbility': {'field': 'ability', 'value': 'FieldAbility.moveId',
      'allowedValues': ['fly', 'surf', 'cut', 'strength', 'flash', 'rock_smash', 'waterfall', 'dive']},
    'knowsMove': 'anyPartyMemberIncludingFaintedAndZeroPp',
    'hasUsableMove': 'nonFaintedMemberWithKnownMoveAndPositivePp',
    'canUseFieldAbility': 'supportedAndUnlockedWithNonFaintedMemberKnowingMoveEvenAtZeroPpWithoutPpConsumption',
    'projectDimensions': ['twoD', 'threeD'],
    'persistentEffects': 'none',
  };

  static const _setPlayerAvatarContract = {
    'consequenceKind': 'setPlayerAvatar',
    'parameters': ['characterId'],
    'characterReference': 'knownUniqueProjectCharacterWithLoadableDirectionalAnimations',
    'projectDimensions': ['twoD', 'threeD'],
    'persistentField': 'trainerProfile.avatarCharacterId',
    'restoration': 'explicitCharacterSelection',
    'collisionEffect': 'none',
    'positionAndFacing': 'preserved',
    'mediaFailure': 'abortSceneTransaction',
    'projection': 'immediateWithinSceneWithRollbackOnFailureOrCancellation',
    'persistent': true,
    'outputPorts': ['completed'],
  };

  static const _warpContract = {
    'parameters': ['destinationMapId', 'warpId', 'arrivalFacing', 'transition', 'presentation'],
    'arrivalFacingValues': ['north', 'south', 'east', 'west'],
    'absentArrivalFacing': 'preserveCurrentDirection',
    'transitionValues': ['mapDefault', 'none'],
    'defaultTransition': 'mapDefault',
    'arrivalReference': 'warpOwnedByDestinationMap',
    'presentation': {
      'projectDimension': 'twoD',
      'parameters': ['mode', 'illustrationElementId', 'fadeOutMs', 'transferDelayMs',
        'revealMs', 'illustrationHoldMs', 'illustrationFadeMs'],
      'modes': ['fade', 'illustrated', 'caveEntrance', 'caveExit'],
      'illustrationModes': ['illustrated', 'caveEntrance'],
      'positiveDurationFields': ['fadeOutMs', 'revealMs', 'illustrationFadeMs'],
      'illustrationReference': 'uniqueStaticNativeElement',
      'durationMsRange': [0, 10000],
      'transferDelayMinimum': 'fadeOutMs',
      'transferDelayMeaning': 'fadeStartToTransferOrCavePrelude',
      'illustratedReveal': 'worldAndImageConcurrentAfterHold',
      'caveReveal': 'remainingToneAfterTransfer',
      'caveBands': 15,
      'caveDurationsMs': [400, 400, 100],
      'persistent': false,
    },

  };

  static const _waitForActorRoutesContract = {
    'parameters': ['mapId'],
    'projectDimension': 'twoD',
    'mapReference': 'knownUniqueLoaded2DMap',
    'routeSet': 'live',
    'completion': 'allForcedRoutesFinished',
    'timeout': 'none',
    'persistent': false,
    'outputPorts': ['completed'],
  };

  static const _waitContract = {
    'projectDimension': 'twoD',
    'parameters': ['durationMs'],
    'durationMsRange': [0, 2147483647],
    'durationUnit': 'milliseconds',
    'completion': 'elapsed',
    'actorReference': 'none',
    'persistent': false,
    'outputPorts': ['completed'],
  };

  static const _openPartyTradeContract = {
    'projectDimension': 'twoD',
    'parameters': [],
    'selection': 'individualIdentity',
    'teamOrder': 'preserved',
    'partner': 'unchanged',
    'evolution': 'firstPokemonNativeTradeRules',
    'cancellation': 'noMutation',
    'commit': 'onceAfterConfirmation',
    'completion': 'closed',
    'persistent': true,
    'outputPorts': ['completed', 'cancelled'],
  };

  static const _setNpcPoseContract = {
    'consequenceKind': 'setNpcPose',
    'parameters': ['mapId', 'entityId', 'x?', 'y?', 'facing?'],
    'target': 'validatedNpcPresentationOwner',
    'modes': ['absolutePlacement', 'facingOnly'],
    'coordinates': 'pairedAbsoluteInBoundsOrBothAbsent',
    'facing': 'requiredWithoutCoordinatesOtherwiseOptionalCardinal',
    'facingOnlyPosition': 'currentSavedPoseOrAuthoredAnchorPreserved',
    'persistence': 'canonicalCurrentMapInstanceNpcPose',
    'visibleNpc': 'facingOnly',
    'staleInstance': 'refused',
  };
  static const _markPokemonSeenContract = {
    'consequenceKind': 'markPokemonSeen',
    'parameters': ['speciesId'],
    'validation': 'nonemptySpeciesIdAndActiveNativePokemonCatalog',
    'pokedex': 'seenOnly',
    'partyAndStorage': 'unchanged',
    'caught': 'unchanged',
    'persistence': 'canonicalGameStateCheckpoint',
    'idempotent': true,
  };
  static const _givePokemonFromCatalogContract = {
    'consequenceKind': 'givePokemonFromCatalog',
    'parameters': ['speciesId', 'formId', 'level', 'moveIds'],
    'moveIds': {
      'type': 'array',
      'items': 'canonicalMoveId',
      'minItems': 1,
      'maxItems': 4,
      'uniqueItems': true,
      'ordered': true,
      'default': null,
      'semantics': 'replaceNativeLevelLearnset'
    },
    'levelRange': [1, 100],
    'catalog': 'activeProjectPokemonCatalog',
    'generation': 'activeNativeRuleset',
    'initialHealth': 'fullHpAndPp',
    'moves': 'nativeLevelLearnset',
    'destination': 'partyThenStorage',
    'storageFull': 'atomicRefusalWithoutConsumingOperation',
    'pokedex': 'seenAndCaughtOnSuccessfulGrant',
    'idempotency': 'saveIdAndSceneGrantOperationId',
  };

  static const _receivePokemonFromCatalogContract = {
    'interactiveCommandKind': 'receivePokemonFromCatalog',
    'parameters': [
      'speciesId',
      'formId',
      'level',
      'nicknamePolicy',
      'nicknameMaxGraphemes',
      'pokedexPresentationPolicy',
      'moveIds'
    ],
    'moveIds': {
      'type': 'array',
      'items': 'canonicalMoveId',
      'minItems': 1,
      'maxItems': 4,
      'uniqueItems': true,
      'ordered': true,
      'default': null,
      'semantics': 'replaceNativeLevelLearnset'
    },
    'levelRange': [1, 100],
    'nicknamePolicies': ['offer', 'disabled'],
    'nicknameMaxGraphemesRange': [1, 100],
    'pokedexPresentationPolicies': ['never', 'whenNewAndPokedexVisible'],
    'outputPorts': ['party', 'pc', 'noCapacity'],
    'projectDimensions': ['twoD', 'threeD'],
    'catalog': 'activeProjectPokemonCatalog',
    'catalogValidation': 'runtimePreloadAndCommit',
    'generation': 'activeNativeRuleset',
    'destination': 'partyThenStorage',
    'pokedexAvailability': 'nativePauseMenuVisibility',
    'pokedex': 'seenAndCaughtOnSuccessfulGrant',
    'nicknameDeclined': 'keepSpeciesNameAndContinue',
    'technicalDismissal': 'abortSceneTransaction',
    'noCapacity': 'continueWithoutGrantOrOperationConsumption',
    'idempotency': 'saveIdAndSceneGrantOperationId',
    'persistent': true,
    'transaction': 'wholeScene',
  };

  static const _openRegionalMapContract = {
    'projectDimension': 'twoD',
    'parameters': [],
    'mode': 'readOnly',
    'fastTravel': false,
    'completion': 'closed',
    'persistent': false,
    'outputPorts': ['completed', 'cancelled'],
  };

  static const _worldPresentationContract = {
    'projectDimension': 'twoD',
    'operations': ['showPicture', 'movePicture', 'erasePicture', 'flash', 'shake'],
    'parameters': ['operation', 'scope', 'slotId', 'mediaAssetId', 'referenceWidth', 'referenceHeight', 'x', 'y', 'scaleX', 'scaleY', 'opacity', 'origin', 'red', 'green', 'blue', 'alpha', 'power', 'speed', 'durationMs', 'waitForCompletion'],
    'scopes': ['scene', 'map'],
    'defaultScope': 'map',
    'origins': ['topLeft', 'center'],
    'slotIdRange': [1, 100],
    'referenceDimensionRange': [1, 8192],
    'positionRange': [-1000000, 1000000],
    'scaleRange': [0, 16],
    'scaleMinimumExclusive': true,
    'opacityRange': [0, 1],
    'rgbaRange': [0, 255],
    'powerRange': [0, 128],
    'speedHzRange': [0.1, 60],
    'durationMsRange': [0, 60000],
    'finiteNumbers': true,
    'mediaReference': 'ProjectMediaCatalog.image',
    'viewport': 'referenceFrameLetterbox',
    'blend': 'normal',
    'mapScopeEnd': 'mapActivation',
    'sceneScopeEnd': 'sceneCompletion',
    'outputPorts': ['completed', 'blocked'],
  };

  static const _worldToneContract = {
    'projectDimension': 'twoD',
    'parameters': ['red', 'green', 'blue', 'gray', 'durationMs'],
    'finiteNumbers': true,
    'rgbRange': [-255, 255],
    'grayRange': [0, 255],
    'durationMsRange': [0, 2147483647],
    'durationUnit': 'milliseconds',
    'completion': 'scheduled',
    'persistent': false,
    'outputPorts': ['completed', 'blocked'],
  };

  static const _soundEffectContract = {
    'projectDimensions': ['twoD', 'threeD'],
    'parameters': ['mediaAssetId', 'volume', 'waitForCompletion'],
    'mediaReference': 'knownNonLoopingSound',
    'finiteNumbers': true,
    'volumeRange': [0, 1],
    'unsupportedParameters': ['pitch'],
    'completion': 'startedOrNaturalCompletionWhenRequested',
    'waitForCompletion': {'type': 'boolean', 'default': false},
    'persistent': false,
    'outputPorts': ['completed', 'blocked'],
  };

  static const _sceneMusicContract = {
    'projectDimension': 'twoD',
    'executionProfile': 'world',
    'parameters': ['operation', 'channel', 'scope', 'mediaAssetId', 'volume', 'durationMs'],
    'operations': {
      'play': ['operation', 'mediaAssetId', 'volume'],
      'restore': ['operation'],
      'fadeOut': ['operation', 'durationMs'],
      'stop': ['operation'],
      'memorize': ['operation'],
      'restoreMemorized': ['operation'],
    },
    'mediaReference': 'knownUniqueMusic',
    'forcedLoop': true,
    'volumeRange': [0, 1],
    'finiteNumbers': true,
    'durationMsRange': [0, 60000],
    'scope': 'ownerScoped',
    'scopes': ['scene', 'map'],
    'channels': ['music', 'ambience', 'both'],
    'defaultScope': 'scene',
    'defaultChannel': 'music',
    'bothChannelOperations': ['memorize', 'restoreMemorized'],
    'restoreBaseline': 'capturedBeforeFirstModification',
    'recaptureAfterRestore': true,
    'battlePriority': 'higher',
    'completion': 'scheduled',
    'persistentScopes': ['map'],
    'persistence': 'mapOwnerUntilActivationEnds',
    'sceneCompletion': 'restoreSceneOwnerOnly',
    'ambienceBus': 'effects',
    'ambienceBattlePolicy': 'pauseAndResumeSameHandle',
    'memorizedPosition': false,
    'sceneTerminalRestoration': [
      'completed',
      'failure',
      'abort',
      'exitEvent',
      'dispose',
    ],
    'mapTerminalRestoration': ['activationEnds', 'abortCompensatesCheckpoint', 'dispose'],
    'staleOwnerPolicy': 'rejectAndCancelLateCallbacks',
    'outputPorts': ['completed', 'blocked'],
  };

  static const _musicEffectContract = {
    'projectDimensions': ['twoD', 'threeD'],
    'parameters': ['mediaAssetId', 'volume', 'bgmInterruption', 'waitForCompletion'],
    'role': 'musicEffect',
    'mediaReference': 'knownNonLoopingSound',
    'finiteNumbers': true,
    'volumeRange': [0, 1],
    'bgmInterruption': {
      'parameters': ['fadeOutMs', 'fadeInMs'],
      'integerRange': [0, 60000],
    },
    'unsupportedParameters': ['pitch'],
    'completion': 'startedOrNaturalCompletionWhenRequested',
    'waitForCompletion': {'type': 'boolean', 'default': false},
    'persistent': false,
    'outputPorts': ['completed', 'blocked'],
  };

  static const _actorRouteContract = {
    'contractVersion': 4,
    'parameters': ['target', 'steps', 'skippable', 'transientScope'],
    'transientScopes': ['route', 'scene'],
    'defaultTransientScope': 'route',
    'transientFlags': ['through', 'renderAboveMap', 'visibility', 'appearance'],
    'execution': 'awaitedSequentialRoute',
    'simultaneousActorsAndJumps': 'cinematicTimeline',
    'nonSkippableObstruction': 'blockedWithoutRetry',
    'transientLifetime': 'explicitScopeWithRestorationOnCompletionFailureOrCancellation',
    'playerSceneScope': 'continuousAcrossMapTransfers',
    'entitySceneScope': 'exactMapInstanceAndEntity',
    'savePolicy': 'transientFlagsNeverSerializedSceneCheckpointInterlock',
    'targetKinds': ['player', 'entity'],
    'targetReference': 'uniqueActorOnExactMap',
    'targetMapMode': '2D',
    'entityKind': 'npc',
    'entityCharacterReference': 'knownUniqueDirectOrTrainerCharacter',
    'targetFields': {
      'player': ['kind', 'mapId'],
      'entity': ['kind', 'mapId', 'entityId'],
    },
    'stepKinds': ['face', 'move', 'moveDiagonal', 'wait', 'through', 'renderAboveMap', 'visibility', 'appearance', 'sound'],
    'stepFields': {
      'face': ['kind', 'direction', 'durationMs', 'yieldAfter'],
      'move': ['kind', 'direction', 'durationMs', 'initialCollisionOwnerEntityId'],
      'moveDiagonal': ['kind', 'horizontal', 'vertical', 'durationMs'],
      'renderAboveMap': ['kind', 'enabled'],
      'visibility': ['kind', 'visible'],
      'appearance': ['kind', 'characterId'],
      'wait': ['kind', 'durationMs'],
      'through': ['kind', 'enabled'],
      'sound': ['kind', 'mediaAssetId', 'gain'],
    },
    'stepOptionalFields': {
      'face': ['durationMs', 'yieldAfter'],
      'move': ['initialCollisionOwnerEntityId'],
    },
    'initialCollisionOwner': {
      'field': 'initialCollisionOwnerEntityId',
      'status': 'partial',
      'targetKind': 'player',
      'effectiveThrough': false,
      'reference': 'knownUniqueNPCCharacterOnExactTargetMap',
      'collisionFootprintSize': [1, 1],
      'collisionFootprintAnchor': 'sameAsEntityAnchor',
      'collisionExemption': 'initialOwnerOverlapOnly',
      'absent': 'ordinaryCollisionValidation',
      'explicitNull': 'rejected',
      'identity': 'canonicalNonempty',
      'validation': 'runtimeInitialPhysicalOverlapAndDisjointDestination',
      'lifetime': 'currentMoveOnly',
    },
    'directions': ['north', 'south', 'east', 'west'],
    'durationMsRange': [0, 2147483647],
    'minimumMoveDurationMs': 1,
    'diagonalHorizontalDirections': ['west', 'east'],
    'diagonalVerticalDirections': ['north', 'south'],
    'diagonalMotion': 'simultaneousAxesWithSweptCollisionAndSingleStep',
    'renderAboveMap': 'aboveForegroundBelowScreenOverlays',
    'defaultFaceDurationMs': 0,
    'defaultFaceYieldAfter': false,
    'faceYieldCompletion': 'nextUpdateBeforeHold',
    'defaultSkippable': false,
    'finiteNumbers': true,
    'gainRange': [0, 1],
    'mediaReference': 'knownUniqueNonLoopingSound',
    'unsupportedParameters': ['pitch', 'repeat'],
    'dynamicCollisionValidation': 'runtime',
    'completion': 'routeFinished',
    'persistent': false,
    'outputPorts': ['completed', 'blocked'],
  };

  static const _actorVisibilityContract = {
    'parameters': ['target', 'visible'],
    'targetKinds': ['player', 'entity'],
    'targetReference': 'uniqueActorOnExactMap',
    'targetMapMode': '2D',
    'entityKind': 'npc',
    'entityCharacterReference': 'knownUniqueDirectOrTrainerCharacter',
    'targetFields': {
      'player': ['kind', 'mapId'],
      'entity': ['kind', 'mapId', 'entityId'],
    },
    'collisionEffect': 'none',
    'completion': 'applied',
    'persistent': false,
    'outputPorts': ['completed', 'blocked'],
  };

  static const _mapEventInstanceBooleanContract = {
    'sourceKind': 'mapEventInstanceBoolean',
    'parameters': ['mapId', 'sourceId', 'key', 'operator'],
    'owner': 'knownUniqueLogicalMapEntity',
    'operators': ['isTrue', 'isFalse'],
    'valueType': 'boolean',
    'defaultValue': false,
    'lifetime': 'mapEventInstance',
    'saveResume': 'retainedInstanceState',
    'recreatedInstance': 'defaultsRestored',
  };

  static const _setMapEventInstanceBooleanContract = {
    'consequenceKind': 'setMapEventInstanceBoolean',
    'parameters': ['mapId', 'eventId', 'key', 'value'],
    'owner': 'knownUniqueLogicalMapEntity',
    'valueType': 'boolean',
    'lifetime': 'mapEventInstance',
    'persistentFacts': 'unchanged',
    'outputPorts': ['completed'],
  };

  static const _battleDefeatRecoveryContract = {
    'payloadKind': 'battle',
    'field': 'defeatRecovery',
    'values': ['continueScene', 'returnToRecoveryPoint'],
    'default': 'continueScene',
    'projectDimension': 'twoD',
    'activation': 'actualDefeatAfterSuccessfulSceneCompletion',
    'effects': ['healParty', 'defeatMoneyPenalty', 'returnToRecordedRecoveryPoint'],
    'saveResume': 'committedRecoveredState',
  };

  static const _whiteOutContract = {
    'interactiveCommandKind': 'whiteOut',
    'parameters': [],
    'projectDimension': 'twoD',
    'activation': 'afterSuccessfulSceneCompletion',
    'effects': ['healParty', 'defeatMoneyPenalty', 'returnToRecordedRecoveryPoint'],
    'saveResume': 'committedRecoveredState',
    'outputPorts': ['completed'],
  };

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    narrativeActionDescriptor(
      'scene.graph.patch',
      'Atomically edit selected Scene nodes and links while preserving layout',
      resourceKinds: const ['project', 'scene'],
      extensions: const {
        'parameters': ['sceneId', 'upsertNodes', 'removeNodeIds', 'upsertEdges', 'removeEdgeIds'],
        'finishGame': _finishGameContract,
        'battleDefeatRecovery': _battleDefeatRecoveryContract,
        'whiteOut': _whiteOutContract,
        'calculateIntegerFacts': _calculateIntegerFactsContract,
        'adjustMoney': _adjustMoneyContract,
        'adjustIntegerFact': _adjustIntegerFactContract,
        'integerComparison': _integerComparisonContract,
        'partyState': _partyConditionContract,
        'mapEventInstanceBoolean': _mapEventInstanceBooleanContract,
        'setMapEventInstanceBoolean': _setMapEventInstanceBooleanContract,
        'setPlayerAvatar': _setPlayerAvatarContract,
        'markPokemonSeen': _markPokemonSeenContract,
        'setNpcPose': _setNpcPoseContract,
        'givePokemonFromCatalog': _givePokemonFromCatalogContract,
        'inputIntegerToFact': _inputIntegerToFactContract,
        'tryPayMoney': _tryPayMoneyContract,
        'inputTextToFact': _inputTextToFactContract,
        'receivePokemonFromCatalog': _receivePokemonFromCatalogContract,
        'waitForActorRoutes': _waitForActorRoutesContract,
        'wait': _waitContract,
        'openRegionalMap': _openRegionalMapContract,
        'openPartyTrade': _openPartyTradeContract,
        'worldTone': _worldToneContract,
        'worldPresentation': _worldPresentationContract,
        'playSoundEffect': _soundEffectContract,
        'playMusicEffect': _musicEffectContract,
        'sceneMusic': _sceneMusicContract,
        'stopSoundEffects': {'projectDimensions': ['twoD', 'threeD'], 'parameters': ['scope'], 'scopes': ['scene', 'map'], 'owner': 'currentMapActivationAndOptionalScene', 'excludes': ['musicEffects', 'music', 'ambience', 'battleEffects']},
        'actorRoute': _actorRouteContract,
      },
    ),
    narrativeActionDescriptor(
      'scene.condition.set',
      'Configure one typed Scene condition without replacing its graph',
      resourceKinds: const ['project', 'scene'],
      extensions: const {
        'parameters': ['sceneId', 'nodeId', 'conditionSource'],
        'integerComparison': _integerComparisonContract,
        'partyState': _partyConditionContract,
        'mapEventInstanceBoolean': _mapEventInstanceBooleanContract,
        'pokedexCaughtCount': {
          'sourceKind': 'pokedexCaughtCount',
          'projectDimension': 'twoD',
          'sourceId': 'national:first:last',
          'field': 'minimumCount',
          'value': 'positiveInteger',
          'bounds': [1, 65535],
          'operators': ['isTrue', 'isFalse'],
          'state': 'historicalCaughtSpeciesNationalNumbers',
          'forms': 'deduplicateNationalNumber',
          'unresolvedSpecies': 'refuse',
        },
        'trainerDefeated': {
          'sourceKind': 'trainerDefeated',
          'sourceId': 'projectTrainerId',
          'operators': ['isTrue', 'isFalse'],
          'runtimeSource': 'storyFlags.activeFlags:trainer_defeated:<trainerId>',
          'projectDimensions': ['twoD', 'threeD'],
          'staticEncounters': 'refused',
        },
        'playerFacing': {
          'sourceKind': 'playerFacing',
          'sourceId': ['north', 'south', 'east', 'west'],
          'operators': ['isTrue', 'isFalse'],
          'state': 'livePlayerFacing',
          'independentOfEntityFacing': true,
        },
      },
    ),
    narrativeActionDescriptor(
      'scene.interactive_command.set',
      'Configure one typed interactive Scene command and validate its routes',
      resourceKinds: const ['project', 'scene'],
      extensions: const {
        'parameters': ['sceneId', 'nodeId', 'command'],
        'inputIntegerToFact': _inputIntegerToFactContract,
        'tryPayMoney': _tryPayMoneyContract,
        'inputTextToFact': _inputTextToFactContract,
        'receivePokemonFromCatalog': _receivePokemonFromCatalogContract,
        'warp': _warpContract,
        'worldTone': _worldToneContract,
        'worldPresentation': _worldPresentationContract,
        'playSoundEffect': _soundEffectContract,
        'playMusicEffect': _musicEffectContract,
        'sceneMusic': _sceneMusicContract,
        'stopSoundEffects': {'projectDimensions': ['twoD', 'threeD'], 'parameters': ['scope'], 'scopes': ['scene', 'map'], 'owner': 'currentMapActivationAndOptionalScene', 'excludes': ['musicEffects', 'music', 'ambience', 'battleEffects']},
        'waitForActorRoutes': _waitForActorRoutesContract,
        'wait': _waitContract,
        'openRegionalMap': _openRegionalMapContract,
        'openPartyTrade': _openPartyTradeContract,
        'actorRoute': _actorRouteContract,
        'actorVisibility': _actorVisibilityContract,
      },
    ),
    narrativeActionDescriptor(
      'scene.dialogue.lineFeedback.update',
      'Configure one compiled dialogue line text, cadence and bounded media feedback',
      resourceKinds: const ['project', 'scene', 'dialogue'],
      extensions: const {
        'linePolicy': {
          'scopeFields': ['nodeName', 'lineIndex'],
          'textBinding': 'nonemptySegmentsMatchCompiledPlainText',
          'emptySegments': 'compiledScopeCadenceOrAudioOnly',
          'segmentKinds': ['text', 'icon'],
          'advanceKinds': ['confirm', 'autoAfterReveal'],
          'audioMedia': 'knownNonLoopingSound',
          'audioCue': {
            'cardinality': 'atMostOnePerLine',
            'revealOffset': {
              'type': 'integer',
              'default': 0,
              'minimum': 0,
              'maximum': 1048576,
              'unit': 'unicodeRunesBeforeInterpolation',
              'bound': 'compiledLineTextRuneLength',
              'nonzeroRole': 'effect',
              'trigger': 'onceWhenRevealReachesOffset',
            },
          },
          'parameters': ['sceneId', 'nodeId', 'linePolicy'],
        },
      },
    ),
    narrativeActionDescriptor(
      'scene.dialogue.choicePolicy.update',
      'Configure one compiled dialogue choice default and cancellation policy',
      resourceKinds: const ['project', 'scene', 'dialogue'],
      extensions: const {
        'choicePolicy': {
          'scopeFields': ['nodeName', 'choiceIndex'],
          'cancellationKinds': ['disabled', 'choice', 'branch'],
          'defaultOutcome': 'uniqueVisibleChoiceOutcome',
          'branchOutcome': 'distinctDeclaredSceneOutcome',
          'parameters': ['sceneId', 'nodeId', 'choicePolicy'],
        },
      },
    ),
    narrativeActionDescriptor(
      'scene.upsert',
      'Create or replace a complete Scene graph',
      resourceKinds: const ['project', 'scene'],
      extensions: const {
        'finishGame': _finishGameContract,
        'battleDefeatRecovery': _battleDefeatRecoveryContract,
        'whiteOut': _whiteOutContract,
        'calculateIntegerFacts': _calculateIntegerFactsContract,
        'adjustMoney': _adjustMoneyContract,
        'adjustIntegerFact': _adjustIntegerFactContract,
        'mapEventInstanceBoolean': _mapEventInstanceBooleanContract,
        'setMapEventInstanceBoolean': _setMapEventInstanceBooleanContract,
        'setPlayerAvatar': _setPlayerAvatarContract,
        'markPokemonSeen': _markPokemonSeenContract,
        'setNpcPose': _setNpcPoseContract,
        'givePokemonFromCatalog': _givePokemonFromCatalogContract,
        'inputIntegerToFact': _inputIntegerToFactContract,
        'tryPayMoney': _tryPayMoneyContract,
        'inputTextToFact': _inputTextToFactContract,
        'receivePokemonFromCatalog': _receivePokemonFromCatalogContract,
        'warp': _warpContract,
        'worldTone': _worldToneContract,
        'worldPresentation': _worldPresentationContract,
        'playSoundEffect': _soundEffectContract,
        'playMusicEffect': _musicEffectContract,
        'sceneMusic': _sceneMusicContract,
        'stopSoundEffects': {'projectDimensions': ['twoD', 'threeD'], 'parameters': ['scope'], 'scopes': ['scene', 'map'], 'owner': 'currentMapActivationAndOptionalScene', 'excludes': ['musicEffects', 'music', 'ambience', 'battleEffects']},
        'waitForActorRoutes': _waitForActorRoutesContract,
        'wait': _waitContract,
        'openRegionalMap': _openRegionalMapContract,
        'openPartyTrade': _openPartyTradeContract,
        'actorRoute': _actorRouteContract,
        'actorVisibility': _actorVisibilityContract,
        'integerComparison': _integerComparisonContract,
        'partyState': _partyConditionContract,
        'badgeCondition': {
          'sourceKind': 'badge',
          'sourceId': 'projectBadgeId',
          'operators': ['isTrue', 'isFalse'],
          'runtimeSource': 'trainerProfile.badgeIds',
        },
        'movingPlatform': {
          'interactiveCommandKind': 'movePlatform',
          'parameters': ['mapId', 'platformId', 'motion'],
          'motions': ['forward', 'backward', 'rotateClockwise'],
          'outputPorts': ['moved', 'blocked', 'notRiding', 'rotationRequiresPivot'],
        },
        'movingProps': {
          'interactiveCommandKind': 'setPropState',
          'parameters': ['mapId', 'propIds', 'state', 'durationMs'],
          'states': ['closed', 'open'],
          'groupSize': {'minimum': 1, 'maximum': 32, 'unique': true},
          'durationMs': {'minimum': 16, 'maximum': 10000, 'default': 350},
          'outputPorts': ['moved', 'blocked'],
          'semantics': 'atomicSynchronizedRailMovementWithDurableState',
          'dimensions': ['twoD'],
        },
        'itemGift': {
          'interactiveCommandKind': 'giveItem',
          'parameters': ['itemId', 'quantity'],
          'outputPorts': ['received', 'bagFull'],
          'retry': 'routeBagFullToRetryableEndOrAuthoredRetry',
        },
      },
    ),
    narrativeActionDescriptor(
      'scene.upsert_batch',
      'Create or replace a bounded atomic batch of complete Scene graphs',
      resourceKinds: const ['project', 'scene'],
      extensions: const {
        'sceneContract': 'scene.upsert',
        'finishGame': _finishGameContract,
        'batch': {
          'minScenes': 1,
          'maxScenes': 128,
          'uniqueBy': 'id',
          'semantics': 'createOrUpdate',
          'atomic': true,
        },
      },
    ),
    narrativeActionDescriptor(
      'scene.delete',
      'Delete an unreferenced Scene or replace its references',
      resourceKinds: const ['project', 'scene'],
      risk: AuthoringRiskLevel.high,
    ),
    narrativeActionDescriptor(
      'scene.character_animation.set',
      'Set one bounded Character Studio animation on a Scene action node',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.create',
      'Create a typed preSession Scene from a canonical template',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.interaction.insert',
      'Insert a structured preSession interaction before a Scene node',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.presentation.cue.routes.set',
      'Author what the Presentation does after each interaction output',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.interaction.update',
      'Update a structured preSession interaction and its optional cue link',
      resourceKinds: const [
        'project',
        'scene',
        'presentationCinematic',
      ],
    ),
    narrativeActionDescriptor(
      'scene.preSession.presentation.insert',
      'Insert a canonical Presentation Cinematic before a Scene node',
      resourceKinds: const ['project', 'scene', 'presentationCinematic'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.presentation.createAndLink',
      'Create, catalog and link one Presentation Cinematic atomically',
      resourceKinds: const [
        'project',
        'scene',
        'presentationCinematic',
        'cinematicLibraryEntry',
      ],
    ),
    narrativeActionDescriptor(
      'scene.preSession.condition.insert',
      'Insert a draft-local preSession condition with a false terminal',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.preSession.end.configure',
      'Configure a typed preSession Scene end and declared outcome',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.pause_menu_visibility.set',
      'Set one persistent pause menu entry visibility on a Scene action node',
      resourceKinds: const ['project', 'scene'],
    ),
  ]);

  Future<AuthoringMutationDraft> prepare(AuthoringPlanningContext context) async {
    Set<String>? moveIds;
    final parameters = context.request.parameters;
    final rawSources = <Object?>[];
    if (context.request.actionId == 'scene.condition.set') {
      rawSources.add(parameters['conditionSource']);
    } else {
      final rawScenes = context.request.actionId == 'scene.upsert_batch'
          ? parameters['scenes']
          : [parameters['scene']];
      if (rawScenes is List) {
        for (final rawScene in rawScenes) {
          final rawGraph = rawScene is Map ? rawScene['graph'] : null;
          final rawNodes = context.request.actionId == 'scene.graph.patch'
              ? parameters['upsertNodes'] : rawGraph is Map ? rawGraph['nodes'] : null;
          if (rawNodes is List) {
            for (final node in rawNodes) {
              final payload = node is Map ? node['payload'] : null;
              if (payload is Map) rawSources.add(payload['conditionSource']);
            }
          }
        }
      }
    }
    for (final raw in rawSources) {
      if (raw is! Map<String, dynamic>) continue;
      SceneConditionSource source;
      try {
        source = SceneConditionSource.fromJson(raw);
      } on ArgumentError {
        continue;
      } on FormatException {
        continue;
      } on TypeError {
        throw NarrativeAuthoringException('scene.graph.payload_invalid',
            'The typed condition payload is invalid.');
      }
      final moveId = source.partyMoveId;
      if (moveId == null) continue;
      moveIds ??= await loadScenePartyMoveCatalog(context.snapshot);
      if (!moveIds.contains(moveId)) {
        throw NarrativeAuthoringException('scene.party_move_ref_unknown',
            'The selected party move is not in the active project catalogue.');
      }
    }
    final draft = build(context);
    final rawScene = context.request.parameters['scene'];
    final targetId = context.request.parameters['sceneId'] ?? (rawScene is Map ? rawScene['id'] : null);
    final batchIds = context.request.actionId == 'scene.upsert_batch'
        ? (parameters['scenes'] as List).map((value) => (value as Map)['id']).toSet()
        : const <Object?>{};
    final scenes = draft.projectedProject?.scenes.where((scene) =>
        scene.id == targetId || batchIds.contains(scene.id) ||
        !context.snapshot.manifest.scenes.contains(scene)).toList() ?? const <SceneAsset>[];
    final diagnosticsContext = context.request.actionId == 'scene.upsert_batch'
        ? SceneProjectDiagnosticsContext(draft.projectedProject!,
            presentationMediaCatalog: _presentationMedia(context),
            availableItemIds: context.snapshot.itemCatalog?.entries.map((item) => item.id).toSet(),
            mapsById: {for (final map in context.snapshot.maps) map.id: map})
        : null;
    for (final scene in scenes) {
      _validateScenePublication(
        draft.projectedProject!,
        maps: context.snapshot.maps,
        scene: scene,
        itemCatalog: context.snapshot.itemCatalog,
        context: diagnosticsContext,
        presentationMediaCatalog: _presentationMedia(context),
      );
    }
    final moveScenes = scenes.where(sceneNeedsPartyMoveCatalog).toList();
    if (moveScenes.isNotEmpty) {
      moveIds ??= await loadScenePartyMoveCatalog(context.snapshot);
      for (final scene in moveScenes) {
        validateScenePartyMoves(scene, moveIds);
      }
    }
    return draft;
  }

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    switch (context.request.actionId) {
      case 'scene.graph.patch':
      case 'scene.condition.set':
      case 'scene.interactive_command.set':
        return _buildGraphEdit(context);
      case 'scene.dialogue.lineFeedback.update':
        rejectUnknownNarrativeParameters(parameters, const {'sceneId', 'nodeId', 'linePolicy'});
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final nodeId = narrativeStringParameter(parameters, 'nodeId');
        final scene = _requireDialoguePolicyScene(context.snapshot.manifest, sceneId,
          errorPrefix: 'scene.dialogue.line_feedback');
        final node = _requireDialoguePolicyNode(scene, nodeId,
          errorPrefix: 'scene.dialogue.line_feedback');
        final payload = node.payload as SceneYarnDialoguePayload;
        late final SceneDialogueLinePolicy policy;
        try {
          policy = SceneDialogueLinePolicy.fromJson(narrativeObjectParameter(parameters, 'linePolicy'));
        } on ArgumentError {
          throw NarrativeAuthoringException('scene.dialogue.line_feedback.invalid',
            'The dialogue line feedback payload is invalid.');
        } on FormatException {
          throw NarrativeAuthoringException('scene.dialogue.line_feedback.invalid',
            'The dialogue line feedback payload is invalid.');
        }
        final projected = updateDialogueLineFeedback(context.snapshot.manifest,
          maps: context.snapshot.maps, sceneId: sceneId, nodeId: nodeId,
          linePolicy: policy, dialogue: _compilePolicyDialogue(context.snapshot, payload.dialogueId,
            errorPrefix: 'scene.dialogue.line_feedback'));
        final updated = projected.scenes.singleWhere((candidate) => candidate.id == sceneId)
            .graph.nodes.singleWhere((candidate) => candidate.id == nodeId).payload as SceneYarnDialoguePayload;
        return narrativeProjectDraft(context.snapshot, projected,
          operation: context.request.actionId, path: '/scenes/$sceneId/graph/nodes/$nodeId/payload/linePolicies',
          before: payload.linePolicies.map((item) => item.toJson()).toList(growable: false),
          after: updated.linePolicies.map((item) => item.toJson()).toList(growable: false));
      case 'scene.dialogue.choicePolicy.update':
        rejectUnknownNarrativeParameters(parameters, const {'sceneId', 'nodeId', 'choicePolicy'});
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final nodeId = narrativeStringParameter(parameters, 'nodeId');
        final scene = _requireDialoguePolicyScene(context.snapshot.manifest, sceneId);
        final node = _requireDialoguePolicyNode(scene, nodeId);
        final payload = node.payload as SceneYarnDialoguePayload;
        final policy = SceneDialogueChoicePolicy.fromJson(narrativeObjectParameter(parameters, 'choicePolicy'));
        final projected = updateDialogueChoicePolicy(context.snapshot.manifest,
          maps: context.snapshot.maps, sceneId: sceneId, nodeId: nodeId,
          choicePolicy: policy, dialogue: _compilePolicyDialogue(context.snapshot, payload.dialogueId));
        final updated = projected.scenes.singleWhere((candidate) => candidate.id == sceneId)
            .graph.nodes.singleWhere((candidate) => candidate.id == nodeId).payload as SceneYarnDialoguePayload;
        return narrativeProjectDraft(context.snapshot, projected,
          operation: context.request.actionId, path: '/scenes/$sceneId/graph/nodes/$nodeId/payload/choicePolicies',
          before: payload.choicePolicies.map((item) => item.toJson()).toList(growable: false),
          after: updated.choicePolicies.map((item) => item.toJson()).toList(growable: false));
      case 'scene.upsert_batch':
        final rawScenes = parameters['scenes'];
        if (parameters.keys.any((key) => key != 'scenes') ||
            rawScenes is! List || rawScenes.isEmpty || rawScenes.length > 128) {
          throw NarrativeAuthoringException('scene.batch_invalid',
              'A Scene batch must contain between 1 and 128 scenes.');
        }
        final scenes = <SceneAsset>[];
        final ids = <String>{};
        for (var index = 0; index < rawScenes.length; index++) {
          final raw = rawScenes[index];
          if (raw is! Map<String, dynamic>) {
            throw NarrativeAuthoringException('scene.invalid',
                'The Scene payload is invalid.', details: {'index': index});
          }
          final scene = _decodeScene(raw);
          if (!ids.add(scene.id)) {
            throw NarrativeAuthoringException('scene.batch_duplicate_id',
                'Scene identities must be unique within a batch.',
                details: {'index': index, 'sceneId': scene.id});
          }
          _validateSceneDialoguePolicies(context.snapshot, scene);
          scenes.add(scene);
        }
        final projected = upsertBatch(context.snapshot.manifest,
            maps: context.snapshot.maps, scenes: scenes,
            presentationMediaCatalog: _presentationMedia(context),
            itemCatalog: context.snapshot.itemCatalog);
        return narrativeProjectDraft(context.snapshot, projected,
            operation: context.request.actionId, path: '/scenes',
            before: context.snapshot.manifest.scenes
                .where((scene) => ids.contains(scene.id))
                .map((scene) => scene.toJson()).toList(growable: false),
            after: scenes.map((scene) => scene.toJson()).toList(growable: false),
            preview: {'sceneIds': scenes.map((scene) => scene.id).toList(growable: false)},
            includeInspectionPreview: true);
      case 'scene.upsert':
        rejectUnknownNarrativeParameters(parameters, const {'scene'});
        final scene =
            _decodeScene(narrativeObjectParameter(parameters, 'scene'));
        _validateSceneDialoguePolicies(context.snapshot, scene);
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == scene.id)
            .firstOrNull;
        final projected = upsert(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          scene: scene,
          itemCatalog: context.snapshot.itemCatalog,
          presentationMediaCatalog: _presentationMedia(context),
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/${scene.id}',
          before: before?.toJson(),
          after: scene.toJson(),
          includeInspectionPreview: true,
        );
      case 'scene.delete':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'replacementSceneId'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        final replacement = parameters['replacementSceneId'];
        if (replacement != null && replacement is! String) {
          throw ArgumentError.value(
            replacement,
            'replacementSceneId',
            'must be a string',
          );
        }
        final projected = delete(
          context.snapshot.manifest,
          sceneId: sceneId,
          replacementSceneId: replacement as String?,
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId',
          before: before?.toJson(),
          includeInspectionPreview: true,
        );
      case 'scene.character_animation.set':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'nodeId', 'runtimeCommand'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final nodeId = narrativeStringParameter(parameters, 'nodeId');
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        final projected = setCharacterAnimationCommand(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: nodeId,
          command: _decodeCharacterAnimationCommand(
            narrativeObjectParameter(parameters, 'runtimeCommand'),
          ),
        );
        final after = projected.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId/graph/nodes/$nodeId/interactiveCommand',
          before: before?.toJson(),
          after: after?.toJson(),
          includeInspectionPreview: true,
        );
      case 'scene.preSession.create':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'name',
            'templateId',
            'setAsEntrypoint',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = createPreSessionScene(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          name: narrativeStringParameter(parameters, 'name'),
          templateId: narrativeStringParameter(parameters, 'templateId'),
          setAsEntrypoint: _optionalBoolParameter(
            parameters,
            'setAsEntrypoint',
            fallback: true,
          ),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.interaction.insert':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'targetNodeId',
            'title',
            'interaction',
            'cueBinding',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = insertPreSessionInteraction(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          targetNodeId: narrativeStringParameter(parameters, 'targetNodeId'),
          title: _optionalStringParameter(parameters, 'title'),
          interaction: _decodePreSessionInteraction(
            narrativeObjectParameter(parameters, 'interaction'),
          ),
          cueBinding: _decodeOptionalCueBinding(parameters),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.interaction.update':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'nodeId', 'interaction', 'cueBinding'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = updatePreSessionInteraction(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          interaction: _decodePreSessionInteraction(
            narrativeObjectParameter(parameters, 'interaction'),
          ),
          replaceCueBinding: parameters.containsKey('cueBinding'),
          cueBinding: _decodeOptionalCueBinding(parameters),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.presentation.cue.routes.set':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'presentationNodeId', 'markerId', 'routes'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = setPresentationCueOutcomeRoutes(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          presentationNodeId: narrativeStringParameter(
            parameters,
            'presentationNodeId',
          ),
          markerId: narrativeStringParameter(parameters, 'markerId'),
          routes: _decodeCueOutcomeRoutes(parameters),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.presentation.insert':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'targetNodeId',
            'title',
            'presentationCinematicId',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = insertPreSessionPresentation(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          targetNodeId: narrativeStringParameter(parameters, 'targetNodeId'),
          title: _optionalStringParameter(parameters, 'title'),
          presentationCinematicId: narrativeStringParameter(
            parameters,
            'presentationCinematicId',
          ),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.presentation.createAndLink':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'targetNodeId',
            'cinematic',
            'cinematicId',
            'title',
            'templateId',
            'templateVersion',
            'targetFolderId',
            'targetIndex',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final nodeId = narrativeStringParameter(parameters, 'nodeId');
        final cinematic = _createAndLinkCinematic(parameters);
        final cinematicId = cinematic.id;
        final projected = createAndLinkPreSessionPresentation(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: nodeId,
          targetNodeId: narrativeStringParameter(
            parameters,
            'targetNodeId',
          ),
          cinematic: cinematic,
          mediaCatalog: _presentationMedia(context),
          sourceAssets: presentationSourceAssets(context.snapshot),
          targetFolderId: _nullableStringParameter(
            parameters,
            'targetFolderId',
          ),
          targetIndex: _integerParameter(parameters, 'targetIndex'),
        );
        final publishedCinematic = projected.presentationCinematics.singleWhere(
          (candidate) => candidate.id == cinematicId,
        );
        final scene = projected.scenes.singleWhere(
          (candidate) => candidate.id == sceneId,
        );
        final node = scene.graph.nodes.singleWhere(
          (candidate) => candidate.id == nodeId,
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId/presentationCinematics/$cinematicId',
          after: <String, Object?>{
            'cinematic': encodePresentationCinematicAsset(
              publishedCinematic,
            ),
            'libraryEntry': projected.cinematicLibraryCatalog
                .entryFor(CinematicLibraryFamily.presentation, cinematicId)!
                .toJson(),
            'node': node.toJson(),
          },
          preview: <String, Object?>{
            'resourceKind': 'presentationCinematic',
            'sceneId': sceneId,
            'nodeId': nodeId,
            'cinematicId': cinematicId,
            if (parameters['templateId'] case final String templateId)
              'templateId': templateId,
            if (parameters['templateVersion'] case final int templateVersion)
              'templateVersion': templateVersion,
          },
        );
      case 'scene.preSession.condition.insert':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'targetNodeId',
            'falseEndNodeId',
            'title',
            'draftField',
            'operator',
            'value',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = insertPreSessionCondition(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          targetNodeId: narrativeStringParameter(parameters, 'targetNodeId'),
          falseEndNodeId: narrativeStringParameter(
            parameters,
            'falseEndNodeId',
          ),
          title: _optionalStringParameter(parameters, 'title'),
          draftField: _enumParameter(
            parameters,
            'draftField',
            ScenePreSessionDraftField.values,
          ),
          operator: _enumParameter(
            parameters,
            'operator',
            SceneConditionOperator.values,
          ),
          value: _optionalStringParameter(parameters, 'value'),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.preSession.end.configure':
        rejectUnknownNarrativeParameters(
          parameters,
          const {
            'sceneId',
            'nodeId',
            'outcomeId',
            'outcomeLabel',
            'outcomePolicy',
          },
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final projected = configurePreSessionEnd(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: narrativeStringParameter(parameters, 'nodeId'),
          outcomeId: narrativeStringParameter(parameters, 'outcomeId'),
          outcomeLabel: narrativeStringParameter(parameters, 'outcomeLabel'),
          outcomePolicy: _enumParameter(
            parameters,
            'outcomePolicy',
            SceneOutcomePolicy.values,
          ),
        );
        return _preSessionProjectDraft(
          context,
          projected,
          sceneId: sceneId,
        );
      case 'scene.pause_menu_visibility.set':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'nodeId', 'actionId', 'visible'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final nodeId = narrativeStringParameter(parameters, 'nodeId');
        final beforeScene = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        final beforePayload = beforeScene?.graph.nodes
            .where((node) => node.id == nodeId)
            .firstOrNull
            ?.payload
            .toJson();
        final projected = setPauseMenuEntryVisibility(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          sceneId: sceneId,
          nodeId: nodeId,
          actionId: _decodePauseActionId(
            narrativeStringParameter(parameters, 'actionId'),
          ),
          visible: _booleanParameter(parameters, 'visible'),
        );
        final afterScene = projected.scenes
            .where((candidate) => candidate.id == sceneId)
            .first;
        final afterPayload = afterScene.graph.nodes
            .where((node) => node.id == nodeId)
            .first
            .payload
            .toJson();
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId/graph/nodes/$nodeId/consequence',
          before: beforePayload,
          after: afterPayload,
          includeInspectionPreview: true,
        );
      default:
        throw NarrativeAuthoringException(
          'scene.action_unsupported',
          'The requested Scene action is unsupported.',
        );
    }
  }

  ProjectManifest updateDialogueChoicePolicy(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required SceneDialogueChoicePolicy choicePolicy,
    required RuntimeDialogueDocument dialogue,
  }) {
    final scene = _requireDialoguePolicyScene(project, sceneId);
    _requireDialoguePolicyNode(scene, nodeId);
    late final SceneAsset updated;
    try {
      updated = updateSceneDialogueChoicePolicy(scene, nodeId: nodeId,
        dialogue: dialogue, choicePolicy: choicePolicy);
    } on Object catch (error) {
      throw NarrativeAuthoringException('scene.dialogue.choice_policy.invalid',
        'The choice policy does not resolve against the compiled dialogue.',
        details: {'sceneId': sceneId, 'nodeId': nodeId, 'validationType': error.runtimeType.toString()});
    }
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest updateDialogueLineFeedback(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required SceneDialogueLinePolicy linePolicy,
    required RuntimeDialogueDocument dialogue,
  }) {
    final scene = _requireDialoguePolicyScene(project, sceneId,
      errorPrefix: 'scene.dialogue.line_feedback');
    _requireDialoguePolicyNode(scene, nodeId,
      errorPrefix: 'scene.dialogue.line_feedback');
    late final SceneAsset updated;
    try {
      updated = updateSceneDialogueLinePolicy(scene, nodeId: nodeId,
        dialogue: dialogue, linePolicy: linePolicy);
      final payload = updated.graph.nodes.firstWhere((node) => node.id == nodeId).payload as SceneYarnDialoguePayload;
      validateDialogueLineFeedbackAgainstProject(project: project, document: dialogue, policies: payload.linePolicies);
    } on ValidationException catch (error) {
      throw NarrativeAuthoringException('scene.dialogue.line_feedback.invalid',
        'The line feedback does not resolve against the compiled dialogue and project media.',
        details: {'sceneId': sceneId, 'nodeId': nodeId, 'validationType': error.runtimeType.toString()});
    } on ArgumentError catch (error) {
      throw NarrativeAuthoringException('scene.dialogue.line_feedback.invalid',
        'The line feedback does not resolve against the compiled dialogue and project media.',
        details: {'sceneId': sceneId, 'nodeId': nodeId, 'validationType': error.runtimeType.toString()});
    } on FormatException catch (error) {
      throw NarrativeAuthoringException('scene.dialogue.line_feedback.invalid',
        'The line feedback does not resolve against the compiled dialogue and project media.',
        details: {'sceneId': sceneId, 'nodeId': nodeId, 'validationType': error.runtimeType.toString()});
    }
    return upsert(project, maps: maps, scene: updated);
  }

  AuthoringMutationDraft _buildGraphEdit(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    final action = context.request.actionId;
    final sceneId = narrativeStringParameter(parameters, 'sceneId');
    final before = _requireDialoguePolicyScene(
      context.snapshot.manifest,
      sceneId,
    );
    late ProjectManifest projected;
    if (action == 'scene.graph.patch') {
      rejectUnknownNarrativeParameters(parameters, const {
        'sceneId',
        'upsertNodes',
        'removeNodeIds',
        'upsertEdges',
        'removeEdgeIds',
      });
      List<T> objects<T>(String key, T Function(Map<String, dynamic>) decode) {
        final value = parameters[key] ?? const <Object?>[];
        if (value is! List || value.any((item) => item is! Map)) {
          throw NarrativeAuthoringException(
            'scene.graph.invalid_patch',
            'Expected a list of typed graph objects.',
            details: {'field': key},
          );
        }
        return [
          for (final item in value)
            decode(Map<String, dynamic>.from(item as Map)),
        ];
      }

      List<String> ids(String key) {
        final value = parameters[key] ?? const <String>[];
        if (value is! List ||
            value.any(
              (item) =>
                  item is! String || item.trim().isEmpty || item.trim() != item,
            )) {
          throw NarrativeAuthoringException(
            'scene.graph.invalid_patch',
            'Expected a list of graph identities.',
            details: {'field': key},
          );
        }
        return value.cast<String>();
      }

      try {
        projected = patchGraph(
          context.snapshot.manifest,
          presentationMediaCatalog: _presentationMedia(context),
          maps: context.snapshot.maps,
          sceneId: sceneId,
          upsertNodes: objects('upsertNodes', SceneNode.fromJson),
          upsertEdges: objects('upsertEdges', SceneEdge.fromJson),
          removeNodeIds: ids('removeNodeIds'),
          removeEdgeIds: ids('removeEdgeIds'),
        );
      } on FormatException {
        throw NarrativeAuthoringException(
          'scene.graph.invalid_patch',
          'The graph patch payload is invalid.',
          details: {'sceneId': sceneId},
        );
      } on ArgumentError {
        throw NarrativeAuthoringException(
          'scene.graph.invalid_patch',
          'The graph patch payload is invalid.',
          details: {'sceneId': sceneId},
        );
      } on ValidationException {
        throw NarrativeAuthoringException(
          'scene.graph.invalid_patch',
          'The graph patch payload is invalid.',
          details: {'sceneId': sceneId},
        );
      }
    } else {
      final condition = action == 'scene.condition.set';
      rejectUnknownNarrativeParameters(parameters, {
        'sceneId',
        'nodeId',
        condition ? 'conditionSource' : 'command',
      });
      final nodeId = narrativeStringParameter(parameters, 'nodeId');
      final node = before.graph.nodes
          .where((node) => node.id == nodeId)
          .firstOrNull;
      if (node == null ||
          node.kind !=
              (condition ? SceneNodeKind.condition : SceneNodeKind.action)) {
        throw NarrativeAuthoringException(
          'scene.graph.node_kind_required',
          'The selected node has an incompatible kind.',
          details: {'sceneId': sceneId, 'nodeId': nodeId},
        );
      }
      late SceneNodePayload payload;
      final existingAction = node.payload is SceneActionPayload
          ? node.payload as SceneActionPayload
          : null;
      try {
        if (condition) {
          payload = SceneConditionPayload(
            conditionSource: SceneConditionSource.fromJson(
              narrativeObjectParameter(parameters, 'conditionSource'),
            ),
          );
        } else {
          final command = SceneInteractiveCommand.fromJson(
            narrativeObjectParameter(parameters, 'command'),
          );
          payload = command is SceneActorRouteInteractiveCommand
              ? buildSceneActorRoutePayload(
                  target: command.target,
                  steps: command.steps,
                  skippable: command.skippable,
                  transientScope: command.transientScope,
                  actionKind: existingAction?.actionKind,
                  parameters: existingAction?.parameters ?? const {},
                )
              : SceneActionPayload.interactive(
                  command,
                  actionKind: existingAction?.actionKind,
                  parameters: existingAction?.parameters ?? const {},
                );
        }
      } on FormatException {
        throw NarrativeAuthoringException(
          'scene.graph.payload_invalid',
          'The typed node payload is invalid.',
          details: {'sceneId': sceneId, 'nodeId': nodeId},
        );
      } on ArgumentError {
        throw NarrativeAuthoringException(
          'scene.graph.payload_invalid',
          'The typed node payload is invalid.',
          details: {'sceneId': sceneId, 'nodeId': nodeId},
        );
      } on ValidationException {
        throw NarrativeAuthoringException(
          'scene.graph.payload_invalid',
          'The typed node payload is invalid.',
          details: {'sceneId': sceneId, 'nodeId': nodeId},
        );
      }
      if (payload case SceneActionPayload(
        interactiveCommand: SceneWarpInteractiveCommand(
          :final destinationMapId,
          :final warpId,
        ),
      )) {
        final destination = context.snapshot.maps
            .where((map) => map.id == destinationMapId)
            .firstOrNull;
        if (destination == null ||
            !destination.warps.any((warp) => warp.id == warpId)) {
          throw NarrativeAuthoringException(
            'scene.warp.arrival_missing',
            'The arrival point must belong to the destination map.',
            details: {'destinationMapId': destinationMapId, 'warpId': warpId},
          );
        }
      }
      projected = patchGraph(
        context.snapshot.manifest,
        presentationMediaCatalog: _presentationMedia(context),
        maps: context.snapshot.maps,
        sceneId: sceneId,
        upsertNodes: [
          SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: payload,
          ),
        ],
      );
    }
    final after = projected.scenes.singleWhere((scene) => scene.id == sceneId);
    _validateSceneDialoguePolicies(context.snapshot, after);
    return narrativeProjectDraft(
      context.snapshot,
      projected,
      operation: action,
      path: '/scenes/$sceneId/graph',
      before: before.graph.toJson(),
      after: after.graph.toJson(),
    );
  }

  ProjectManifest patchGraph(
    ProjectManifest project, {
    ProjectMediaCatalog? presentationMediaCatalog,
    required List<MapData> maps,
    required String sceneId,
    List<SceneNode> upsertNodes = const [],
    List<String> removeNodeIds = const [],
    List<SceneEdge> upsertEdges = const [],
    List<String> removeEdgeIds = const [],
  }) {
    final scene = _requireDialoguePolicyScene(project, sceneId);
    void validateIds(
      String field,
      List<String> additions,
      List<String> removals,
      Set<String> existing,
    ) {
      if (additions.toSet().length != additions.length ||
          removals.toSet().length != removals.length ||
          removals.any(
            (id) => !existing.contains(id) || additions.contains(id),
          )) {
        throw NarrativeAuthoringException(
          'scene.graph.identity_conflict',
          'Graph edits contain conflicting or unknown identities.',
          details: {'sceneId': sceneId, 'field': field},
        );
      }
    }

    validateIds(
      'nodes',
      upsertNodes.map((node) => node.id).toList(),
      removeNodeIds,
      scene.graph.nodes.map((node) => node.id).toSet(),
    );
    validateIds(
      'edges',
      upsertEdges.map((edge) => edge.id).toList(),
      removeEdgeIds,
      scene.graph.edges.map((edge) => edge.id).toSet(),
    );
    final nodeUpdates = {for (final node in upsertNodes) node.id: node};
    final edgeUpdates = {for (final edge in upsertEdges) edge.id: edge};
    final nodes = [
      for (final node in scene.graph.nodes)
        if (!removeNodeIds.contains(node.id))
          nodeUpdates.remove(node.id) ?? node,
      ...nodeUpdates.values,
    ];
    final edges = [
      for (final edge in scene.graph.edges)
        if (!removeEdgeIds.contains(edge.id))
          edgeUpdates.remove(edge.id) ?? edge,
      ...edgeUpdates.values,
    ];
    late SceneAsset updated;
    try {
      updated = SceneAsset.fromJson({
        ...scene.toJson(),
        'graph': SceneGraph(
          startNodeId: scene.graph.startNodeId,
          nodes: nodes,
          edges: edges,
        ).toJson(),
        'layout': SceneGraphLayout(
          nodeLayouts: [
            for (final item in scene.layout.nodeLayouts)
              if (!removeNodeIds.contains(item.nodeId)) item,
          ],
          edgeLayouts: [
            for (final item in scene.layout.edgeLayouts)
              if (!removeEdgeIds.contains(item.edgeId)) item,
          ],
        ).toJson(),
      });
    } on ValidationException {
      throw NarrativeAuthoringException(
        'scene.graph.invalid_patch',
        'Graph edits would leave invalid references.',
        details: {'sceneId': sceneId},
      );
    }
    return upsert(project, maps: maps, scene: updated,
        presentationMediaCatalog: presentationMediaCatalog);
  }

  ProjectManifest upsert(
    ProjectManifest project, {
    required List<MapData> maps,
    required SceneAsset scene,
    ProjectItemCatalog? itemCatalog,
    ProjectMediaCatalog? presentationMediaCatalog,
  }) {
    final exists = project.scenes.any((candidate) => candidate.id == scene.id);
    final projected = project.copyWith(
      scenes: exists
          ? [
              for (final candidate in project.scenes)
                if (candidate.id == scene.id) scene else candidate,
            ]
          : [...project.scenes, scene],
    );
    _validateScenePublication(
      projected,
      maps: maps,
      scene: scene,
      itemCatalog: itemCatalog,
      presentationMediaCatalog: presentationMediaCatalog,
    );
    return projected;
  }

  ProjectManifest upsertBatch(
    ProjectManifest project, {
    required List<MapData> maps,
    required List<SceneAsset> scenes,
    ProjectItemCatalog? itemCatalog,
    ProjectMediaCatalog? presentationMediaCatalog,
  }) {
    if (scenes.isEmpty || scenes.length > 128) {
      throw NarrativeAuthoringException('scene.batch_invalid',
          'A Scene batch must contain between 1 and 128 scenes.');
    }
    final replacements = <String, SceneAsset>{};
    for (var index = 0; index < scenes.length; index++) {
      final scene = scenes[index];
      if (replacements.containsKey(scene.id)) {
        throw NarrativeAuthoringException('scene.batch_duplicate_id',
            'Scene identities must be unique within a batch.',
            details: {'index': index, 'sceneId': scene.id});
      }
      replacements[scene.id] = scene;
    }
    final existingIds = project.scenes.map((scene) => scene.id).toSet();
    final projected = project.copyWith(scenes: [
      for (final scene in project.scenes) replacements[scene.id] ?? scene,
      for (final scene in scenes) if (!existingIds.contains(scene.id)) scene,
    ]);
    final context = SceneProjectDiagnosticsContext(projected,
        presentationMediaCatalog: presentationMediaCatalog,
        availableItemIds: itemCatalog?.entries.map((item) => item.id).toSet(),
        mapsById: {for (final map in maps) map.id: map});
    for (final scene in scenes) {
      _validateScenePublication(projected, maps: maps, scene: scene,
          itemCatalog: itemCatalog, context: context);
    }
    return projected;
  }

  void validateAll(
    ProjectManifest project, {
    required List<MapData> maps,
    ProjectItemCatalog? itemCatalog,
    ProjectMediaCatalog? presentationMediaCatalog,
    void Function(SceneProjectDiagnosticsContext context)? onContextBuilt,
  }) {
    for (final _ in validateInOrder(project,
      maps: maps,
      itemCatalog: itemCatalog,
      presentationMediaCatalog: presentationMediaCatalog,
      onContextBuilt: onContextBuilt,
    )) {}
  }

  Iterable<SceneAsset> validateInOrder(
    ProjectManifest project, {
    required List<MapData> maps,
    ProjectItemCatalog? itemCatalog,
    ProjectMediaCatalog? presentationMediaCatalog,
    void Function(SceneProjectDiagnosticsContext context)? onContextBuilt,
  }) sync* {
    final context = SceneProjectDiagnosticsContext(
      project,
      presentationMediaCatalog: presentationMediaCatalog,
      availableItemIds: itemCatalog?.entries.map((item) => item.id).toSet(),
      mapsById: {for (final map in maps) map.id: map},
    );
    onContextBuilt?.call(context);
    for (final scene in project.scenes) {
      _validateScenePublication(
        project,
        maps: maps,
        scene: scene,
        itemCatalog: itemCatalog,
        context: context,
      );
      yield scene;
    }
  }

  void _validateScenePublication(
    ProjectManifest project, {
    required List<MapData> maps,
    required SceneAsset scene,
    ProjectItemCatalog? itemCatalog,
    ProjectMediaCatalog? presentationMediaCatalog,
    SceneProjectDiagnosticsContext? context,
  }) {
    final diagnostics = context?.diagnose(scene) ?? diagnoseSceneAgainstProject(
      scene,
      project,
      presentationMediaCatalog: presentationMediaCatalog,
      availableItemIds: itemCatalog?.entries.map((item) => item.id).toSet(),
      mapsById: {for (final map in maps) map.id: map},
    );
    final runtimePlan = buildSceneRuntimePlan(scene);
    if (diagnostics.hasErrors || !runtimePlan.canBuild) {
      throw NarrativeAuthoringException(
        'scene.publication_blocked',
        'The Scene is not safe for the canonical runtime.',
        details: {
          'diagnostics': [
            for (final item in diagnostics.diagnostics)
              {
                'code': item.code.name,
                'severity': item.severity.name,
                'message': item.message,
                if (item.nodeId != null) 'nodeId': item.nodeId,
                if (item.edgeId != null) 'edgeId': item.edgeId,
              },
          ],
          'runtimePlanBuildable': runtimePlan.canBuild,
        },
      );
    }
  }

  ProjectManifest createPreSessionScene(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String name,
    required String templateId,
    required bool setAsEntrypoint,
  }) {
    if (project.scenes.any((scene) => scene.id == sceneId)) {
      throw NarrativeAuthoringException(
        'scene.preSession.duplicate',
        'The preSession Scene identity already exists.',
        details: <String, Object?>{'sceneId': sceneId},
      );
    }
    final scene = _createPreSessionTemplate(
      project,
      sceneId: sceneId,
      name: name,
      templateId: templateId,
    );
    var projected = upsert(project, maps: maps, scene: scene);
    if (setAsEntrypoint) {
      projected = projected.copyWith(
        newGame: ProjectNewGameConfig.fromJson(<String, dynamic>{
          ...projected.newGame.toJson(),
          'preSessionSceneId': scene.id,
        }),
      );
    }
    return projected;
  }

  /// Replaces the authored branches of one interaction cue — BETA-CIN-079.
  ///
  /// The cue must already be linked: routes speak about the output ports of
  /// the bound awaitable node, and map_core validates them against it.
  ProjectManifest setPresentationCueOutcomeRoutes(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String presentationNodeId,
    required String markerId,
    required List<ScenePresentationCueOutcomeRoute> routes,
  }) {
    final scene = project.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (scene == null) {
      throw NarrativeAuthoringException(
        'scene.unknown',
        'The Scene identity is unknown.',
        details: <String, Object?>{'sceneId': sceneId},
      );
    }
    try {
      final updated = updateScenePresentationCueOutcomeRoutes(
        scene,
        presentationNodeId: presentationNodeId,
        markerId: markerId,
        routes: routes,
      ).updatedScene;
      return upsert(project, maps: maps, scene: updated);
    } on ArgumentError catch (error) {
      throw NarrativeAuthoringException(
        'scene.presentation.cue.routes.invalid',
        '${error.message}',
        details: <String, Object?>{
          'presentationNodeId': presentationNodeId,
          'markerId': markerId,
        },
      );
    } on ValidationException catch (error) {
      throw NarrativeAuthoringException(
        'scene.presentation.cue.routes.invalid',
        error.message,
        details: <String, Object?>{
          'presentationNodeId': presentationNodeId,
          'markerId': markerId,
        },
      );
    }
  }

  ProjectManifest insertPreSessionInteraction(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String targetNodeId,
    required ScenePreSessionInteractionSpec interaction,
    String? title,
    ScenePreSessionInteractionCueBindingDraft? cueBinding,
  }) {
    final scene = _requirePreSessionScene(project, sceneId);
    _validatePreSessionInteractionBinding(project, interaction);
    var updated = _insertLinearNode(
      scene,
      node: SceneNode(
        id: nodeId,
        kind: SceneNodeKind.action,
        title: title,
        payload: SceneActionPayload.preSessionInteraction(interaction),
      ),
      targetNodeId: targetNodeId,
      outgoingEdgeKind: SceneEdgeKind.actionCompleted,
      outgoingPortIds: interaction.outputPortIds,
    );
    if (cueBinding != null) {
      _validateInteractionCueBinding(
        project,
        scene: updated,
        binding: cueBinding,
      );
      updated = updateScenePresentationInteractionCueBinding(
        updated,
        presentationNodeId: cueBinding.presentationNodeId,
        markerId: cueBinding.markerId,
        awaitableNodeId: nodeId,
      ).updatedScene;
    }
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest updatePreSessionInteraction(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required ScenePreSessionInteractionSpec interaction,
    bool replaceCueBinding = false,
    ScenePreSessionInteractionCueBindingDraft? cueBinding,
  }) {
    final scene = _requirePreSessionScene(project, sceneId);
    _validatePreSessionInteractionBinding(project, interaction);
    var updated = updateScenePreSessionInteractionPayload(
      scene,
      nodeId: nodeId,
      interaction: interaction,
    ).updatedScene;
    updated = _reconcileInteractionOutputEdges(
      updated,
      nodeId: nodeId,
      outputPortIds: interaction.outputPortIds,
    );
    if (replaceCueBinding) {
      updated = _withoutInteractionCueBindings(
        updated,
        awaitableNodeId: nodeId,
      );
      if (cueBinding != null) {
        _validateInteractionCueBinding(
          project,
          scene: updated,
          binding: cueBinding,
        );
        updated = updateScenePresentationInteractionCueBinding(
          updated,
          presentationNodeId: cueBinding.presentationNodeId,
          markerId: cueBinding.markerId,
          awaitableNodeId: nodeId,
        ).updatedScene;
      }
    }
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest insertPreSessionPresentation(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String targetNodeId,
    required String presentationCinematicId,
    String? title,
  }) {
    if (!project.presentationCinematics
        .any((asset) => asset.id == presentationCinematicId)) {
      throw NarrativeAuthoringException(
        'scene.preSession.presentation.unknown',
        'The Presentation Cinematic identity is unknown.',
        details: <String, Object?>{
          'presentationCinematicId': presentationCinematicId,
        },
      );
    }
    final scene = _requirePreSessionScene(project, sceneId);
    final updated = _insertLinearNode(
      scene,
      node: SceneNode(
        id: nodeId,
        kind: SceneNodeKind.presentationCinematic,
        title: title,
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: presentationCinematicId,
        ),
      ),
      targetNodeId: targetNodeId,
      outgoingEdgeKind: SceneEdgeKind.presentationCompleted,
    );
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest createAndLinkPreSessionPresentation(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String targetNodeId,
    required PresentationCinematicAsset cinematic,
    ProjectMediaCatalog? mediaCatalog,
    Iterable<ProjectMediaSourceAssetDefinition> sourceAssets = const [],
    required String? targetFolderId,
    required int targetIndex,
  }) {
    if (!supportsPresentationProjectVersion(project)) {
      throw NarrativeAuthoringException(
        'scene.preSession.presentation.project_version_unsupported',
        'Presentation create-and-link requires ProjectVersion.v8 (2D) or ProjectVersion.v9 (3D).',
      );
    }
    final cinematicId = cinematic.id;
    final catalogCollision = project.cinematicLibraryCatalog.entryFor(
      CinematicLibraryFamily.presentation,
      cinematicId,
    );
    if (project.presentationCinematics.any(
          (candidate) => candidate.id == cinematicId,
        ) ||
        catalogCollision != null) {
      throw NarrativeAuthoringException(
        'scene.preSession.presentation.cinematic_id_unavailable',
        'The requested Presentation Cinematic identity already exists.',
        details: <String, Object?>{'cinematicId': cinematicId},
      );
    }
    final withAsset = project.copyWith(
      presentationCinematics: <PresentationCinematicAsset>[
        ...project.presentationCinematics,
        cinematic,
      ],
    );
    final catalog = const CinematicLibraryCatalogOperations().placeCinematic(
      withAsset.cinematicLibraryCatalog,
      family: CinematicLibraryFamily.presentation,
      cinematicId: cinematicId,
      targetFolderId: targetFolderId,
      targetIndex: targetIndex,
    );
    final withCatalog = withAsset.copyWith(cinematicLibraryCatalog: catalog);
    final projected = insertPreSessionPresentation(
      withCatalog,
      maps: maps,
      sceneId: sceneId,
      nodeId: nodeId,
      targetNodeId: targetNodeId,
      presentationCinematicId: cinematicId,
      title: cinematic.title,
    );
    ProjectValidator.validate(projected);
    final referenceDiagnostics = PresentationReferenceGraph.build(
      cinematics: projected.presentationCinematics,
      scenes: projected.scenes,
      mediaCatalog: mediaCatalog,
      sourceAssets: sourceAssets,
    ).diagnostics;
    if (referenceDiagnostics.isNotEmpty) {
      throw NarrativeAuthoringException(
        'scene.preSession.presentation.reference_validation_failed',
        'The Presentation create-and-link projection contains invalid references.',
        details: <String, Object?>{
          'diagnostics': <Object?>[
            for (final diagnostic in referenceDiagnostics) diagnostic.toJson(),
          ],
        },
      );
    }
    return projected;
  }

  ProjectManifest insertPreSessionCondition(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String targetNodeId,
    required String falseEndNodeId,
    required ScenePreSessionDraftField draftField,
    required SceneConditionOperator operator,
    String? value,
    String? title,
  }) {
    final scene = _requirePreSessionScene(project, sceneId);
    _requireNewNodeIds(scene, <String>[nodeId, falseEndNodeId]);
    final target = _requireTargetNode(scene, targetNodeId);
    if (target.kind == SceneNodeKind.start) {
      throw NarrativeAuthoringException(
        'scene.preSession.target.invalid',
        'A node cannot be inserted before the Scene start.',
      );
    }
    final incoming = _singleIncomingEdge(scene, targetNodeId);
    final nodes = <SceneNode>[
      ...scene.graph.nodes,
      SceneNode(
        id: nodeId,
        kind: SceneNodeKind.condition,
        title: title,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.newGameDraft,
            sourceId: draftField.name,
            operator: operator,
            value: value,
            label: draftField.name,
          ),
        ),
      ),
      SceneNode(id: falseEndNodeId, kind: SceneNodeKind.end),
    ];
    final edges = <SceneEdge>[
      for (final edge in scene.graph.edges)
        if (edge.id == incoming.id) _copyEdge(edge, toNodeId: nodeId) else edge,
      SceneEdge(
        id: _edgeId(nodeId, 'true', targetNodeId),
        fromNodeId: nodeId,
        fromPortId: 'true',
        toNodeId: targetNodeId,
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: _edgeId(nodeId, 'false', falseEndNodeId),
        fromNodeId: nodeId,
        fromPortId: 'false',
        toNodeId: falseEndNodeId,
        kind: SceneEdgeKind.conditionFalse,
      ),
    ];
    final updated = _copyScene(
      scene,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: nodes,
        edges: edges,
      ),
    );
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest configurePreSessionEnd(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required String outcomeId,
    required String outcomeLabel,
    required SceneOutcomePolicy outcomePolicy,
  }) {
    final scene = _requirePreSessionScene(project, sceneId);
    final nodeIndex = scene.graph.nodes.indexWhere((node) => node.id == nodeId);
    if (nodeIndex < 0 ||
        scene.graph.nodes[nodeIndex].kind != SceneNodeKind.end) {
      throw NarrativeAuthoringException(
        'scene.preSession.end.required',
        'The selected preSession node is not an end node.',
        details: <String, Object?>{'nodeId': nodeId},
      );
    }
    final nodes = <SceneNode>[];
    final generatedOutcomes = <SceneOutcome>[];
    for (final node in scene.graph.nodes) {
      if (node.id == nodeId) {
        nodes.add(
          SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: SceneEndPayload(
              sceneOutcomeId: outcomeId,
              outcomePolicy: outcomePolicy,
            ),
          ),
        );
        continue;
      }
      final payload = node.payload;
      if (node.kind == SceneNodeKind.end &&
          payload is SceneEndPayload &&
          payload.sceneOutcomeId == null) {
        final generatedOutcomeId = 'outcome_${node.id}';
        nodes.add(
          SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: SceneEndPayload(
              sceneOutcomeId: generatedOutcomeId,
              outcomePolicy: SceneOutcomePolicy.retryable,
            ),
          ),
        );
        generatedOutcomes.add(
          SceneOutcome(
            id: generatedOutcomeId,
            label: node.title ?? node.id,
          ),
        );
        continue;
      }
      nodes.add(node);
    }
    final outcomes = <SceneOutcome>[
      for (final outcome in scene.declaredOutcomes)
        if (outcome.id != outcomeId &&
            !generatedOutcomes.any((generated) => generated.id == outcome.id))
          outcome,
      ...generatedOutcomes,
      SceneOutcome(id: outcomeId, label: outcomeLabel),
    ];
    final updated = _copyScene(
      scene,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: nodes,
        edges: scene.graph.edges,
      ),
      declaredOutcomes: outcomes,
    );
    return upsert(project, maps: maps, scene: updated);
  }

  ProjectManifest delete(
    ProjectManifest project, {
    required String sceneId,
    String? replacementSceneId,
  }) {
    final result = deleteSceneFromProject(
      project,
      sceneId: sceneId,
      replacementSceneId: replacementSceneId,
      dependencyIndex: buildNarrativeDependencyIndex(project: project),
    );
    if (!result.isApplied) {
      throw NarrativeAuthoringException(
        result.code ?? 'scene.delete_rejected',
        result.message ?? 'The canonical Scene deletion was rejected.',
        details: {'referencePaths': result.referencePaths},
      );
    }
    return result.after;
  }

  ProjectManifest setCharacterAnimationCommand(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required CharacterCustomAnimationRuntimeCommand command,
  }) {
    _validateSceneCharacterAnimationCommand(project, command);
    final scene = project.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (scene == null) {
      throw NarrativeAuthoringException(
        'scene.unknown',
        'The Scene identity is unknown.',
        details: <String, Object?>{'sceneId': sceneId},
      );
    }
    final nodeIndex = scene.graph.nodes.indexWhere((node) => node.id == nodeId);
    if (nodeIndex < 0 ||
        scene.graph.nodes[nodeIndex].kind != SceneNodeKind.action) {
      throw NarrativeAuthoringException(
        'scene.character_animation.action_node_required',
        'Character animations require an existing Scene action node.',
        details: <String, Object?>{'nodeId': nodeId},
      );
    }
    final beforeNode = scene.graph.nodes[nodeIndex];
    final nodes = scene.graph.nodes.toList();
    nodes[nodeIndex] = SceneNode(
      id: beforeNode.id,
      kind: beforeNode.kind,
      title: beforeNode.title,
      description: beforeNode.description,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.playCharacterAnimation(
          runtimeCommand: command,
        ),
      ),
    );
    final updatedScene = SceneAsset(
      id: scene.id,
      name: scene.name,
      description: scene.description,
      storylineId: scene.storylineId,
      chapterId: scene.chapterId,
      tags: scene.tags,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: nodes,
        edges: scene.graph.edges,
      ),
      layout: scene.layout,
      declaredOutcomes: scene.declaredOutcomes,
      metadata: scene.metadata,
    );
    return upsert(project, maps: maps, scene: updatedScene);
  }

  ProjectManifest setPauseMenuEntryVisibility(
    ProjectManifest project, {
    required List<MapData> maps,
    required String sceneId,
    required String nodeId,
    required ProjectPauseActionId actionId,
    required bool visible,
  }) {
    final scene = project.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (scene == null) {
      throw NarrativeAuthoringException(
        'scene.unknown',
        'The Scene identity is unknown.',
        details: <String, Object?>{'sceneId': sceneId},
      );
    }
    final updated = updateSceneActionConsequencePayload(
      scene,
      nodeId: nodeId,
      consequence: SceneConsequence.setPauseMenuEntryVisibility(
        actionId: actionId,
        visible: visible,
      ),
    );
    return upsert(project, maps: maps, scene: updated.updatedScene);
  }
}

List<ScenePresentationCueOutcomeRoute> _decodeCueOutcomeRoutes(
  Map<String, Object?> parameters,
) {
  final raw = parameters['routes'];
  if (raw is! List) {
    throw ArgumentError.value(raw, 'routes', 'must be a list');
  }
  return <ScenePresentationCueOutcomeRoute>[
    for (final entry in raw)
      if (entry is Map)
        ScenePresentationCueOutcomeRoute.fromJson(<String, dynamic>{
          for (final pair in entry.entries)
            if (pair.key is String) pair.key as String: pair.value,
        })
      else
        throw ArgumentError.value(entry, 'routes', 'must contain objects'),
  ];
}

ScenePreSessionInteractionCueBindingDraft? _decodeOptionalCueBinding(
  Map<String, Object?> parameters,
) {
  if (!parameters.containsKey('cueBinding') ||
      parameters['cueBinding'] == null) {
    return null;
  }
  final raw = parameters['cueBinding'];
  if (raw is! Map) {
    throw ArgumentError.value(raw, 'cueBinding', 'must be an object or null');
  }
  final value = <String, Object?>{
    for (final entry in raw.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
  rejectUnknownNarrativeParameters(
    value,
    const {'presentationNodeId', 'markerId'},
  );
  return ScenePreSessionInteractionCueBindingDraft(
    presentationNodeId: narrativeStringParameter(value, 'presentationNodeId'),
    markerId: narrativeStringParameter(value, 'markerId'),
  );
}

void _validateInteractionCueBinding(
  ProjectManifest project, {
  required SceneAsset scene,
  required ScenePreSessionInteractionCueBindingDraft binding,
}) {
  final presentationNode = scene.graph.nodes
      .where((node) => node.id == binding.presentationNodeId)
      .firstOrNull;
  final payload = presentationNode?.payload;
  if (presentationNode?.kind != SceneNodeKind.presentationCinematic ||
      payload is! ScenePresentationCinematicPayload) {
    throw NarrativeAuthoringException(
      'scene.preSession.interaction.presentation_node_unknown',
      'The interaction cue must target a Presentation node in the Scene.',
      details: <String, Object?>{
        'presentationNodeId': binding.presentationNodeId,
      },
    );
  }
  final cinematic = project.presentationCinematics
      .where((asset) => asset.id == payload.presentationCinematicId)
      .firstOrNull;
  final markerExists = cinematic?.tracks.any(
        (track) => track.clips.any(
          (clip) =>
              clip is PresentationMarkerClip &&
              clip.id == binding.markerId &&
              clip.markerKind == PresentationMarkerKind.interactionCue,
        ),
      ) ??
      false;
  if (!markerExists) {
    throw NarrativeAuthoringException(
      'scene.preSession.interaction.marker_unknown',
      'The selected marker is not an Interaction cue of this Presentation.',
      details: <String, Object?>{
        'presentationCinematicId': payload.presentationCinematicId,
        'markerId': binding.markerId,
      },
    );
  }
}

SceneAsset _withoutInteractionCueBindings(
  SceneAsset scene, {
  required String awaitableNodeId,
}) {
  var updated = scene;
  final bindings = <(String, String)>[
    for (final node in scene.graph.nodes)
      if (node.payload case final ScenePresentationCinematicPayload payload)
        for (final binding in payload.interactionCueBindings)
          if (binding.awaitableNodeId == awaitableNodeId)
            (node.id, binding.markerId),
  ];
  for (final binding in bindings) {
    updated = updateScenePresentationInteractionCueBinding(
      updated,
      presentationNodeId: binding.$1,
      markerId: binding.$2,
      awaitableNodeId: null,
    ).updatedScene;
  }
  return updated;
}

ProjectPauseActionId _decodePauseActionId(String value) {
  try {
    return ProjectPauseActionId.values.byName(value);
  } on ArgumentError {
    throw ArgumentError.value(value, 'actionId', 'is not a pause menu entry');
  }
}

bool _booleanParameter(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}

void _validatePreSessionInteractionBinding(
  ProjectManifest project,
  ScenePreSessionInteractionSpec interaction,
) {
  final field = interaction.resultBinding?.field;
  if (field == null || field == ScenePreSessionDraftField.playerName) return;
  final allowedIds = switch (field) {
    ScenePreSessionDraftField.avatarCharacterId =>
      project.newGame.playerAvatarCharacterIds.toSet(),
    ScenePreSessionDraftField.starterOptionId =>
      project.newGame.starterOptions.map((option) => option.id).toSet(),
    ScenePreSessionDraftField.playerName => const <String>{},
  };
  final unknownIds = interaction.options
      .map((option) => option.id)
      .where((id) => !allowedIds.contains(id))
      .toList(growable: false);
  if (unknownIds.isNotEmpty) {
    throw NarrativeAuthoringException(
      'scene.preSession.binding.option_unknown',
      'A structured interaction option is not allowed by New Game config.',
      details: <String, Object?>{
        'draftField': field.name,
        'optionIds': unknownIds,
      },
    );
  }
}

AuthoringMutationDraft _preSessionProjectDraft(
  AuthoringPlanningContext context,
  ProjectManifest projected, {
  required String sceneId,
}) {
  final before = context.snapshot.manifest.scenes
      .where((scene) => scene.id == sceneId)
      .firstOrNull;
  final after =
      projected.scenes.where((scene) => scene.id == sceneId).firstOrNull;
  return narrativeProjectDraft(
    context.snapshot,
    projected,
    operation: context.request.actionId,
    path: '/scenes/$sceneId',
    before: before?.toJson(),
    after: after?.toJson(),
    includeInspectionPreview: true,
  );
}

SceneAsset _createPreSessionTemplate(
  ProjectManifest project, {
  required String sceneId,
  required String name,
  required String templateId,
}) {
  if (templateId == 'minimal') {
    return SceneAsset(
      id: sceneId,
      name: name,
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
  }
  if (templateId != 'identitySetup') {
    throw NarrativeAuthoringException(
      'scene.preSession.template.unknown',
      'The preSession Scene template is unknown.',
      details: <String, Object?>{'templateId': templateId},
    );
  }

  final authoredNodes = <SceneNode>[
    SceneNode(
      id: 'playerName',
      kind: SceneNodeKind.action,
      title: 'Nom du joueur',
      payload: SceneActionPayload.preSessionInteraction(
        ScenePreSessionInteractionSpec.text(
          prompt: SceneInteractionPrompt(
            localizationKey: 'newGame.playerName.prompt',
            fallbackText: 'Quel est ton nom ?',
          ),
          constraints: SceneTextInputConstraints(
            minGraphemes: 1,
            maxGraphemes: 24,
          ),
          resultBinding: const ScenePreSessionResultBinding(
            field: ScenePreSessionDraftField.playerName,
          ),
        ),
      ),
    ),
    if (project.newGame.playerAvatarCharacterIds.isNotEmpty)
      SceneNode(
        id: 'avatarCharacterId',
        kind: SceneNodeKind.action,
        title: 'Avatar',
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.selection(
            prompt: SceneInteractionPrompt(
              localizationKey: 'newGame.avatar.prompt',
              fallbackText: 'Choisis ton avatar',
            ),
            options: [
              for (final id in project.newGame.playerAvatarCharacterIds)
                SceneInteractionOption(
                  id: id,
                  label: SceneInteractionPrompt(
                    localizationKey: 'newGame.avatar.$id',
                    fallbackText: project.characters
                            .where((character) => character.id == id)
                            .firstOrNull
                            ?.name ??
                        'Personnage',
                  ),
                ),
            ],
            constraints: SceneSelectionConstraints(),
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.avatarCharacterId,
            ),
          ),
        ),
      ),
    if (project.newGame.starterOptions.isNotEmpty)
      SceneNode(
        id: 'starterOptionId',
        kind: SceneNodeKind.action,
        title: 'Starter',
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.selection(
            prompt: SceneInteractionPrompt(
              localizationKey: 'newGame.starter.prompt',
              fallbackText: 'Choisis ton starter',
            ),
            options: [
              for (final option in project.newGame.starterOptions)
                SceneInteractionOption(
                  id: option.id,
                  label: SceneInteractionPrompt(
                    localizationKey: 'newGame.starter.${option.id}',
                    fallbackText: option.label,
                  ),
                ),
            ],
            constraints: SceneSelectionConstraints(),
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.starterOptionId,
            ),
          ),
        ),
      ),
  ];
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    ...authoredNodes,
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  final orderedIds = nodes.map((node) => node.id).toList(growable: false);
  return SceneAsset(
    id: sceneId,
    name: name,
    executionProfile: SceneExecutionProfile.preSession,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var index = 0; index < orderedIds.length - 1; index += 1)
          SceneEdge(
            id: _edgeId(
              orderedIds[index],
              'completed',
              orderedIds[index + 1],
            ),
            fromNodeId: orderedIds[index],
            fromPortId: 'completed',
            toNodeId: orderedIds[index + 1],
            kind: index == 0
                ? SceneEdgeKind.defaultFlow
                : SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}

SceneAsset _insertLinearNode(
  SceneAsset scene, {
  required SceneNode node,
  required String targetNodeId,
  required SceneEdgeKind outgoingEdgeKind,
  List<String> outgoingPortIds = const <String>['completed'],
}) {
  _requireNewNodeIds(scene, <String>[node.id]);
  final target = _requireTargetNode(scene, targetNodeId);
  if (target.kind == SceneNodeKind.start) {
    throw NarrativeAuthoringException(
      'scene.preSession.target.invalid',
      'A node cannot be inserted before the Scene start.',
    );
  }
  final incoming = _singleIncomingEdge(scene, targetNodeId);
  return _copyScene(
    scene,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: <SceneNode>[...scene.graph.nodes, node],
      edges: <SceneEdge>[
        for (final edge in scene.graph.edges)
          if (edge.id == incoming.id)
            _copyEdge(edge, toNodeId: node.id)
          else
            edge,
        for (final outputPortId in outgoingPortIds)
          SceneEdge(
            id: _edgeId(node.id, outputPortId, targetNodeId),
            fromNodeId: node.id,
            fromPortId: outputPortId,
            toNodeId: targetNodeId,
            kind: outgoingEdgeKind,
          ),
      ],
    ),
  );
}

SceneAsset _reconcileInteractionOutputEdges(
  SceneAsset scene, {
  required String nodeId,
  required List<String> outputPortIds,
}) {
  final outgoing = scene.graph.edges
      .where((edge) => edge.fromNodeId == nodeId)
      .toList(growable: false);
  if (outgoing.isEmpty) {
    throw NarrativeAuthoringException(
      'scene.preSession.interaction.output_missing',
      'The structured interaction has no outgoing route.',
      details: <String, Object?>{'nodeId': nodeId},
    );
  }
  final existingByPort = <String, SceneEdge>{
    for (final edge in outgoing) edge.fromPortId: edge,
  };
  final fallbackTargetNodeId = outgoing.first.toNodeId;
  final outputPorts = outputPortIds.toSet();
  return _copyScene(
    scene,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: scene.graph.nodes,
      edges: <SceneEdge>[
        for (final edge in scene.graph.edges)
          if (edge.fromNodeId != nodeId ||
              outputPorts.contains(edge.fromPortId))
            edge,
        for (final outputPortId in outputPortIds)
          if (!existingByPort.containsKey(outputPortId))
            SceneEdge(
              id: _edgeId(nodeId, outputPortId, fallbackTargetNodeId),
              fromNodeId: nodeId,
              fromPortId: outputPortId,
              toNodeId: fallbackTargetNodeId,
              kind: SceneEdgeKind.actionCompleted,
            ),
      ],
    ),
  );
}

SceneAsset _requirePreSessionScene(ProjectManifest project, String sceneId) {
  final scene =
      project.scenes.where((scene) => scene.id == sceneId).firstOrNull;
  if (scene == null) {
    throw NarrativeAuthoringException(
      'scene.unknown',
      'The Scene identity is unknown.',
      details: <String, Object?>{'sceneId': sceneId},
    );
  }
  if (scene.executionProfile != SceneExecutionProfile.preSession) {
    throw NarrativeAuthoringException(
      'scene.preSession.profile_required',
      'The requested Scene is not a preSession Scene.',
      details: <String, Object?>{'sceneId': sceneId},
    );
  }
  return scene;
}

void _requireNewNodeIds(SceneAsset scene, List<String> nodeIds) {
  final existing = scene.graph.nodes.map((node) => node.id).toSet();
  final requested = <String>{};
  for (final nodeId in nodeIds) {
    if (!requested.add(nodeId) || existing.contains(nodeId)) {
      throw NarrativeAuthoringException(
        'scene.preSession.node.duplicate',
        'The preSession node identity already exists.',
        details: <String, Object?>{'nodeId': nodeId},
      );
    }
  }
}

SceneNode _requireTargetNode(SceneAsset scene, String targetNodeId) {
  final target =
      scene.graph.nodes.where((node) => node.id == targetNodeId).firstOrNull;
  if (target == null) {
    throw NarrativeAuthoringException(
      'scene.preSession.target.unknown',
      'The insertion target node is unknown.',
      details: <String, Object?>{'targetNodeId': targetNodeId},
    );
  }
  return target;
}

SceneEdge _singleIncomingEdge(SceneAsset scene, String targetNodeId) {
  final incoming = scene.graph.edges
      .where((edge) => edge.toNodeId == targetNodeId)
      .toList(growable: false);
  if (incoming.length != 1) {
    throw NarrativeAuthoringException(
      'scene.preSession.target.incoming_ambiguous',
      'The insertion target must have exactly one incoming edge.',
      details: <String, Object?>{
        'targetNodeId': targetNodeId,
        'incomingEdgeCount': incoming.length,
      },
    );
  }
  return incoming.single;
}

SceneAsset _copyScene(
  SceneAsset scene, {
  required SceneGraph graph,
  List<SceneOutcome>? declaredOutcomes,
}) {
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: graph,
    layout: scene.layout,
    declaredOutcomes: declaredOutcomes ?? scene.declaredOutcomes,
    metadata: scene.metadata,
  );
}

SceneEdge _copyEdge(SceneEdge edge, {required String toNodeId}) {
  return SceneEdge(
    id: edge.id,
    fromNodeId: edge.fromNodeId,
    fromPortId: edge.fromPortId,
    toNodeId: toNodeId,
    kind: edge.kind,
    label: edge.label,
  );
}

String _edgeId(String fromNodeId, String fromPortId, String toNodeId) =>
    'edge_${fromNodeId}_${fromPortId}_$toNodeId';

ScenePreSessionInteractionSpec _decodePreSessionInteraction(
  Map<String, dynamic> json,
) {
  try {
    return ScenePreSessionInteractionSpec.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.preSession.interaction.invalid',
      'The structured preSession interaction cannot be decoded.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

bool _optionalBoolParameter(
  Map<String, Object?> parameters,
  String key, {
  required bool fallback,
}) {
  final value = parameters[key];
  if (value == null) return fallback;
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}

String? _optionalStringParameter(
  Map<String, Object?> parameters,
  String key,
) {
  final value = parameters[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, key, 'must be a nonblank trimmed string');
  }
  return value;
}

String? _nullableStringParameter(
  Map<String, Object?> parameters,
  String key,
) {
  final value = parameters[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, key, 'must be null or a trimmed string');
  }
  return value;
}

int _integerParameter(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! int) {
    throw ArgumentError.value(value, key, 'must be an integer');
  }
  return value;
}

PresentationCinematicAsset _createAndLinkCinematic(
  Map<String, Object?> parameters,
) {
  final encoded = parameters['cinematic'];
  if (encoded != null) {
    final templateFields = const <String>[
      'cinematicId',
      'title',
      'templateId',
      'templateVersion',
    ].where(parameters.containsKey).toList(growable: false);
    if (templateFields.isNotEmpty) {
      throw ArgumentError.value(
        templateFields,
        'parameters',
        'cinematic cannot be combined with template fields',
      );
    }
    try {
      return decodePresentationCinematicAsset(encoded);
    } on PresentationCinematicCodecException catch (error) {
      throw NarrativeAuthoringException(
        'scene.preSession.presentation.draft_invalid',
        'The Presentation draft cannot be decoded.',
        details: <String, Object?>{
          'codecCode': error.code.name,
          'path': error.path,
        },
      );
    }
  }
  final cinematicId = narrativeStringParameter(parameters, 'cinematicId');
  final title = narrativeStringParameter(parameters, 'title');
  final templateId = narrativeStringParameter(parameters, 'templateId');
  final templateVersion = _integerParameter(parameters, 'templateVersion');
  return instantiatePresentationCinematicTemplate(
    _presentationTemplate(templateId, templateVersion),
    cinematicId: cinematicId,
    title: title,
    description: null,
  );
}

PresentationCinematicTemplate _presentationTemplate(
  String templateId,
  int templateVersion,
) {
  try {
    return PresentationCinematicTemplateCatalog.canonical().require(
      templateId,
      version: templateVersion,
    );
  } on PresentationCinematicTemplateException catch (error) {
    throw NarrativeAuthoringException(
      switch (error.code) {
        PresentationCinematicTemplateErrorCode.unknownTemplate =>
          'scene.preSession.presentation.template_unknown',
        PresentationCinematicTemplateErrorCode.unsupportedVersion =>
          'scene.preSession.presentation.template_version_unsupported',
      },
      error.message,
      details: <String, Object?>{
        'templateId': templateId,
        'templateVersion': templateVersion,
      },
    );
  }
}

T _enumParameter<T extends Enum>(
  Map<String, Object?> parameters,
  String key,
  List<T> values,
) {
  final value = narrativeStringParameter(parameters, key);
  return values.where((candidate) => candidate.name == value).firstOrNull ??
      (throw ArgumentError.value(value, key, 'contains an unknown value'));
}

SceneAsset _requireDialoguePolicyScene(ProjectManifest project, String sceneId, {
  String errorPrefix = 'scene.dialogue.choice_policy',
}) {
  final scene = project.scenes.where((candidate) => candidate.id == sceneId).firstOrNull;
  if (scene == null) throw NarrativeAuthoringException('$errorPrefix.scene_unknown', 'The Scene is unknown.');
  return scene;
}

SceneNode _requireDialoguePolicyNode(SceneAsset scene, String nodeId, {
  String errorPrefix = 'scene.dialogue.choice_policy',
}) {
  final node = scene.graph.nodes.where((candidate) => candidate.id == nodeId).firstOrNull;
  if (node == null || node.payload is! SceneYarnDialoguePayload) {
    throw NarrativeAuthoringException('$errorPrefix.node_unknown', 'The Scene dialogue node is unknown.');
  }
  return node;
}

RuntimeDialogueDocument _compilePolicyDialogue(ProjectSnapshot snapshot, String dialogueId, {
  String errorPrefix = 'scene.dialogue.choice_policy',
}) {
  final entry = snapshot.manifest.dialogues.where((candidate) => candidate.id == dialogueId).firstOrNull;
  if (entry == null) throw NarrativeAuthoringException('$errorPrefix.dialogue_unknown', 'The dialogue is unknown.');
  final bytes = snapshot.findResourceBytes(dialogueSourceResourceIdentity(dialogueId));
  if (bytes == null) throw NarrativeAuthoringException('$errorPrefix.source_missing', 'The dialogue source is missing.');
  final compiled = const DialogueAuthoringCompiler().compile(entry: entry, source: utf8.decode(bytes));
  if (!compiled.canPublish || compiled.document == null) {
    throw NarrativeAuthoringException('$errorPrefix.dialogue_invalid', 'The dialogue does not compile for publication.');
  }
  return compiled.document!;
}

void _validateSceneDialoguePolicies(ProjectSnapshot snapshot, SceneAsset scene) {
  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    if (payload is! SceneYarnDialoguePayload ||
        (payload.choicePolicies.isEmpty && payload.linePolicies.isEmpty)) {
      continue;
    }
    final document = _compilePolicyDialogue(snapshot, payload.dialogueId,
      errorPrefix: payload.linePolicies.isNotEmpty ? 'scene.dialogue.line_feedback' : 'scene.dialogue.choice_policy');
    try {
      validateSceneDialogueChoicePolicies(sceneDialogueChoiceScopes(document), payload.choicePolicies);
    } on ArgumentError {
      throw NarrativeAuthoringException('scene.dialogue.choice_policy.invalid', 'The Scene contains a dangling dialogue choice policy.');
    }
    try {
      validateDialogueLineFeedbackAgainstProject(project: snapshot.manifest, document: document, policies: payload.linePolicies);
    } on ArgumentError {
      throw NarrativeAuthoringException('scene.dialogue.line_feedback.invalid', 'The Scene contains incompatible dialogue line feedback.');
    } on FormatException {
      throw NarrativeAuthoringException('scene.dialogue.line_feedback.invalid', 'The Scene contains incompatible dialogue line feedback.');
    }
  }
}

SceneAsset _decodeScene(Map<String, dynamic> json) {
  try {
    return SceneAsset.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.invalid',
      'The Scene payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

CharacterCustomAnimationRuntimeCommand _decodeCharacterAnimationCommand(
  Map<String, dynamic> json,
) {
  try {
    return CharacterCustomAnimationRuntimeCommand.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.character_animation.command_invalid',
      'The Character Studio animation command cannot be decoded.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

void _validateSceneCharacterAnimationCommand(
  ProjectManifest project,
  CharacterCustomAnimationRuntimeCommand command,
) {
  CharacterCustomAnimationDefinition? definition;
  for (final candidate
      in project.characterStudioCatalog.customAnimationDefinitions) {
    if (candidate.id == command.definitionId) {
      definition = candidate;
      break;
    }
  }
  if (definition == null) {
    throw NarrativeAuthoringException(
      'scene.character_animation.definition_unknown',
      'The selected custom animation definition does not exist.',
      details: <String, Object?>{'definitionId': command.definitionId},
    );
  }
  if (definition.mode == CharacterCustomAnimationMode.single &&
      command.direction != null) {
    throw NarrativeAuthoringException(
      'scene.character_animation.direction_unexpected',
      'A single custom animation does not accept a direction.',
    );
  }
  if (definition.mode == CharacterCustomAnimationMode.directional &&
      command.direction == null) {
    throw NarrativeAuthoringException(
      'scene.character_animation.direction_required',
      'A directional custom animation requires a direction.',
    );
  }
}

ProjectMediaCatalog _presentationMedia(AuthoringPlanningContext context) {
  final bytes = context.snapshot.findResourceBytes(
    projectMediaCatalogResourceIdentity,
  );
  return bytes == null
      ? ProjectMediaCatalog()
      : decodeProjectMediaCatalogBytes(bytes);
}
