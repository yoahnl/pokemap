import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_adapters/src/source_intro_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final enabled = root != null && snapshot != null && profile != null;
  group('native source introduction projection', () {
    late ({NormalizedSourceProject source, ExternalOriginalFiles files}) fixture;
    late SourceEventAnalysis analysis;
    late SourceFreshEntryProgram entry;
    late Map<int, MapData> maps;
    late Map<int, SourceIntroProgram> texts;
    late SourceEventSoundBinding music;
    setUpAll(() async {
      fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {1, 2, 7},
          supplementalRoots:
              (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
                  .split('|').where((value) => value.isNotEmpty).toList());
      analysis = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source)).analyze();
      entry = sourceFreshEntryProgram(fixture.source)!;
      maps = {
        for (final map in fixture.source.maps)
          map.map.sourceMapId: MapData(id: 'native_${map.map.sourceMapId}',
              name: map.map.name,
              size: GridSize(width: map.map.width, height: map.map.height),
              layers: [CollisionLayer(id: 'collision', name: 'Collision',
                  collisions: List.filled(map.map.width * map.map.height, false))]),
      };
      texts = await const SourceIntroBindingResolver().readTextVariables(
          source: fixture.source, files: fixture.files,
          referencedVariableIds: {entry.intro.nameVariableId});
      music = await const SourceEventSoundResolver().read(
          source: fixture.source, files: fixture.files,
          name: 'FRLG Misc - Prof. Oak (Prof. Oak)',
          kind: SourceEventAudioKind.music);
    });
    SourceEventProjection project({bool wrongAudio = false, Map<int, MapData>? nativeMaps}) =>
        const SourceEventProjector().project(
            source: fixture.source, analysis: analysis,
            nativeMaps: nativeMaps ?? maps, textVariablePrograms: texts,
            soundBindings: {if (wrongAudio) 'bgm:${entry.intro.music.name}': music});
    Map evidence(SourceEventProjection result) =>
        (result.semanticEvidence['events'] as List).cast<Map>().singleWhere(
            (row) => row['sourceIdentity'] ==
                fixture.source.eventIdentity(1, 1).value);

    test('preserves confirmed name, source completion and home transfer', () {
      final result = project();
      final row = evidence(result);
      expect(row['gaps'], isEmpty, reason: '$row');
      expect(row['status'], 'adaptedStaticSemantics');
      final native = row['nativeIntroduction'] as Map;
      final freshId = native['nativeEntryFactId'] as String;
      expect(native['requiresNativeFreshEntryFactory'], isTrue);
      expect((native['sourceMusic'] as Map)['status'],
          'missingOptionalSourceAudioOmittedWithoutSubstitution');
      expect(result.facts.singleWhere((fact) => fact.id == freshId)
          .initialValue, NarrativeValue.boolean(false));
      final factId = sourceEventIntegerVariableBindingId(
          'source:${fixture.source.snapshot.logicalProjectNamespace.value}:variable:28');
      expect(result.facts.singleWhere((fact) => fact.id == factId)
          .initialValue, NarrativeValue.string(''));
      final scene = result.scenes.singleWhere((scene) =>
          scene.metadata['sourceEventIdentity'] == fixture.source.eventIdentity(1, 1).value &&
          scene.metadata['sourcePageIndex'] == '0');
      final actions = scene.graph.nodes.map((node) => node.payload)
          .whereType<SceneActionPayload>().toList();
      final input = actions.map((action) => action.interactiveCommand)
          .whereType<SceneInputTextToFactInteractiveCommand>().single;
      expect(input.factId, factId);
      expect(input.presetValues, ['Blue', 'Gary', 'Michael']);
      expect(input.constraints.maxGraphemes, 7);
      expect(input.confirmationPrompt.fallbackText, contains('{value}'));
      expect(input.confirmationPrompt.fallbackText, isNot(contains(r'\v[')));
      final warpNode = scene.graph.nodes.singleWhere((node) =>
          node.payload is SceneActionPayload &&
          (node.payload as SceneActionPayload).interactiveCommand is SceneWarpInteractiveCommand);
      final warp = (warpNode.payload as SceneActionPayload).interactiveCommand
          as SceneWarpInteractiveCommand;
      expect(warp.destinationMapId, maps[7]!.id);
      expect(warp.arrivalFacing, EntityFacing.south);
      final arrival = result.nativeMaps[7]!.warps.singleWhere((w) => w.id == warp.warpId);
      expect(arrival.pos, const GridPos(x: 27, y: 8));
      final completed = scene.graph.edges.singleWhere((edge) =>
          edge.fromNodeId == warpNode.id && edge.fromPortId == 'completed');
      final effect = (scene.graph.nodes.singleWhere((node) => node.id == completed.toNodeId)
          .payload as SceneActionPayload).consequence as SceneSetFactConsequence;
      expect(effect.factId, sourceEventFactBindingId(
          'source:${fixture.source.snapshot.logicalProjectNamespace.value}:switch:99'));
      expect(effect.narrativeValue, NarrativeValue.boolean(true));
      final releaseEdge = scene.graph.edges.singleWhere((edge) =>
          edge.fromNodeId == completed.toNodeId && edge.fromPortId == 'completed');
      final release = (scene.graph.nodes.singleWhere((node) => node.id == releaseEdge.toNodeId)
          .payload as SceneActionPayload).consequence as SceneSetFactConsequence;
      expect(release.factId, freshId);
      expect(release.value, isFalse);
      expect(result.dialogueSources.values.join('\n'), contains(dialogueFactPlaceholder(factId)));
      expect(result.cinematics.singleWhere((clip) => clip.metadata['converter.sourceProgram'] ==
          entry.intro.programHash.value).timeline.steps.where((step) =>
              step.kind == CinematicTimelineStepKind.dialogueLine), hasLength(8));
    });
    test('refuses substitution with another attested source music', () {
      expect(evidence(project(wrongAudio: true))['gaps'],
          contains('sourceIntroductionMusicBindingMissing'));
    });
    test('refuses the whole introduction when its arrival is blocked', () {
      final target = maps[7]!;
      final cells = List<bool>.filled(target.size.width * target.size.height, false);
      cells[8 * target.size.width + 27] = true;
      expect(evidence(project(nativeMaps: {...maps, 7: target.copyWith(layers: [
        CollisionLayer(id: 'collision', name: 'Collision', collisions: cells)
      ])}))['gaps'], contains('sourceIntroductionArrivalBlocked'));
    });
  }, skip: enabled ? false : 'Requires immutable original source and profile.');
}
