import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final interactive in [false, true]) {
    final kind = interactive
        ? NarrativeCommandIds.receivePokemonFromCatalog
        : NarrativeCommandIds.givePokemonFromCatalog;
    final wire = <String, dynamic>{
      'kind': kind,
      'speciesId': 'fixture_species',
      'formId': 'fixture_form',
      'level': 7,
      if (interactive) ...{
        'nicknamePolicy': 'offer',
        'nicknameMaxGraphemes': 10,
        'pokedexPresentationPolicy': 'whenNewAndPokedexVisible',
      },
    };
    SceneActionPayload read(Map<String, dynamic> value) => interactive
        ? SceneActionPayload.interactive(
            SceneInteractiveCommand.fromJson(value),
          )
        : SceneActionPayload.consequence(SceneConsequence.fromJson(value));
    Map<String, dynamic> commandWire(SceneActionPayload value) => interactive
        ? value.interactiveCommand!.toJson()
        : value.consequence!.toJson();

    group(kind, () {
      test(
        'preserves exceptional move order through exact typed round trip',
        () {
          final payload = {
            ...wire,
            'moveIds': ['exceptional_move', 'fixture_move'],
          };
          final command = read(payload);
          expect(commandWire(command), payload);
          expect(SceneNodePayload.fromJson(command.toJson()), command);
          expect(read(payload).hashCode, command.hashCode);
          expect(
            read({
              ...wire,
              'moveIds': ['fixture_move', 'exceptional_move'],
            }),
            isNot(command),
          );
          expect(read(wire), isNot(command));
        },
      );

      test('absence and null keep automatic learnset selection', () {
        final automatic = read(wire);
        final explicitNull = read({...wire, 'moveIds': null});
        expect(explicitNull, automatic);
        expect(explicitNull.hashCode, automatic.hashCode);
        expect(commandWire(explicitNull), wire);
      });

      test('copies and protects the supplied move list', () {
        final moveIds = ['exceptional_move'];
        final command = read({...wire, 'moveIds': moveIds});
        moveIds[0] = 'mutated_move';
        final stored = commandWire(command)['moveIds'] as List<String>;
        expect(stored, ['exceptional_move']);
        expect(() => stored.add('extra_move'), throwsUnsupportedError);
      });

      test(
        'allows one or four imposed moves without learnset restrictions',
        () {
          for (final moveIds in [
            ['exceptional_move'],
            ['move_a', 'move_b', 'move_c', 'move_d'],
          ]) {
            expect(
              commandWire(read({...wire, 'moveIds': moveIds}))['moveIds'],
              moveIds,
            );
          }
        },
      );

      test('rejects malformed or ambiguous imposed move lists', () {
        for (final invalid in <Object>[
          'exceptional_move',
          4,
          {'id': 'exceptional_move'},
          <String>[],
          ['a', 'b', 'c', 'd', 'e'],
          ['a', 'a'],
          [''],
          [' '],
          [' move_a'],
          ['move_a '],
          ['move a'],
          ['move\ta'],
          ['move\na'],
          [null],
          ['a', 4],
        ]) {
          expect(
            () => read({...wire, 'moveIds': invalid}),
            throwsFormatException,
            reason: '$invalid',
          );
        }
      });

      test(
        'guided builder carries optional imposed moves and rejects aliases',
        () {
          final parameters = {
            for (final entry in wire.entries)
              if (entry.key != 'kind') entry.key: '${entry.value}',
            'moveIds': jsonEncode(['exceptional_move', 'fixture_move']),
          };
          expect(
            buildScenePayloadForNarrativeCommand(
              commandId: kind,
              parameters: parameters,
            ),
            read({
              ...wire,
              'moveIds': ['exceptional_move', 'fixture_move'],
            }),
          );
          expect(
            () => buildScenePayloadForNarrativeCommand(
              commandId: kind,
              parameters: {...parameters, 'moves': 'fixture_move'},
            ),
            throwsFormatException,
          );
          for (final invalid in ['fixture_move', '[]', '[4]', 'null']) {
            expect(
              () => buildScenePayloadForNarrativeCommand(
                commandId: kind,
                parameters: {...parameters, 'moveIds': invalid},
              ),
              throwsFormatException,
            );
          }
        },
      );

      test('gift command parameters cannot replace the command kind', () {
        final parameters = {
          for (final entry in wire.entries)
            if (entry.key != 'kind') entry.key: '${entry.value}',
        };
        for (final injectedKind in [kind, 'healParty', 'wait']) {
          expect(
            () => buildScenePayloadForNarrativeCommand(
              commandId: kind,
              parameters: {...parameters, 'kind': injectedKind},
            ),
            throwsFormatException,
          );
        }
      });

      test('catalogue describes imposed moves as optional', () {
        final parameter = NarrativeCommandCatalog.canonical()
            .byId(kind)!
            .parameters
            .singleWhere((parameter) => parameter.id == 'moveIds');
        expect(parameter.required, isFalse);
        expect(parameter.label, 'Capacités imposées');
      });

      test(
        'scene diagnostics reject a missing imposed move in a loaded catalog',
        () {
          final scene = _scene(
            read({
              ...wire,
              'moveIds': ['exceptional_move', 'fixture_move'],
            }),
          );
          final project = ProjectManifest(
            name: 'Gift',
            maps: [],
            tilesets: [],
            scenes: [scene],
          );
          for (final dimension in ProjectDimension.values) {
            final dimensionProject = project.copyWith(
              settings: ProjectSettings(dimension: dimension),
            );
            final complete = diagnoseSceneAgainstProject(
              scene,
              dimensionProject,
              availableMoveIds: {'exceptional_move', 'fixture_move'},
            );
            expect(complete.hasErrors, isFalse);
            final missing = diagnoseSceneAgainstProject(
              scene,
              dimensionProject,
              availableMoveIds: {'fixture_move'},
            );
            expect(missing.hasErrors, isTrue);
            expect(
              missing.diagnostics
                  .where(
                    (entry) => entry.severity == SceneDiagnosticSeverity.error,
                  )
                  .single
                  .message,
              contains('exceptional_move'),
            );
            final deferred = diagnoseSceneAgainstProject(
              scene,
              dimensionProject,
            );
            expect(deferred.hasErrors, isFalse);
            expect(
              deferred.diagnostics.any(
                (entry) =>
                    entry.code ==
                    SceneDiagnosticCode.commandPokemonCatalogDeferred,
              ),
              isTrue,
            );
          }
        },
      );
    });
  }

  test('consequence dry-run names the imposed move order', () {
    final scene = _scene(
      SceneActionPayload.consequence(
        SceneConsequence.fromJson({
          'kind': 'givePokemonFromCatalog',
          'speciesId': 'fixture_species',
          'formId': 'fixture_form',
          'level': 7,
          'moveIds': ['exceptional_move', 'fixture_move'],
        }),
      ),
    );
    final plan = buildSceneRuntimePlan(scene);
    expect(plan.canBuild, isTrue);
    final result = previewSceneRuntimePath(
      plan.plan!,
      input: const SceneDryRunInputState(),
    );
    expect(result.status, SceneDryRunPreviewStatus.completed);
    expect(
      result.consequenceChanges.single.afterSummary,
      contains('exceptional_move, fixture_move'),
    );
  });
}

SceneAsset _scene(SceneActionPayload payload) {
  final ports =
      payload.interactiveCommand?.outputPortIds ?? const ['completed'];
  return SceneAsset(
    id: 'gift',
    name: 'Gift',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'gift', kind: SceneNodeKind.action, payload: payload),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'gift',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port in ports)
          SceneEdge(
            id: port,
            fromNodeId: 'gift',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}
