import 'dart:convert';

final class Gen5ApproximateParticleSource {
  const Gen5ApproximateParticleSource(this.document, this.warnings);
  final Map<String, dynamic> document;
  final Set<String> warnings;
}

abstract final class Gen5BatchParticleApproximation {
  static Gen5ApproximateParticleSource normalize(Map<String, dynamic> input, {bool omitChildren = false}) {
    final document = jsonDecode(jsonEncode(input)) as Map<String, dynamic>;
    final warnings = <String>{};
    void set(Map value, String key, Object? replacement, String warning) {
      if (value[key] != replacement) {
        value[key] = replacement;
        warnings.add(warning);
      }
    }
    void bound(Map value, String key, int minimum, int maximum, String scope) {
      final original = value[key];
      if (original is int && (original < minimum || original > maximum)) {
        value[key] = original.clamp(minimum, maximum);
        warnings.add('$scope:$key');
      }
    }
    for (final raw in (document['textures'] as List)) {
      final texture = raw as Map;
      if (!{'a3i5', 'a5i3'}.contains(texture['format'])) {
        set(texture, 'format', 'a5i3', 'texture-field:format');
      }
      set(texture, 'repeat', 'none', 'texture-field:repeat');
      set(texture, 'flip', 'none', 'texture-field:flip');
    }
    final emitters = (document['emitters'] as List).cast<Map>();
    final version4 = emitters.any((emitter) => emitter.containsKey('magnetBehavior'));
    const allowed = {
      'emissionType', 'drawType', 'emissionAxis', 'hasRotation', 'randomInitAngle',
      'autoTerminate', 'followEmitter', 'polygonRotAxis', 'polygonReferencePlane',
      'randomLoopOffset', 'drawChildrenFirst', 'hideParent', 'relativeToBasePos',
      'fixedPolygonID', 'childFixedPolygonID', 'emitterBasePos', 'emissionCount',
      'radius', 'length', 'axis', 'color', 'initVelPositionAmplifier',
      'initVelAxisAmplifier', 'baseScale', 'aspectRatio', 'startDelay',
      'minRotation', 'maxRotation', 'initAngle', 'emitterLifeTime', 'particleLifeTime',
      'scaleVariance', 'lifeTimeVariance', 'velocityVariance', 'emissionInterval',
      'baseAlpha', 'airResistance', 'texture', 'loopTime', 'dirStretch',
      'textureRepeatShiftS', 'textureRepeatShiftT', 'scaleAnimDir', 'dirFromPosition',
      'flipTextureS', 'flipTextureT', 'polygonX', 'polygonY', 'unused',
      'scaleAnim', 'colorAnim', 'alphaAnim', 'textureAnim', 'childResource',
      'gravityBehavior', 'magnetBehavior',
    };
    for (final emitter in emitters) {
      if (omitChildren && emitter.containsKey('childResource')) {
        emitter.remove('childResource');
        warnings.add('particle-child:omitted-for-preview');
      }
      for (final field in emitter.keys.where((key) => !allowed.contains(key)).toList()) {
        emitter.remove(field);
        warnings.add('particle-field:$field');
      }
      final shape = emitter['emissionType'];
      if (!{'point', 'sphere_surface'}.contains(shape)) {
        emitter['emissionType'] = 'sphere_surface';
        warnings.add('particle-shape:$shape->sphere_surface');
      }
      if (emitter['emissionType'] == 'sphere_surface' && emitter['radius'] == 0) {
        set(emitter, 'emissionType', 'point', 'particle-zero-radius:point');
      }
      if (!{'billboard', 'directional_billboard'}.contains(emitter['drawType'])) {
        set(emitter, 'drawType', 'billboard', 'particle-field:drawType');
      }
      if (emitter['emissionAxis'] == 'emitter') {
        set(emitter, 'emissionAxis', 'z', 'particle-field:emissionAxis');
      }
      set(emitter, 'polygonRotAxis', 'y', 'particle-field:polygonRotAxis');
      set(emitter, 'polygonReferencePlane', 'xy', 'particle-field:polygonReferencePlane');
      for (final field in ['hasRotation', 'randomLoopOffset', 'drawChildrenFirst', 'hideParent',
          'relativeToBasePos', 'fixedPolygonID', 'childFixedPolygonID', 'dirFromPosition',
          'flipTextureS', 'flipTextureT']) {
        if (emitter.containsKey(field)) set(emitter, field, false, 'particle-field:$field');
      }
      for (final field in ['lifeTimeVariance', 'velocityVariance', 'dirStretch',
          'textureRepeatShiftS', 'textureRepeatShiftT', 'polygonX', 'polygonY']) {
        if (emitter.containsKey(field)) set(emitter, field, 0, 'particle-field:$field');
      }
      if (emitter['autoTerminate'] == false) {
        set(emitter, 'autoTerminate', true, 'particle-field:autoTerminate');
      }
      if (emitter['emitterLifeTime'] == 0) {
        set(emitter, 'emitterLifeTime', 60, 'particle-default:emitterLifeTime');
      }
      for (final (field, min, max) in <(String, int, int)>[
        ('radius', 0, 32767), ('initVelPositionAmplifier', -32768, 32767),
        ('initVelAxisAmplifier', -32768, 32767), ('emissionCount', 0, 262144),
        ('startDelay', 0, 65535), ('emissionInterval', 1, 255),
        ('emitterLifeTime', 1, 65534), ('particleLifeTime', 1, 65535),
        ('scaleVariance', 0, 255), ('initAngle', 0, 65535),
        ('baseScale', 0, 32767), ('aspectRatio', 0, 32767),
        ('baseAlpha', 0, 31), ('loopTime', 1, 65535), ('airResistance', 0, 255),
      ]) {
        bound(emitter, field, min, max, 'particle-bound');
      }
      if (emitter['emissionType'] == 'sphere_surface' && emitter['radius'] == 0) {
        set(emitter, 'emissionType', 'point', 'particle-zero-radius:point');
      }
      final baseScale = emitter['baseScale'];
      final scaleVariance = emitter['scaleVariance'];
      if (baseScale is int && scaleVariance is int &&
          (baseScale * (255 + scaleVariance)) >> 8 > 32767) {
        set(emitter, 'baseScale', (32767 * 256) ~/ (255 + scaleVariance), 'particle-bound:variedScale');
      }
      if (!emitter.containsKey('scaleAnim')) {
        emitter['scaleAnim'] = {'start': 4096, 'mid': 4096, 'end': 4096, 'in': 0, 'out': 254, 'loop': false};
        warnings.add('particle-default:scaleAnim');
      }
      if (!emitter.containsKey('alphaAnim')) {
        emitter['alphaAnim'] = {'start': 31, 'mid': 31, 'end': 31, 'randomRange': 0, 'loop': false, 'in': 0, 'out': 254};
        warnings.add('particle-default:alphaAnim');
      }
      for (final key in ['scaleAnim', 'alphaAnim']) {
        final curve = emitter[key];
        if (curve is! Map) continue;
        for (final field in ['in', 'out']) {
          bound(curve, field, 0, 254, 'particle-curve:$key');
        }
        final start = curve['in'];
        final end = curve['out'];
        if (start is int && end is int && start > end) {
          set(curve, 'out', start, 'particle-curve:$key.order');
        }
        for (final field in ['start', 'mid', 'end']) {
          bound(curve, field, 0, key == 'alphaAnim' ? 31 : 32767, 'particle-curve:$key');
        }
      }
      final color = emitter['colorAnim'];
      if (color is Map) {
        set(color, 'randomStart', false, 'particle-field:colorAnim.randomStart');
        final start = color['in'];
        final peak = color['peak'];
        final end = color['out'];
        if (start is int && peak is int && end is int && (start > peak || peak > end)) {
          final ordered = [start, peak, end]..sort();
          color['in'] = ordered[0];
          color['peak'] = ordered[1];
          color['out'] = ordered[2];
          warnings.add('particle-curve:colorAnim.order');
        }
      }
      final animation = emitter['textureAnim'];
      if (animation is Map) set(animation, 'randomStart', false, 'particle-field:textureAnim.randomStart');
      final child = emitter['childResource'];
      if (child is Map) {
        for (final field in ['followEmitter', 'flipTextureS', 'flipTextureT', 'dirFromPosition']) {
          set(child, field, false, 'particle-child:$field');
        }
        for (final field in ['textureRepeatShiftS', 'textureRepeatShiftT']) {
          set(child, field, 0, 'particle-child:$field');
        }
        if (!version4) {
          set(child, 'hasBehaviors', false, 'particle-child:hasBehaviors');
          set(child, 'hasScaleAnim', false, 'particle-child:hasScaleAnim');
        }
        if (child['hasScaleAnim'] == false) set(child, 'endScale', 0, 'particle-child:endScale');
        set(child, 'useChildColor', true, 'particle-child:useChildColor');
        if (child['drawType'] != 'billboard' && !(version4 && child['drawType'] == 'directional_billboard')) {
          set(child, 'drawType', 'billboard', 'particle-child:drawType');
        }
        set(child, 'polygonRotAxis', 'y', 'particle-child:polygonRotAxis');
        set(child, 'polygonReferencePlane', 'xy', 'particle-child:polygonReferencePlane');
        if (!{'none', 'angle', 'angle_and_velocity'}.contains(child['rotationType'])) {
          set(child, 'rotationType', 'none', 'particle-child:rotationType');
        }
      }
    }
    return Gen5ApproximateParticleSource(document, Set.unmodifiable(warnings));
  }
}
