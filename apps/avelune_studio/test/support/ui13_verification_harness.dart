import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:map_core/map_core_domain.dart';

import '../../tool/create_example_project.dart';
import 'ui06_scene_fixture.dart';

/// A real project on disk carrying faults the canonical validators produce:
/// a rule whose state does not exist, a rule aimed at an entity that is not on
/// its map, and a story with a beginning but no ending.
class Ui13VerificationHarness {
  Ui13VerificationHarness({
    required this.directory,
    required this.session,
    required this.adapter,
    required this.maps,
    required this.narrative,
    required this.world,
    required this.verification,
    required this.scenes,
    required this.port,
  });

  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter adapter;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController narrative;
  final WorldWorkspaceController world;
  final VerificationWorkspaceController verification;
  final SceneWorkspaceController scenes;
  final VerificationPort port;
  int changes = 0;
  void Function()? onChanged;

  static const storyId = 'story_depart';
  static const twinStoryId = 'story_retour';
  static const twinStepId = 'etape_commune';
  static const sharedId = 'kisaragi';
  static const sceneId = Ui06SceneFixture.sceneId;
  static const dialogueId = 'station_welcome';
  static const knownFactId = 'fact_train_parti';
  static const orphanRuleId = 'world_rule_orpheline';
  static const targetRuleId = 'world_rule_cible_absente';

  static Future<Ui13VerificationHarness> create({
    VerificationPort Function(VerificationPort)? wrap,
    bool seedProblems = true,
    bool homonyms = false,
  }) async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ui13_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    if (seedProblems) {
      await _seed(directory, homonyms);
      await _publishDocuments(directory);
    }
    return open(directory, wrap: wrap);
  }

  /// Two stories carrying a step with the same local identifier, and a scene
  /// whose identifier is also a dialogue identifier.
  static List<StorylineAsset> _twins() => [
    StorylineAsset(
      id: twinStoryId,
      type: StorylineType.sideQuest,
      title: 'Le retour',
      chapters: [
        StorylineChapter(
          id: '$twinStoryId.c1',
          title: 'Quai 1',
          order: 0,
          steps: [
            StorylineStep(
              id: twinStepId,
              title: 'Revenir sur ses pas',
              order: 0,
            ),
          ],
        ),
      ],
    ),
  ];

  static Future<void> _seed(Directory directory, bool homonyms) async {
    final file = File('${directory.path}/project.json');
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final mapId = manifest.maps.first.id;
    final fact = NarrativeFactDefinition(
      id: knownFactId,
      label: 'Train parti',
      description: 'Le train a quitté Kisaragi.',
      initialValue: const NarrativeValue.boolean(false),
    );
    final source = WorldRuleSource.factValue(
      factId: knownFactId,
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
                  id: storyId,
                  type: StorylineType.main,
                  title: 'Le départ',
                  chapters: [
                    StorylineChapter(
                      id: '$storyId.c1',
                      title: 'Quai 3',
                      order: 0,
                      steps: [
                        StorylineStep(
                          id: homonyms ? twinStepId : '$storyId.c1.s1',
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
                  id: orphanRuleId,
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
                  id: targetRuleId,
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
  static Future<void> _publishDocuments(Directory directory) async {
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

  /// Reopens the same folder through fresh adapters, the way a later session
  /// would: what is asserted after this has really been written.
  static Future<Ui13VerificationHarness> open(
    Directory directory, {
    VerificationPort Function(VerificationPort)? wrap,
  }) async {
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'UI13',
      directoryPath: directory.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final maps = MapWorkspaceController(session, adapter);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: session, mapAdapter: adapter),
      () {},
      (_, _) async {},
    );
    late Ui13VerificationHarness harness;
    final world = WorldWorkspaceController(
      narrative,
      LocalWorldAdapter(session: session, mapAdapter: adapter),
      changed: () => harness.onChanged?.call(),
    );
    final port = (wrap ?? (value) => value)(
      LocalVerificationAdapter(session: session, mapAdapter: adapter),
    );
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: session, mapAdapter: adapter),
      narrative: narrative,
      changed: () => harness.onChanged?.call(),
    );
    final verification = VerificationWorkspaceController(
      narrative,
      port,
      scenes: () => scenes,
      changed: () {
        harness.changes++;
        harness.onChanged?.call();
      },
      world: () => world,
    );
    harness = Ui13VerificationHarness(
      directory: directory,
      session: session,
      adapter: adapter,
      maps: maps,
      narrative: narrative,
      world: world,
      verification: verification,
      scenes: scenes,
      port: port,
    );
    return harness;
  }

  /// The same project seen through another executor, as the host would wire
  /// it: used to drive cancellation, replacement and late replies by hand.
  VerificationWorkspaceController withPort(VerificationPort other) =>
      VerificationWorkspaceController(
        narrative,
        other,
        changed: () => onChanged?.call(),
        world: () => world,
        scenes: () => scenes,
      );

  Future<void> dispose({bool deleteDirectory = true}) async {
    verification.dispose();
    scenes.dispose();
    world.dispose();
    narrative.dispose();
    maps.dispose();
    if (deleteDirectory && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
