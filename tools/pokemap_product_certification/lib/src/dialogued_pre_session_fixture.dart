import 'package:map_core/map_core.dart';

import 'neutral_certification_game_fixture.dart';

/// One canonical semantic operation of the reference journey.
///
/// The sequence below is DATA, not four hand-written transport scripts: every
/// transport replays this same list, so BETA-CIN-083's "same project on the
/// four transports" is provable by construction rather than by comparing
/// copies that could drift apart independently.
final class DialoguedPreSessionAuthoringStep {
  const DialoguedPreSessionAuthoringStep({
    required this.actionId,
    required this.parameters,
  });

  final String actionId;
  final Map<String, Object?> parameters;
}

/// The dialogued pre-session of BETA-CIN-083, authored only through canonical
/// actions.
///
/// `presentationDialogueReferenceFixture` in map_core freezes the reference
/// journey as a state sequence — dialogue pages, avatar choice, name input,
/// negative confirmation returning to the input, autonomous montage, world
/// handoff — but nothing ever walked it on a real project. This fixture is
/// that project: the same journey expressed as authoring operations, so the
/// contract stops being a declaration and becomes something a package can be
/// built from.
///
/// Nothing here carries a Pokémon name, brand or asset: the scenario is a
/// lighthouse keeper taking a night watch.
final class DialoguedPreSessionFixture {
  const DialoguedPreSessionFixture();

  static const String sceneId = 'presession_night_watch';
  static const String sceneName = 'La veille de nuit';
  static const String cinematicId = 'presentation_night_watch_opening';

  static const String openingNodeId = 'opening';
  static const String pagesNodeId = 'read_pages';
  static const String avatarNodeId = 'pick_keeper';
  static const String nameNodeId = 'ask_name';
  static const String confirmNodeId = 'confirm_name';
  static const String closingNodeId = 'offer_closing';
  static const String endNodeId = 'end';

  static const String visualLayerId = 'layer_tower';
  static const String visualTrackId = 'visuals';
  static const String audioTrackId = 'audio';
  static const String markerTrackId = 'markers';

  /// The clip carrying BOTH orientation variants, and the one carrying NONE:
  /// the second is what proves an absent variant falls back rather than
  /// rendering nothing.
  static const String backdropClipId = 'clip_backdrop';
  static const String sharedOnlyClipId = 'clip_keeper_plate';
  static const String musicClipId = 'clip_lighthouse_music';
  static const String pagesMarkerId = 'cue_pages';
  static const String avatarMarkerId = 'cue_keeper';
  static const String nameMarkerId = 'cue_player_name';
  static const String confirmMarkerId = 'cue_confirm_name';
  static const String closingMarkerId = 'cue_closing';

  /// The seek target: a plain marker, not a cue. A jump resolves by marker
  /// IDENTITY, so the destination has to exist as an authored marker rather
  /// than as a hand-computed offset.
  static const String montageMarkerId = 'mark_autonomous_montage';

  /// The two silhouettes the project seed declares as playable avatars. An
  /// option bound to `avatarCharacterId` that New Game does not allow is
  /// refused by the authoring action, and an avatar id with no character
  /// behind it is refused by the project validator.
  static const String dawnKeeperOptionId = 'keeper_dawn';
  static const String duskKeeperOptionId = 'keeper_dusk';

  static const String outcomeId = 'ready';

  static const String backdropMediaId =
      NeutralCertificationGameFixture.backdropMediaId;
  static const String backdropWideMediaId =
      NeutralCertificationGameFixture.backdropWideMediaId;
  static const String backdropTallMediaId =
      NeutralCertificationGameFixture.backdropTallMediaId;
  static const String lighthouseMusicMediaId =
      NeutralCertificationGameFixture.lighthouseMusicMediaId;

  /// The capabilities a dialogued pre-session actually exercises. Declared
  /// here so the export profile and the host compatibility cannot disagree
  /// about what the package needs.
  static const Set<String> requiredSceneCapabilities = <String>{
    SceneExecutionCapabilityIds.flowStart,
    SceneExecutionCapabilityIds.flowEnd,
    SceneExecutionCapabilityIds.presentationCinematic,
    SceneExecutionCapabilityIds.inputMessage,
    SceneExecutionCapabilityIds.inputChoice,
    SceneExecutionCapabilityIds.inputText,
    SceneExecutionCapabilityIds.inputConfirmation,
  };

  /// The outcomes BETA-CIN-083 asks the scenario to cover, by the wire names
  /// BETA-CIN-070 froze.
  static const Set<String> coveredOutcomeWireNames = <String>{
    'continue',
    'repeatFromMarker',
    'seekMarker',
    'stop',
  };

  /// The journey, in the order the actions have to be applied.
  ///
  /// The interactions are inserted BACKWARDS, each before the node that
  /// follows it. Inserting them all before `end` cannot work: a choice has one
  /// output port per option and a confirmation has two, so the first
  /// multi-port node gives its successor several incoming edges and every
  /// later insert is refused as ambiguous.
  ///
  /// There is deliberately NO draft guard here. BETA-CIN-083's scope lists the
  /// pages, the avatar choice, the negative confirmation, the name input, the
  /// interpolation, the autonomous montage and the world handoff — not a
  /// condition — and `scene.preSession.condition.insert` produces a project no
  /// analysis layer understands: the solvability solver cannot prove a
  /// `newGameDraft` condition and the reference index reports its sourceId as
  /// a legacy external reference, so the export refuses the package. That is a
  /// real defect recorded as its own debt rather than smuggled into this
  /// ticket, and the text input's minGraphemes already refuses an empty name.
  List<DialoguedPreSessionAuthoringStep> get steps =>
      <DialoguedPreSessionAuthoringStep>[
        const DialoguedPreSessionAuthoringStep(
          actionId: 'scene.preSession.create',
          parameters: <String, Object?>{
            'sceneId': sceneId,
            'name': sceneName,
            'templateId': 'minimal',
            'setAsEntrypoint': true,
          },
        ),
        const DialoguedPreSessionAuthoringStep(
          actionId: 'scene.preSession.presentation.createAndLink',
          parameters: <String, Object?>{
            'sceneId': sceneId,
            'nodeId': openingNodeId,
            'targetNodeId': endNodeId,
            'cinematicId': cinematicId,
            'title': 'Ouverture — la veille de nuit',
            'templateId': 'blank',
            'templateVersion': 1,
            'targetFolderId': null,
            'targetIndex': 0,
          },
        ),
        // The markers exist before anything binds to them, because a cue
        // binding names a marker and the action refuses an unknown one. They
        // start OPTIONAL: a required cue with nothing bound to it is an
        // unresolved reference the graph rejects — which is also the order a
        // human authors in.
        DialoguedPreSessionAuthoringStep(
          actionId: 'presentationTrack.create',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'track': markerTrack(cuesRequired: false),
          },
        ),
        // One layer, then the visuals. The media BYTES are project seed — the
        // clips that reference them are authored here, which is the boundary
        // this fixture keeps: the journey goes through the actions, the base
        // data does not have to.
        const DialoguedPreSessionAuthoringStep(
          actionId: 'presentationLayer.create',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'layer': <String, Object?>{
              'id': visualLayerId,
              'label': 'La tour',
              'zIndex': 0,
              'visible': true,
              'locked': false,
            },
          },
        ),
        const DialoguedPreSessionAuthoringStep(
          actionId: 'presentationTrack.create',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'track': <String, Object?>{
              'id': visualTrackId,
              'label': 'Visuels',
              'kind': 'visual',
              'clips': <Object?>[],
            },
          },
        ),
        // Both variants authored: each orientation gets its own framing.
        const DialoguedPreSessionAuthoringStep(
          actionId: 'presentationClip.create',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'trackId': visualTrackId,
            'clip': <String, Object?>{
              'id': backdropClipId,
              'kind': 'visual',
              'contentKind': 'media',
              'mediaKind': 'image',
              'startUs': 0,
              'durationUs': 6000000,
              'layerId': visualLayerId,
              'resourceId': backdropMediaId,
              'landscapeResourceId': backdropWideMediaId,
              'portraitResourceId': backdropTallMediaId,
            },
          },
        ),
        // No variant at all: the shared source has to serve both orientations,
        // which is the fallback the criterion names.
        const DialoguedPreSessionAuthoringStep(
          actionId: 'presentationClip.create',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'trackId': visualTrackId,
            'clip': <String, Object?>{
              'id': sharedOnlyClipId,
              'kind': 'visual',
              'contentKind': 'media',
              'mediaKind': 'image',
              'startUs': 6000000,
              'durationUs': 5000000,
              'layerId': visualLayerId,
              'resourceId': backdropMediaId,
            },
          },
        ),
        const DialoguedPreSessionAuthoringStep(
          actionId: 'presentationTrack.create',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'track': <String, Object?>{
              'id': audioTrackId,
              'label': 'Audio',
              'kind': 'audio',
              'holdPolicy': 'ambientContinues',
              'clips': <Object?>[],
            },
          },
        ),
        // One music, one source, no orientation variant — the schema refuses
        // one and the runtime resolver ignores one.
        const DialoguedPreSessionAuthoringStep(
          actionId: 'presentationClip.create',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'trackId': audioTrackId,
            'clip': <String, Object?>{
              'id': musicClipId,
              'kind': 'audio',
              'startUs': 0,
              'durationUs': 11000000,
              'resourceId': lighthouseMusicMediaId,
              'audioKind': 'music',
              'bus': 'music',
              'loop': true,
            },
          },
        ),
        _interaction(
          nodeId: closingNodeId,
          title: 'Proposer le montage final',
          markerId: closingMarkerId,
          targetNodeId: endNodeId,
          interaction: ScenePreSessionInteractionSpec.confirmation(
            prompt: SceneInteractionPrompt(
              localizationKey: 'nightWatch.closing.prompt',
              fallbackText:
                  'Veux-tu voir la relève avant de monter dans la tour ?',
            ),
          ),
        ),
        // The interpolated draft value BETA-CIN-083 asks for: the name the
        // player just typed is read back before it is accepted, which is what
        // makes the negative branch mean anything.
        _interaction(
          nodeId: confirmNodeId,
          title: 'Relire le nom saisi',
          markerId: confirmMarkerId,
          targetNodeId: closingNodeId,
          interaction: ScenePreSessionInteractionSpec.confirmation(
            prompt: SceneInteractionPrompt(
              localizationKey: 'nightWatch.playerName.confirm',
              fallbackText: 'Le registre dira donc {draft.playerName}. '
                  'C’est bien cela ?',
            ),
          ),
        ),
        _interaction(
          nodeId: nameNodeId,
          title: 'Saisir son nom',
          markerId: nameMarkerId,
          targetNodeId: confirmNodeId,
          interaction: ScenePreSessionInteractionSpec.text(
            prompt: SceneInteractionPrompt(
              localizationKey: 'nightWatch.playerName.prompt',
              fallbackText: 'Comment le registre doit-il t’appeler ?',
            ),
            constraints: SceneTextInputConstraints(
              minGraphemes: 1,
              maxGraphemes: 12,
            ),
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.playerName,
            ),
          ),
        ),
        _interaction(
          nodeId: avatarNodeId,
          title: 'Choisir sa silhouette',
          markerId: avatarMarkerId,
          targetNodeId: nameNodeId,
          interaction: ScenePreSessionInteractionSpec.choice(
            prompt: SceneInteractionPrompt(
              localizationKey: 'nightWatch.keeper.prompt',
              fallbackText: 'Qui prend la veille ?',
            ),
            options: <SceneInteractionOption>[
              SceneInteractionOption(
                id: dawnKeeperOptionId,
                label: SceneInteractionPrompt(
                  localizationKey: 'nightWatch.keeper.dawn',
                  fallbackText: 'La gardienne de l’aube',
                ),
              ),
              SceneInteractionOption(
                id: duskKeeperOptionId,
                label: SceneInteractionPrompt(
                  localizationKey: 'nightWatch.keeper.dusk',
                  fallbackText: 'Le gardien du crépuscule',
                ),
              ),
            ],
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.avatarCharacterId,
            ),
          ),
        ),
        _interaction(
          nodeId: pagesNodeId,
          title: 'Les pages d’ouverture',
          markerId: pagesMarkerId,
          targetNodeId: avatarNodeId,
          interaction: ScenePreSessionInteractionSpec.message(
            prompt: SceneInteractionPrompt(
              localizationKey: 'nightWatch.opening.pages',
              fallbackText:
                  'Le phare tourne depuis cent ans. Cette nuit, il est à toi.',
            ),
          ),
        ),
        // Now that every cue is bound, they become required: this cinematic
        // may no longer play with an unbound cue.
        DialoguedPreSessionAuthoringStep(
          actionId: 'presentationTrack.update',
          parameters: <String, Object?>{
            'cinematicId': cinematicId,
            'track': markerTrack(cuesRequired: true),
          },
        ),
        // The negative confirmation of the reference journey: "no" replays
        // from the name marker instead of dead-ending, so the player can
        // correct a typo without restarting the cinematic.
        const DialoguedPreSessionAuthoringStep(
          actionId: 'scene.presentation.cue.routes.set',
          parameters: <String, Object?>{
            'sceneId': sceneId,
            'presentationNodeId': openingNodeId,
            'markerId': confirmMarkerId,
            'routes': <Object?>[
              <String, Object?>{
                'outputPortId': 'confirmed',
                'outcome': <String, Object?>{'kind': 'continue'},
              },
              <String, Object?>{
                'outputPortId': 'declined',
                'outcome': <String, Object?>{
                  'kind': 'repeatFromMarker',
                  'markerId': nameMarkerId,
                },
              },
            ],
          },
        ),
        // The other two outcomes, on a cue where they mean something: jump
        // ahead to the autonomous montage, or end the Presentation now and
        // hand control back to the Scene graph.
        const DialoguedPreSessionAuthoringStep(
          actionId: 'scene.presentation.cue.routes.set',
          parameters: <String, Object?>{
            'sceneId': sceneId,
            'presentationNodeId': openingNodeId,
            'markerId': closingMarkerId,
            'routes': <Object?>[
              <String, Object?>{
                'outputPortId': 'confirmed',
                'outcome': <String, Object?>{
                  'kind': 'seekMarker',
                  'markerId': montageMarkerId,
                },
              },
              <String, Object?>{
                'outputPortId': 'declined',
                'outcome': <String, Object?>{'kind': 'stop'},
              },
            ],
          },
        ),
        const DialoguedPreSessionAuthoringStep(
          actionId: 'scene.preSession.end.configure',
          parameters: <String, Object?>{
            'sceneId': sceneId,
            'nodeId': endNodeId,
            'outcomeId': outcomeId,
            'outcomeLabel': 'Prêt pour la tour',
            'outcomePolicy': 'progression',
          },
        ),
      ];

  static DialoguedPreSessionAuthoringStep _interaction({
    required String nodeId,
    required String title,
    required String markerId,
    required String targetNodeId,
    required ScenePreSessionInteractionSpec interaction,
  }) =>
      DialoguedPreSessionAuthoringStep(
        actionId: 'scene.preSession.interaction.insert',
        parameters: <String, Object?>{
          'sceneId': sceneId,
          'nodeId': nodeId,
          'targetNodeId': targetNodeId,
          'title': title,
          'interaction': interaction.toJson(),
          'cueBinding': <String, Object?>{
            'presentationNodeId': openingNodeId,
            'markerId': markerId,
          },
        },
      );

  /// The marker track. `ambientContinues` is authored, never guessed: the
  /// lighthouse loop is explicitly allowed to keep turning while the player
  /// reads, which is exactly the case BETA-CIN-077 reserves the policy for.
  static Map<String, Object?> markerTrack({required bool cuesRequired}) =>
      <String, Object?>{
        'id': markerTrackId,
        'label': 'Repères',
        'kind': 'marker',
        'holdPolicy': 'ambientContinues',
        'clips': <Object?>[
          _marker(pagesMarkerId, 0, 'Pages d’ouverture', cuesRequired),
          _marker(
            avatarMarkerId,
            2000000,
            'Choix de la silhouette',
            cuesRequired,
          ),
          _marker(nameMarkerId, 4000000, 'Saisie du nom', cuesRequired),
          _marker(confirmMarkerId, 6000000, 'Relecture du nom', cuesRequired),
          _marker(closingMarkerId, 8000000, 'Proposer la relève', cuesRequired),
          _marker(
            montageMarkerId,
            10000000,
            'Montage autonome',
            false,
            kind: 'ordinary',
          ),
        ],
      };

  static Map<String, Object?> _marker(
    String id,
    int startUs,
    String label,
    bool required, {
    String kind = 'interactionCue',
  }) =>
      <String, Object?>{
        'id': id,
        'kind': 'marker',
        'startUs': startUs,
        'durationUs': 0,
        'label': label,
        'markerKind': kind,
        'required': required,
      };
}
