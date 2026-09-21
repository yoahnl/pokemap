import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core_domain.dart';

import 'ui06_scene_fixture.dart';
import 'ui13_verification_harness.dart';

/// Two stories carrying a step with the same local identifier, and a scene
/// whose identifier is also a dialogue identifier.
List<StorylineAsset> _twins() => [
  StorylineAsset(
    id: Ui13VerificationHarness.twinStoryId,
    type: StorylineType.sideQuest,
    title: 'Le retour',
    chapters: [
      StorylineChapter(
        id: '$Ui13VerificationHarness.twinStoryId.c1',
        title: 'Quai 1',
        order: 0,
        steps: [
          StorylineStep(
            id: Ui13VerificationHarness.twinStepId,
            title: 'Revenir sur ses pas',
            order: 0,
          ),
        ],
      ),
    ],
  ),
];

Future<void> seedUi13Fixture(
  Directory directory, {
  bool homonyms = false,
}) async {
  await _seed(directory, homonyms);
  await _publishDocuments(directory);
}

Future<void> _seed(Directory directory, bool homonyms) async {
  final file = File('${directory.path}/project.json');
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await file.readAsString()) as Map<String, dynamic>,
  );
  final mapId = manifest.maps.first.id;
  final fact = NarrativeFactDefinition(
    id: Ui13VerificationHarness.knownFactId,
    label: 'Train parti',
    description: 'Le train a quitté Kisaragi.',
    initialValue: const NarrativeValue.boolean(false),
  );
  final source = WorldRuleSource.factValue(
    factId: Ui13VerificationHarness.knownFactId,
    operator: NarrativeFactOperator.equals,
    expectedValue: const NarrativeValue.boolean(true),
  );
  await file.writeAsString(
    jsonEncode(
      manifest
          .copyWith(
            version: ProjectVersion.v7,
            facts: [fact],

            storylines: [
              if (homonyms) ..._twins(),
              StorylineAsset(
                id: Ui13VerificationHarness.storyId,
                type: StorylineType.main,
                title: 'Le départ',
                chapters: [
                  StorylineChapter(
                    id: '$Ui13VerificationHarness.storyId.c1',
                    title: 'Quai 3',
                    order: 0,
                    steps: [
                      StorylineStep(
                        id: homonyms
                            ? Ui13VerificationHarness.twinStepId
                            : '$Ui13VerificationHarness.storyId.c1.s1',
                        title: 'Monter dans le train',
                        order: 0,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            worldRules: [
              WorldRuleDefinition(
                id: Ui13VerificationHarness.orphanRuleId,
                label: 'Masquer le conducteur',
                source: WorldRuleSource.factValue(
                  factId: 'fact_inexistant',
                  operator: NarrativeFactOperator.equals,
                  expectedValue: const NarrativeValue.boolean(true),
                ),
                target: WorldRuleTarget(
                  kind: WorldRuleTargetKind.mapEntity,
                  mapId: mapId,
                  entityId: 'entite_inexistante',
                  label: 'Conducteur',
                ),
                effect: const WorldRuleEffect(
                  kind: WorldRuleEffectKind.entityHidden,
                ),
              ),
              WorldRuleDefinition(
                id: Ui13VerificationHarness.targetRuleId,
                label: 'Masquer le chef de gare',
                source: source,
                target: WorldRuleTarget(
                  kind: WorldRuleTargetKind.mapEntity,
                  mapId: mapId,
                  entityId: 'chef_de_gare_absent',
                  label: 'Chef de gare',
                ),
                effect: const WorldRuleEffect(
                  kind: WorldRuleEffectKind.entityHidden,
                ),
              ),
            ],
          )
          .toJson(),
    ),
  );
}

/// A scene that opens a dialogue, published through the canonical path so
/// the Yarn source really exists on disk.
Future<void> _publishDocuments(Directory directory) async {
  final session = ProjectSession(
    sessionId: directory.path,
    name: 'UI13',
    directoryPath: directory.path,
  );
  final adapter = LocalMapWorkspaceAdapter();
  final manifest = await adapter.loadProject(session);
  final base = await adapter.loadMap(session, manifest.maps.first);
  await LocalNarrativeAdapter(session: session, mapAdapter: adapter).publish(
    NarrativePublication(
      base: base,
      current: base.map,
      scenes: [Ui06SceneFixture.buildScene()],
      dialogues: Ui06SceneFixture.buildDialogues(),
      facts: [
        NarrativeFactDefinition(
          id: Ui06SceneFixture.passFactId,
          label: 'Laissez-passer obtenu',
        ),
        NarrativeFactDefinition(
          id: Ui06SceneFixture.departureFactId,
          label: 'Départ autorisé',
        ),
      ],
    ),
  );
}
