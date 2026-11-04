import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'battle_gen5_emitter_motion.dart';
import 'battle_gen5_source_emitter.dart';
import 'battle_overlay_component.dart';
import 'battle_spl_static_admission.dart';
import 'battle_spl_static_component.dart';
import 'battle_verified_spl_loader.dart';

final class BattleGen5SourceParticleSet {
  BattleGen5SourceParticleSet._(this.program, this.variant, this._overlay);

  final Map<String, dynamic> program;
  final String variant;
  final BattleOverlayComponent _overlay;
  final _loaders = <BattleExperimentalSplLoader>[];
  final _prepared =
      <
        ({Map<String, dynamic> args, BattleExperimentalSplPreparation result})
      >[];
  final _active = <BattleSplStaticComponent>{};
  final _indices = <int, Set<int>>{};
  BattleSplAdmissionFailure? _failure;
  var _next = 0;
  var _disposed = false;

  static Future<BattleGen5SourceParticleSet> prepare({
    required InspectedBattleRecipeBundle bundle,
    required BattleOverlayComponent overlay,
    required RuntimeResourceBudget budget,
    required BattleSideId attackerSide,
    bool Function()? isCurrent,
  }) async {
    final recipe = bundle.recipe.toJson();
    final source = recipe['program'] as Map<String, dynamic>;
    if (source['kind'] != 'gen5SourceProgram') {
      throw const FormatException('Expected a Gen 5 source program');
    }
    final program = (source['sourceProgram'] as Map).cast<String, dynamic>();
    final result = BattleGen5SourceParticleSet._(
      program,
      recipe['variant'] as String,
      overlay,
    );
    final definitions = bundle.recipe.readVerifiedSplParticleDefinitions(
      bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    final bindings = <int, ({String resource, List<int> indices})>{};
    for (final value in source['particleBindings'] as List) {
      final binding = value as Map;
      final id = binding['particle'] as int;
      final indices = (binding['sourceEmitterIndices'] as List).cast<int>();
      bindings[id] = (
        resource: binding['resourceId'] as String,
        indices: indices,
      );
      result._indices[id] = indices.toSet();
    }
    final commands = <({String op, Map<String, dynamic> args})>[];
    final instructions = program['instructions'] as List;
    for (
      var index = program['entryIndex'] as int;
      index < instructions.length;
      index++
    ) {
      final instruction = instructions[index] as Map;
      final op = instruction['op'] as String;
      if (op == 'end') break;
      if (op.startsWith('start') && op.endsWith('Emitter')) {
        if (op != 'startEmitter' && op != 'startMovingEmitter') {
          throw const FormatException('Unsupported source emitter motion');
        }
        commands.add((
          op: op,
          args: (instruction['args'] as Map).cast<String, dynamic>(),
        ));
      }
    }
    final usesMotion = commands.any(
      (command) => command.op == 'startMovingEmitter',
    );
    try {
      for (final command in commands) {
        final args = command.args;
        if (isCurrent != null && !isCurrent()) {
          throw StateError('Source particle preparation cancelled');
        }
        final binding = bindings[args['particle']]!;
        final selected = definitions[binding.resource]!;
        final definitionJson =
            jsonDecode(jsonEncode(selected.toJson())) as Map<String, dynamic>;
        final sourceIndex = args['emitter'] as int;
        final emitter =
            (definitionJson['emitters'] as List)[binding.indices.indexOf(
                  sourceIndex,
                )]
                as Map;
        final fromUser =
            args['from'] == 0 || args['from'] == 'EFFVM_EMIT_ATTACKER';
        final towardOpponent =
            args['from'] != 8 &&
            args['to'] != 8 &&
            args['from'] != args['to'] &&
            !(args['from'] == 0 && args['to'] == 'EFFVM_EMIT_ATTACKER');
        applyGen5SourceEmitterParameters(
          emitter,
          args,
          orthographic: false,
          aimAtOpponent: towardOpponent,
        );
        final definition = BattleSplParticleDefinition.fromJson(definitionJson);
        final projection = overlay.experimentalGen5Projection(
          attacker: fromUser == (attackerSide == BattleSideId.player),
          towardOpponent: towardOpponent,
          matchBattleSpacing: usesMotion,
          anchorAtFoot: usesMotion,
        );
        final pixelsPerUnit = usesMotion
            ? projection.worldTransform!.worldUnitsPerUnit /
                  projection.capture()!.single.unit
            : 25.0;
        final loader = BattleExperimentalSplLoader(resourceBudget: budget);
        result._loaders.add(loader);
        late final BattleExperimentalSplPreparation prepared;
        prepared = await loader.create(
          definition: definition,
          sourceEmitterIndices: binding.indices,
          textureBytes: <String, Uint8List>{
            for (final id in definition.textureIds) id: bundle.media[id]!,
          },
          textureSha256: {
            for (final resource in bundle.recipe.resources)
              if (definition.textureIds.contains(resource.id))
                resource.id: resource.sha256Hex,
          },
          emitters: [
            BattleSplStaticEmitter(
              emitterIndex: sourceIndex,
              startTick: 0,
              position: (x: 0, y: args['offsetY'] as int, z: 0),
            ),
          ],
          seed: 0,
          poolCapacity: 128,
          maxTicks: 180,
          origin: ui.Offset.zero,
          pixelsPerUnit: pixelsPerUnit,
          projection: projection,
          onComplete: () => result._active.remove(prepared.component),
          onFailure: (failure) {
            result._failure = failure;
            result._active.remove(prepared.component);
          },
          isCurrent: isCurrent,
        );
        final component = prepared.component;
        if (component == null) {
          throw StateError('Source particle unavailable: ${prepared.failure}');
        }
        component.clipOutOfViewParticles = true;
        component.priority = 12;
        component.clipBounds = () =>
            ui.Rect.fromLTWH(0, 0, overlay.size.x, overlay.size.y);
        if (command.op == 'startMovingEmitter') {
          final motion = BattleGen5EmitterMotion(
            from: (x: 0, y: 0, z: 0),
            to: (x: 0, y: 0, z: 17 * 4096),
            motionType: args['motion'] as int,
            motionFramesFx32: args['motionFramesFx32'] as int,
            offsetYFx32: args['offsetY'] as int,
            heightFx32: args['height'] as int,
            turnsFx32: args['turns'] as int,
          );
          component.advanceEmitterPosition = motion.advance;
        }
        result._prepared.add((args: args, result: prepared));
      }
      return result;
    } on Object {
      result.dispose();
      rethrow;
    }
  }

  bool hasEmitter(int particle, int emitter) =>
      !_disposed && (_indices[particle]?.contains(emitter) ?? false);

  void start(Map<String, dynamic> args) {
    if (_disposed ||
        _next >= _prepared.length ||
        jsonEncode(args) != jsonEncode(_prepared[_next].args)) {
      throw StateError('Unexpected source particle invocation');
    }
    final component = _prepared[_next++].result.component!;
    _active.add(component);
    _overlay.add(component);
  }

  bool isBusy() {
    if (_failure != null) throw StateError('Source particle failed: $_failure');
    return _active.isNotEmpty;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final entry in _prepared) {
      entry.result.dispose();
    }
    for (final loader in _loaders) {
      loader.cancel();
    }
    _active.clear();
  }
}
